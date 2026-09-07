import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';
import 'sources.dart';

/// Stockage local : favoris, historique et reglages.
class Prefs {
  static late SharedPreferences _p;

  static const _kFavorites = 'favorites';
  static const _kRecents = 'recents';
  static const _kSources = 'source_urls';
  static const _kCustom = 'custom_sources';
  static const _kShowLogos = 'show_logos';
  static const _kAutoSubs = 'auto_subtitles';
  static const _kAutoZap = 'auto_zap';
  static const _kHideOffline = 'hide_offline';
  static const _kEpgUrls = 'epg_urls';

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    await _migrer();
  }

  /// Reprend le reglage d une version anterieure (une seule source).
  static Future<void> _migrer() async {
    if (_p.containsKey(_kSources)) return;
    final ancien = _p.getString('source_url');
    await setSourceUrls([ancien ?? Sources.presets.first.url]);
  }

  // ---- Sources actives (plusieurs possibles) ----
  static List<String> get sourceUrls {
    final raw = _p.getString(_kSources);
    if (raw == null || raw.isEmpty) return [Sources.presets.first.url];
    try {
      final l = (jsonDecode(raw) as List).cast<String>();
      return l.isEmpty ? [Sources.presets.first.url] : l;
    } catch (_) {
      return [Sources.presets.first.url];
    }
  }

  static Future<void> setSourceUrls(List<String> urls) =>
      _p.setString(_kSources, jsonEncode(urls));

  static Future<void> toggleSource(String url) async {
    final l = sourceUrls;
    if (l.contains(url)) {
      if (l.length > 1) l.remove(url); // il en faut toujours au moins une
    } else {
      l.add(url);
    }
    await setSourceUrls(l);
  }

  /// URLs ajoutees a la main ou fichiers locaux importes.
  static List<SourcePreset> get customSources {
    final raw = _p.getString(_kCustom);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SourcePreset(
                e['name'] as String,
                e['url'] as String,
                e['description'] as String? ?? '',
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addCustomSource(SourcePreset s) async {
    final l = customSources..removeWhere((e) => e.url == s.url);
    l.insert(0, s);
    await _p.setString(
      _kCustom,
      jsonEncode(l
          .map((e) =>
              {'name': e.name, 'url': e.url, 'description': e.description})
          .toList()),
    );
  }

  static Future<void> removeCustomSource(String url) async {
    final l = customSources..removeWhere((e) => e.url == url);
    await _p.setString(
      _kCustom,
      jsonEncode(l
          .map((e) =>
              {'name': e.name, 'url': e.url, 'description': e.description})
          .toList()),
    );
    final actives = sourceUrls..remove(url);
    await setSourceUrls(actives.isEmpty ? [Sources.presets.first.url] : actives);
  }

  // ---- Options ----
  static bool get showLogos => _p.getBool(_kShowLogos) ?? true;
  static Future<void> setShowLogos(bool v) => _p.setBool(_kShowLogos, v);

  static bool get autoSubtitles => _p.getBool(_kAutoSubs) ?? true;
  static Future<void> setAutoSubtitles(bool v) => _p.setBool(_kAutoSubs, v);

  static bool get autoZap => _p.getBool(_kAutoZap) ?? true;
  static Future<void> setAutoZap(bool v) => _p.setBool(_kAutoZap, v);

  static bool get hideOffline => _p.getBool(_kHideOffline) ?? false;
  static Future<void> setHideOffline(bool v) => _p.setBool(_kHideOffline, v);

  // ---- Guide des programmes ----
  static List<String> get epgUrls {
    final raw = _p.getString(_kEpgUrls);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> setEpgUrls(List<String> urls) =>
      _p.setString(_kEpgUrls, jsonEncode(urls));

  static Future<void> toggleEpgUrl(String url) async {
    final l = epgUrls;
    l.contains(url) ? l.remove(url) : l.add(url);
    await setEpgUrls(l);
  }

  // ---- Favoris ----
  static List<Channel> get favorites => _read(_kFavorites);

  static bool isFavorite(Channel c) => favorites.any((f) => f.url == c.url);

  static Future<void> toggleFavorite(Channel c) async {
    final list = favorites;
    final i = list.indexWhere((f) => f.url == c.url);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, c);
    }
    await _write(_kFavorites, list);
  }

  static Future<void> setFavorites(List<Channel> list) =>
      _write(_kFavorites, list);

  static Future<void> clearFavorites() => _p.remove(_kFavorites);

  // ---- Historique ----
  static List<Channel> get recents => _read(_kRecents);

  static Future<void> pushRecent(Channel c) async {
    final list = recents..removeWhere((r) => r.url == c.url);
    list.insert(0, c);
    if (list.length > 50) list.removeRange(50, list.length);
    await _write(_kRecents, list);
  }

  static Future<void> clearRecents() => _p.remove(_kRecents);

  // ---- Interne ----
  static List<Channel> _read(String key) {
    final raw = _p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(String key, List<Channel> list) =>
      _p.setString(key, jsonEncode(list.map((c) => c.toJson()).toList()));
}
