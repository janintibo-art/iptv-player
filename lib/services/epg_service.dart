import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

/// Une emission du guide des programmes.
class Programme {
  final String chaine; // identifiant XMLTV, correspond au tvg-id du M3U
  final DateTime debut;
  final DateTime fin;
  final String titre;
  final String description;

  const Programme({
    required this.chaine,
    required this.debut,
    required this.fin,
    required this.titre,
    this.description = '',
  });

  bool get enCours {
    final n = DateTime.now();
    return n.isAfter(debut) && n.isBefore(fin);
  }

  /// Avancement de 0 a 1 pour la barre de progression.
  double get progression {
    final total = fin.difference(debut).inSeconds;
    if (total <= 0) return 0;
    final ecoule = DateTime.now().difference(debut).inSeconds;
    return (ecoule / total).clamp(0.0, 1.0);
  }

  String get plage {
    String h(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${h(debut)} - ${h(fin)}';
  }

  Map<String, dynamic> toJson() => {
        'c': chaine,
        'd': debut.millisecondsSinceEpoch,
        'f': fin.millisecondsSinceEpoch,
        't': titre,
        'x': description,
      };

  factory Programme.fromJson(Map<String, dynamic> j) => Programme(
        chaine: j['c'] as String,
        debut: DateTime.fromMillisecondsSinceEpoch(j['d'] as int),
        fin: DateTime.fromMillisecondsSinceEpoch(j['f'] as int),
        titre: j['t'] as String,
        description: j['x'] as String? ?? '',
      );
}

/// Guides preconfigures, verifies un par un.
///
/// EPGShare couvre le plus de chaines et livre du gzip, d ou l analyse en
/// flux plus bas. Les guides iptv-org sont plus legers mais moins fournis.
/// Les deux derniers ne servent que si vous apportez vous-meme une
/// playlist Pluto ou Samsung : leurs playlists ne sont plus publiees.
class GuidesEpg {
  static const List<({String nom, String url})> presets = [
    (
      nom: 'France - EPGShare (le plus complet)',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_FR1.xml.gz'
    ),
    (
      nom: 'Belgique - EPGShare',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_BE2.xml.gz'
    ),
    (
      nom: 'Suisse - EPGShare',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_CH1.xml.gz'
    ),
    (
      nom: 'Canada - EPGShare',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_CA2.xml.gz'
    ),
    (
      nom: 'Luxembourg - EPGShare',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_LU1.xml.gz'
    ),
    (
      nom: 'beIN Sports - EPGShare',
      url: 'https://epgshare01.online/epgshare01/epg_ripper_BEIN1.xml.gz'
    ),
    (
      nom: 'France - Orange (iptv-org)',
      url: 'https://iptv-org.github.io/epg/guides/fr/chaines-tv.orange.fr.xml'
    ),
    (
      nom: 'France - Programme TV (iptv-org)',
      url: 'https://iptv-org.github.io/epg/guides/fr/programme-tv.net.xml'
    ),
    (
      nom: 'France - Telerama (iptv-org)',
      url: 'https://iptv-org.github.io/epg/guides/fr/telerama.fr.xml'
    ),
    (
      nom: 'Quebec - TV Hebdo (iptv-org)',
      url: 'https://iptv-org.github.io/epg/guides/ca/tvhebdo.com.xml'
    ),
    (
      nom: 'Pluto TV France (playlist Pluto requise)',
      url: 'https://i.mjh.nz/PlutoTV/fr.xml'
    ),
    (
      nom: 'Samsung TV Plus France (playlist Samsung requise)',
      url: 'https://i.mjh.nz/SamsungTVPlus/fr.xml'
    ),
  ];
}

class EpgService {
  EpgService._();
  static final EpgService instance = EpgService._();

  /// On ne garde que cette fenetre autour de maintenant, pour la memoire.
  static const Duration _avant = Duration(hours: 3);
  static const Duration _apres = Duration(hours: 36);

  /// Garde-fou : au-dela on arrete d accumuler.
  static const int _maxProgrammes = 80000;

  /// chaine XMLTV -> emissions triees par heure de debut.
  final Map<String, List<Programme>> _parChaine = {};

  DateTime? derniereMaj;
  bool enCours = false;
  String etape = '';

  bool get disponible => _parChaine.isNotEmpty;
  int get nbChaines => _parChaine.length;
  int get nbProgrammes =>
      _parChaine.values.fold(0, (s, l) => s + l.length);

  /// Emission en cours sur une chaine, ou null.
  Programme? maintenant(String tvgId) {
    if (tvgId.isEmpty) return null;
    final l = _parChaine[tvgId];
    if (l == null) return null;
    final n = DateTime.now();
    for (final p in l) {
      if (p.debut.isAfter(n)) break;
      if (p.fin.isAfter(n)) return p;
    }
    return null;
  }

  /// Emission suivante sur une chaine, ou null.
  Programme? suivante(String tvgId) {
    if (tvgId.isEmpty) return null;
    final l = _parChaine[tvgId];
    if (l == null) return null;
    final n = DateTime.now();
    for (final p in l) {
      if (p.debut.isAfter(n)) return p;
    }
    return null;
  }

  /// Grille complete connue pour une chaine.
  List<Programme> grille(String tvgId) => _parChaine[tvgId] ?? const [];

  // ---- Telechargement et analyse ----

