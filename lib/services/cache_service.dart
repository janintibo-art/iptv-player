import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Cache disque des playlists : demarrage instantane et consultation
/// hors ligne. Un fichier par URL, plus la date de telechargement.
class CacheService {
  static Directory? _dir;

  static Future<Directory> _dossier() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}${Platform.pathSeparator}playlists');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  /// Nom de fichier stable et sans caractere interdit, derive de l URL.
  static String _nom(String url) {
    var h = 0;
    for (final c in url.codeUnits) {
      h = (h * 31 + c) & 0x7FFFFFFF;
    }
    return 'pl_$h.m3u';
  }

  static Future<File> _fichier(String url) async =>
      File('${(await _dossier()).path}${Platform.pathSeparator}${_nom(url)}');

  /// Ecrit le contenu brut du M3U sur le disque.
  static Future<void> write(String url, String contenu) async {
    try {
      await (await _fichier(url)).writeAsString(contenu);
    } catch (_) {
      // Un echec d ecriture ne doit jamais bloquer la lecture.
    }
  }

  /// Relit le cache. Si [maxAge] est fourni, renvoie null si trop ancien.
  static Future<String?> read(String url, {Duration? maxAge}) async {
    try {
      final f = await _fichier(url);
      if (!await f.exists()) return null;
      if (maxAge != null) {
        final age = DateTime.now().difference(await f.lastModified());
        if (age > maxAge) return null;
      }
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Date du dernier telechargement reussi, ou null.
  static Future<DateTime?> lastUpdate(String url) async {
    try {
      final f = await _fichier(url);
      if (!await f.exists()) return null;
      return await f.lastModified();
    } catch (_) {
      return null;
    }
  }

  /// Taille totale du cache en octets.
  static Future<int> size() async {
    try {
      var total = 0;
      await for (final e in (await _dossier()).list()) {
        if (e is File) total += await e.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> clear() async {
    try {
      final d = await _dossier();
      if (await d.exists()) await d.delete(recursive: true);
      _dir = null;
    } catch (_) {}
  }
}
