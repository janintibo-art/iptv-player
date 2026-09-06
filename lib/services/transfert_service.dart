import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/channel.dart';
import 'm3u_service.dart';
import 'prefs_service.dart';
import 'sources.dart';

/// Resultat d une operation d import ou d export.
class ResultatFichier {
  final bool ok;
  final String message;
  const ResultatFichier(this.ok, this.message);
}

class TransfertService {
  /// Exporte les favoris en JSON. Renvoie le chemin ou un message d erreur.
  static Future<ResultatFichier> exporterFavoris() async {
    final favoris = Prefs.favorites;
    if (favoris.isEmpty) {
      return const ResultatFichier(false, 'Aucun favori a exporter.');
    }

    final contenu = const JsonEncoder.withIndent('  ').convert({
      'application': 'iptv_player',
      'version': 4,
      'date': DateTime.now().toIso8601String(),
      'favoris': favoris.map((c) => c.toJson()).toList(),
    });

    final nom =
        'favoris_iptv_${DateTime.now().toIso8601String().substring(0, 10)}.json';
    final octets = utf8.encode(contenu);

    // Boite de dialogue systeme quand elle est disponible.
    try {
      final chemin = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer les favoris',
        fileName: nom,
        bytes: octets,
      );
      if (chemin != null) {
        // Sur bureau, saveFile renvoie le chemin sans ecrire le fichier.
        final f = File(chemin);
        if (!await f.exists()) await f.writeAsString(contenu);
        return ResultatFichier(true, '${favoris.length} favoris vers $chemin');
      }
    } catch (_) {
      // On bascule sur l ecriture directe ci-dessous.
    }

    // Repli : dossier de l application.
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}${Platform.pathSeparator}$nom');
      await f.writeAsString(contenu);
      return ResultatFichier(true, '${favoris.length} favoris vers ${f.path}');
    } catch (e) {
      return ResultatFichier(false, 'Echec de l export : $e');
    }
  }

  /// Importe des favoris depuis un fichier JSON, en les ajoutant aux actuels.
  static Future<ResultatFichier> importerFavoris() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choisir un fichier de favoris',
        type: FileType.any,
        withData: true,
      );
      if (res == null || res.files.isEmpty) {
        return const ResultatFichier(false, 'Import annule.');
      }

      final f = res.files.first;
      final texte = f.bytes != null
          ? utf8.decode(f.bytes!, allowMalformed: true)
          : await File(f.path!).readAsString();

      final data = jsonDecode(texte);
      final brut = data is Map ? data['favoris'] : data;
      if (brut is! List) {
        return const ResultatFichier(
            false, 'Fichier invalide : aucun favori trouve.');
      }

      final importes = brut
          .whereType<Map<String, dynamic>>()
          .map(Channel.fromJson)
          .where((c) => c.url.isNotEmpty)
          .toList();

      final actuels = Prefs.favorites;
      final urls = actuels.map((c) => c.url).toSet();
      var ajoutes = 0;
      for (final c in importes) {
        if (urls.add(c.url)) {
          actuels.add(c);
          ajoutes++;
        }
      }
      await Prefs.setFavorites(actuels);

      return ResultatFichier(true,
          '$ajoutes favori(s) ajoute(s), ${importes.length - ajoutes} deja present(s).');
    } catch (e) {
      return ResultatFichier(false, 'Echec de l import : $e');
    }
  }

  /// Importe un fichier .m3u de l appareil et l ajoute aux sources.
  static Future<ResultatFichier> importerPlaylist() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choisir un fichier .m3u',
        type: FileType.any,
        withData: true,
      );
      if (res == null || res.files.isEmpty) {
        return const ResultatFichier(false, 'Import annule.');
      }

      final f = res.files.first;
      final texte = f.bytes != null
          ? utf8.decode(f.bytes!, allowMalformed: true)
          : await File(f.path!).readAsString();

      if (!texte.contains('#EXTINF')) {
        return const ResultatFichier(
            false, 'Ce fichier ne ressemble pas a une playlist M3U.');
      }

      final nb = M3uService.instance.parse(texte).length;
      if (nb == 0) {
        return const ResultatFichier(false, 'Aucune chaine lisible.');
      }

      final cle = '${M3uService.prefixeLocal}${f.name}';
      await M3uService.instance.enregistrerLocale(cle, texte);
      await Prefs.addCustomSource(SourcePreset(
        f.name,
        cle,
        'Fichier importe depuis l appareil, $nb chaine(s).',
      ));
      await Prefs.toggleSource(cle);

      return ResultatFichier(true, '$nb chaine(s) importee(s) depuis ${f.name}');
    } catch (e) {
      return ResultatFichier(false, 'Echec de l import : $e');
    }
  }
}
