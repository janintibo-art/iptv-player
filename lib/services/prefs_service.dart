import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/channel.dart';

/// Stockage local : favoris, historique et reglages.
class Prefs {
  static late SharedPreferences _p;

  static const _kFavorites = 'favorites';
  static const _kRecents = 'recents';
  static const _kSource = 'source_url';
  static const _kShowLogos = 'show_logos';

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  // ---- Reglages ----
  static String get sourceUrl =>
      _p.getString(_kSource) ?? 'https://iptv-org.github.io/iptv/index.m3u';

  static Future<void> setSourceUrl(String v) => _p.setString(_kSource, v);

  static bool get showLogos => _p.getBool(_kShowLogos) ?? true;

  static Future<void> setShowLogos(bool v) => _p.setBool(_kShowLogos, v);

  // ---- Favoris ----
  static List<Channel> get favorites => _read(_kFavorites);

  static bool isFavorite(Channel c) =>
      favorites.any((f) => f.url == c.url);

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
      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((e) => Channel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(String key, List<Channel> list) =>
      _p.setString(key, jsonEncode(list.map((c) => c.toJson()).toList()));
}
