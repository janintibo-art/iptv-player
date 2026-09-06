import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/channel.dart';

/// Playlists publiques du projet iptv-org.
class Playlists {
  static const String all =
      'https://iptv-org.github.io/iptv/index.m3u';
  static const String byCategory =
      'https://iptv-org.github.io/iptv/index.category.m3u';
  static const String byCountry =
      'https://iptv-org.github.io/iptv/index.country.m3u';
  static const String byLanguage =
      'https://iptv-org.github.io/iptv/index.language.m3u';
}

class M3uService {
  M3uService._();
  static final M3uService instance = M3uService._();

  final Map<String, List<Channel>> _cache = {};
  static final RegExp _attr = RegExp(r'([\w-]+)="([^"]*)"');

  bool isCached(String url) => _cache.containsKey(url);

  void clearCache() => _cache.clear();

  /// Telecharge (ou relit depuis le cache memoire) une playlist.
  Future<List<Channel>> load(String url, {bool force = false}) async {
    if (!force && _cache.containsKey(url)) return _cache[url]!;

    final res = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'IptvPlayer/1.0'})
        .timeout(const Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Erreur HTTP ${res.statusCode} sur $url');
    }

    final channels = parse(utf8.decode(res.bodyBytes, allowMalformed: true));
    _cache[url] = channels;
    return channels;
  }

  /// Analyse le contenu texte d'un fichier M3U.
  List<Channel> parse(String content) {
    final lines = const LineSplitter().convert(content);
    final out = <Channel>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;

      // Attributs : tvg-id, tvg-logo, group-title...
      final attrs = <String, String>{};
      for (final m in _attr.allMatches(line)) {
        attrs[m.group(1)!] = m.group(2)!;
      }

      // Le nom se trouve apres la derniere virgule qui suit les attributs.
      final lastQuote = line.lastIndexOf('"');
      final commaIdx = line.indexOf(',', lastQuote == -1 ? 0 : lastQuote);
      final name = commaIdx == -1
          ? (attrs['tvg-name'] ?? 'Sans nom')
          : line.substring(commaIdx + 1).trim();

      // L'URL est la premiere ligne suivante qui n'est ni vide ni un commentaire.
      String url = '';
      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isEmpty || next.startsWith('#')) continue;
        url = next;
        break;
      }
      if (url.isEmpty) continue;

      out.add(Channel(
        name: name.isEmpty ? 'Sans nom' : name,
        url: url,
        logo: attrs['tvg-logo'] ?? '',
        group: attrs['group-title'] ?? '',
        tvgId: attrs['tvg-id'] ?? '',
      ));
    }
    return out;
  }

  /// Regroupe les chaines par group-title (categorie, pays ou langue).
  Map<String, List<Channel>> groupBy(List<Channel> channels) {
    final map = <String, List<Channel>>{};
    for (final c in channels) {
      final key = c.group.trim().isEmpty ? 'Non classe' : c.group.trim();
      map.putIfAbsent(key, () => []).add(c);
    }
    final sorted = map.keys.toList()..sort();
    return {for (final k in sorted) k: map[k]!};
  }
}
