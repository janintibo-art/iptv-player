import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/channel.dart';
import 'cache_service.dart';

/// Playlists publiques du projet iptv-org.
class Playlists {
  static const String all = 'https://iptv-org.github.io/iptv/index.m3u';
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

  /// Au-dela de cette duree le cache disque est considere comme perime.
  static const Duration validite = Duration(hours: 12);

  final Map<String, List<Channel>> _memoire = {};
  static final RegExp _attr = RegExp(r'([\w-]+)="([^"]*)"');

  /// Vrai si la derniere lecture venait du cache et non du reseau.
  bool venaitDuCache = false;

  void clearMemory() => _memoire.clear();

  Future<void> clearAll() async {
    _memoire.clear();
    await CacheService.clear();
  }

  /// Charge une playlist. Ordre de priorite :
  /// 1. memoire, 2. cache disque recent, 3. reseau, 4. cache disque perime.
  Future<List<Channel>> load(String url, {bool force = false}) async {
    if (!force && _memoire.containsKey(url)) {
      return _memoire[url]!;
    }

    if (!force) {
      final recent = await CacheService.read(url, maxAge: validite);
      if (recent != null) {
        venaitDuCache = true;
        final ch = parse(recent);
        _memoire[url] = ch;
        return ch;
      }
    }

    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'IptvPlayer/3.0'})
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        throw Exception('Erreur HTTP ${res.statusCode}');
      }

      final texte = utf8.decode(res.bodyBytes, allowMalformed: true);
      await CacheService.write(url, texte);

      venaitDuCache = false;
      final ch = parse(texte);
      _memoire[url] = ch;
      return ch;
    } catch (e) {
      // Pas de reseau : on se rabat sur le cache, meme perime.
      final vieux = await CacheService.read(url);
      if (vieux != null) {
        venaitDuCache = true;
        final ch = parse(vieux);
        _memoire[url] = ch;
        return ch;
      }
      rethrow;
    }
  }

  /// Analyse le contenu texte d un fichier M3U.
  List<Channel> parse(String content) {
    final lines = const LineSplitter().convert(content);
    final out = <Channel>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;

      final attrs = <String, String>{};
      for (final m in _attr.allMatches(line)) {
        attrs[m.group(1)!] = m.group(2)!;
      }

      final lastQuote = line.lastIndexOf('"');
      final commaIdx = line.indexOf(',', lastQuote == -1 ? 0 : lastQuote);
      final name = commaIdx == -1
          ? (attrs['tvg-name'] ?? 'Sans nom')
          : line.substring(commaIdx + 1).trim();

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

  /// Regroupe les chaines par group-title.
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
