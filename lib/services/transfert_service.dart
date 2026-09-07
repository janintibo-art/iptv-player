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
  /// Dossier ou ecrire les exports : visible depuis un gestionnaire de
  /// fichiers sur Android, Documents sur Windows.
  static Future<Directory> _dossierExport() async {
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) return ext;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Exporte les favoris en JSON.
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

    try {
      final dir = await _dossierExport();
      final f = File('${dir.path}${Platform.pathSeparator}$nom');
      await f.writeAsString(contenu);
      return ResultatFichier(
          true, '${favoris.length} favoris enregistres dans ${f.path}');
    } catch (e) {
      return ResultatFichier(false, 'Echec de l export : $e');
    }
  }

  /// Lit le contenu texte du fichier choisi par l utilisateur.
  static Future<({String nom, String texte})?> _choisirFichier() async {
    final fichier = await FilePicker.pickFile();
    if (fichier == null) return null;

    final octets = await fichier.readAsBytes();
    return (
      nom: fichier.name,
      texte: utf8.decode(octets, allowMalformed: true),
    );
  }

  /// Importe des favoris depuis un JSON, en les ajoutant aux actuels.
  static Future<ResultatFichier> importerFavoris() async {
    try {
      final choix = await _choisirFichier();
      if (choix == null) {
        return const ResultatFichier(false, 'Import annule.');
      }

      final data = jsonDecode(choix.texte);
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

      return ResultatFichier(
        true,
        '$ajoutes favori(s) ajoute(s), '
        '${importes.length - ajoutes} deja present(s).',
      );
    } catch (e) {
      return ResultatFichier(false, 'Echec de l import : $e');
    }
  }

  /// Importe un fichier .m3u de l appareil et l ajoute aux sources.
  static Future<ResultatFichier> importerPlaylist() async {
    try {
      final choix = await _choisirFichier();
      if (choix == null) {
        return const ResultatFichier(false, 'Import annule.');
      }

      if (!choix.texte.contains('#EXTINF')) {
        return const ResultatFichier(
            false, 'Ce fichier ne ressemble pas a une playlist M3U.');
      }

      final nb = M3uService.instance.parse(choix.texte).length;
      if (nb == 0) {
        return const ResultatFichier(false, 'Aucune chaine lisible.');
      }

      final cle = '${M3uService.prefixeLocal}${choix.nom}';
      await M3uService.instance.enregistrerLocale(cle, choix.texte);
      await Prefs.addCustomSource(SourcePreset(
        choix.nom,
        cle,
        'Fichier importe depuis l appareil, $nb chaine(s).',
      ));
      await Prefs.toggleSource(cle);

      return ResultatFichier(
          true, '$nb chaine(s) importee(s) depuis ${choix.nom}');
    } catch (e) {
      return ResultatFichier(false, 'Echec de l import : $e');
    }
  }
}
