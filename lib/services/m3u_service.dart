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

  /// Prefixe des sources importees depuis un fichier de l appareil.
  static const String prefixeLocal = 'local:';

  static const Duration validite = Duration(hours: 12);

  final Map<String, List<Channel>> _memoire = {};
  static final RegExp _attr = RegExp(r'([\w-]+)="([^"]*)"');

  /// Nombre de doublons retires lors de la derniere fusion.
  int doublonsRetires = 0;

  void clearMemory() => _memoire.clear();

  Future<void> clearAll() async {
    _memoire.clear();
    await CacheService.clear();
  }

  /// Enregistre une playlist importee depuis un fichier local.
  Future<void> enregistrerLocale(String cle, String contenu) async {
    await CacheService.write(cle, contenu);
    _memoire.remove(cle);
  }

  /// Charge plusieurs sources et les fusionne en retirant les doublons.
  ///
  /// Deux entrees sont considerees identiques si elles pointent vers la
  /// meme URL, ou si elles portent le meme nom normalise.
  Future<List<Channel>> loadMerged(List<String> urls,
      {bool force = false}) async {
    final vues = <String>{};
    final noms = <String>{};
    final out = <Channel>[];
    var doublons = 0;
    Object? derniereErreur;

    for (final url in urls) {
      List<Channel> liste;
      try {
        liste = await load(url, force: force);
      } catch (e) {
        derniereErreur = e;
        continue; // une source morte ne doit pas faire tomber les autres
      }

      for (final c in liste) {
        final nom = _normaliser(c.name);
        if (vues.contains(c.url) || noms.contains(nom)) {
          doublons++;
          continue;
        }
        vues.add(c.url);
        noms.add(nom);
        out.add(c);
      }
    }

    doublonsRetires = doublons;

    if (out.isEmpty && derniereErreur != null) throw derniereErreur;
    return out;
  }

  /// Enleve la resolution, la casse et la ponctuation pour comparer les noms.
  String _normaliser(String nom) => nom
      .toLowerCase()
      .replaceAll(RegExp(r'\(\s*\d+p\s*\)'), '')
      .replaceAll(RegExp(r'\b(hd|fhd|sd|uhd|4k|1080p?|720p?|576p?|480p?)\b'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .trim();

  /// Charge une playlist. Ordre : memoire, cache recent, reseau, cache perime.
  Future<List<Channel>> load(String url, {bool force = false}) async {
    if (!force && _memoire.containsKey(url)) return _memoire[url]!;

    // Fichier importe depuis l appareil : jamais de reseau.
    if (url.startsWith(prefixeLocal)) {
      final contenu = await CacheService.read(url);
      if (contenu == null) {
        throw Exception('Fichier importe introuvable. Reimportez-le.');
      }
      final ch = parse(contenu);
      _memoire[url] = ch;
      return ch;
    }

    if (!force) {
      final recent = await CacheService.read(url, maxAge: validite);
      if (recent != null) {
        final ch = parse(recent);
        _memoire[url] = ch;
        return ch;
      }
    }

    try {
      final res = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'IptvPlayer/4.0'})
          .timeout(const Duration(seconds: 60));

      if (res.statusCode != 200) {
        throw Exception('Erreur HTTP ${res.statusCode}');
      }

      final texte = utf8.decode(res.bodyBytes, allowMalformed: true);
      await CacheService.write(url, texte);

      final ch = parse(texte);
      _memoire[url] = ch;
      return ch;
    } catch (e) {
      final vieux = await CacheService.read(url);
      if (vieux != null) {
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

      // Lignes intercalaires avant l URL : options VLC et groupe.
      var groupe = attrs['group-title'] ?? '';
      var userAgent = '';
      var referer = '';
      String url = '';

      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isEmpty) continue;

        if (next.startsWith('#EXTVLCOPT:')) {
          final opt = next.substring(11);
          final eq = opt.indexOf('=');
          if (eq > 0) {
            final cle = opt.substring(0, eq).trim().toLowerCase();
            final val = opt.substring(eq + 1).trim();
            if (cle == 'http-user-agent') userAgent = val;
            if (cle == 'http-referrer' || cle == 'http-referer') referer = val;
          }
          continue;
        }
        if (next.startsWith('#EXTGRP:')) {
          if (groupe.isEmpty) groupe = next.substring(8).trim();
          continue;
        }
        if (next.startsWith('#')) continue;

        url = next;
        break;
      }
      if (url.isEmpty) continue;

      out.add(Channel(
        name: name.isEmpty ? 'Sans nom' : name,
        url: url,
        logo: attrs['tvg-logo'] ?? '',
        group: groupe,
        tvgId: attrs['tvg-id'] ?? '',
        userAgent: userAgent,
        referer: referer,
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