  /// Telecharge et analyse une liste de guides XMLTV.
  Future<String> charger(List<String> urls,
      {void Function(String etape)? onEtape}) async {
    if (enCours) return 'Chargement deja en cours.';
    enCours = true;
    _parChaine.clear();

    var total = 0;
    final erreurs = <String>[];

    try {
      for (final url in urls) {
        etape = 'Lecture de ${_court(url)}';
        onEtape?.call(etape);
        try {
          total += await _telechargerEtAnalyser(url);
        } catch (e) {
          erreurs.add('${_court(url)} : $e');
        }
        if (total >= _maxProgrammes) break;
      }

      for (final l in _parChaine.values) {
        l.sort((a, b) => a.debut.compareTo(b.debut));
      }

      derniereMaj = DateTime.now();
      await sauvegarder();
    } finally {
      enCours = false;
      etape = '';
    }

    if (total == 0) {
      return erreurs.isEmpty
          ? 'Aucune emission trouvee dans ces guides.'
          : 'Echec : ${erreurs.first}';
    }
    final suffixe = erreurs.isEmpty ? '' : ' (${erreurs.length} source(s) en echec)';
    return '$total emissions sur $nbChaines chaines$suffixe';
  }

  static String _court(String url) {
    final s = url.split('/');
    return s.isEmpty ? url : s.last;
  }

  /// Telecharge et analyse un guide sans jamais le charger entierement
  /// en memoire : les octets sont decompresses puis decodes au fil de
  /// l eau, et les emissions hors fenetre sont jetees immediatement.
  ///
  /// Un guide national fait couramment 50 Mo une fois decompresse : le
  /// tenir en memoire ferait tomber l application sur telephone.
  Future<int> _telechargerEtAnalyser(String url) async {
    final client = http.Client();
    final debutFenetre = DateTime.now().subtract(_avant);
    final finFenetre = DateTime.now().add(_apres);
    var gardes = 0;

    try {
      final req = http.Request('GET', Uri.parse(url))
        ..followRedirects = true;
      req.headers['User-Agent'] = 'IptvPlayer/6.0';

      final res = await client.send(req).timeout(const Duration(seconds: 120));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      Stream<List<int>> octets = res.stream;
      if (url.toLowerCase().endsWith('.gz')) {
        octets = octets.transform(gzip.decoder);
      }

      final texte = octets.transform(const Utf8Decoder(allowMalformed: true));

      await texte
          .toXmlEvents()
          .normalizeEvents()
          .selectSubtreeEvents((e) => e.localName == 'programme')
          .toXmlNodes()
          .forEach((noeuds) {
        for (final n in noeuds) {
          if (n is! XmlElement) continue;

          final chaine = n.getAttribute('channel');
          final debut = _date(n.getAttribute('start'));
          final fin = _date(n.getAttribute('stop'));
          if (chaine == null || debut == null || fin == null) continue;

          if (fin.isBefore(debutFenetre) || debut.isAfter(finFenetre)) {
            continue;
          }
          if (gardes >= _maxProgrammes) return;

          final titre = n.getElement('title')?.innerText.trim() ?? '';
          if (titre.isEmpty) continue;

          var desc = n.getElement('desc')?.innerText.trim() ?? '';
          if (desc.length > 400) desc = '${desc.substring(0, 400)}...';

          _parChaine.putIfAbsent(chaine, () => []).add(Programme(
                chaine: chaine,
                debut: debut,
                fin: fin,
                titre: titre,
                description: desc,
              ));
          gardes++;
        }
      });
    } finally {
      client.close();
    }

    return gardes;
  }

  /// Convertit une date XMLTV : 20260907183000 +0200
  static DateTime? _date(String? brut) {
    if (brut == null || brut.length < 14) return null;
    try {
      final d = brut.substring(0, 14);
      final an = int.parse(d.substring(0, 4));
      final mo = int.parse(d.substring(4, 6));
      final jo = int.parse(d.substring(6, 8));
      final he = int.parse(d.substring(8, 10));
      final mi = int.parse(d.substring(10, 12));
      final se = int.parse(d.substring(12, 14));

      // Decalage horaire eventuel, ex : " +0200"
      final reste = brut.substring(14).trim();
      if (reste.length >= 5 && (reste[0] == '+' || reste[0] == '-')) {
        final signe = reste[0] == '-' ? -1 : 1;
        final dh = int.parse(reste.substring(1, 3));
        final dm = int.parse(reste.substring(3, 5));
        final utc = DateTime.utc(an, mo, jo, he, mi, se)
            .subtract(Duration(hours: signe * dh, minutes: signe * dm));
        return utc.toLocal();
      }
      return DateTime(an, mo, jo, he, mi, se);
    } catch (_) {
      return null;
    }
  }

  // ---- Persistance ----

  static Future<File> _fichier() async {
    final base = await getApplicationSupportDirectory();
    return File('${base.path}${Platform.pathSeparator}epg.json');
  }

  Future<void> sauvegarder() async {
    try {
      final tout = <Map<String, dynamic>>[];
      for (final l in _parChaine.values) {
        for (final p in l) {
          tout.add(p.toJson());
        }
      }
      await (await _fichier()).writeAsString(jsonEncode({
        'date': derniereMaj?.toIso8601String(),
        'programmes': tout,
      }));
    } catch (_) {}
  }

  Future<void> chargerDepuisDisque() async {
    try {
      final f = await _fichier();
      if (!await f.exists()) return;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final d = data['date'] as String?;
      if (d != null) derniereMaj = DateTime.tryParse(d);

      final limite = DateTime.now().subtract(_avant);
      _parChaine.clear();
      for (final e in (data['programmes'] as List? ?? [])) {
        final p = Programme.fromJson(e as Map<String, dynamic>);
        if (p.fin.isBefore(limite)) continue; // emission deja terminee
        _parChaine.putIfAbsent(p.chaine, () => []).add(p);
      }
      for (final l in _parChaine.values) {
        l.sort((a, b) => a.debut.compareTo(b.debut));
      }
    } catch (_) {}
  }

  Future<void> effacer() async {
    _parChaine.clear();
    derniereMaj = null;
    try {
      final f = await _fichier();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
