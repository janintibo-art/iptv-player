import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/channel.dart';

/// Etat connu d un flux.
enum EtatFlux { inconnu, enLigne, horsLigne }

/// Teste la disponibilite des flux et memorise le resultat.
///
/// Un test consiste a demander les tout premiers octets du flux : si le
/// serveur repond, le lien est vivant. On ne telecharge pas la video.
class StreamCheckService {
  StreamCheckService._();
  static final StreamCheckService instance = StreamCheckService._();

  /// Resultats : url -> en ligne ?
  final Map<String, bool> _resultats = {};
  DateTime? _dernierTest;

  bool enCours = false;
  int fait = 0;
  int total = 0;
  bool _annule = false;

  DateTime? get dernierTest => _dernierTest;

  int get nbEnLigne => _resultats.values.where((v) => v).length;
  int get nbHorsLigne => _resultats.values.where((v) => !v).length;
  int get nbTestes => _resultats.length;

  EtatFlux etat(Channel c) {
    final r = _resultats[c.url];
    if (r == null) return EtatFlux.inconnu;
    return r ? EtatFlux.enLigne : EtatFlux.horsLigne;
  }

  bool estHorsLigne(Channel c) => _resultats[c.url] == false;

  void annuler() => _annule = true;

  /// Test unitaire d un flux. Vrai si le serveur repond correctement.
  static Future<bool> tester(String url,
      {Duration timeout = const Duration(seconds: 8)}) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url))
        ..followRedirects = true
        ..maxRedirects = 5;
      req.headers['Range'] = 'bytes=0-1';
      req.headers['User-Agent'] = 'IptvPlayer/4.0';

      final res = await client.send(req).timeout(timeout);
      return res.statusCode >= 200 && res.statusCode < 400;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Teste toute une liste, 8 flux en parallele.
  Future<void> testerListe(
    List<Channel> channels, {
    void Function(int fait, int total)? onProgress,
  }) async {
    if (enCours) return;
    enCours = true;
    _annule = false;
    fait = 0;
    total = channels.length;

    final file = List<Channel>.from(channels);

    Future<void> ouvrier() async {
      while (file.isNotEmpty && !_annule) {
        final c = file.removeLast();
        _resultats[c.url] = await tester(c.url);
        fait++;
        onProgress?.call(fait, total);
      }
    }

    await Future.wait(List.generate(8, (_) => ouvrier()));

    _dernierTest = DateTime.now();
    enCours = false;
    await sauvegarder();
  }

  // ---- Persistance ----

  static Future<File> _fichier() async {
    final base = await getApplicationSupportDirectory();
    return File('${base.path}${Platform.pathSeparator}etat_flux.json');
  }

  Future<void> sauvegarder() async {
    try {
      final f = await _fichier();
      await f.writeAsString(jsonEncode({
        'date': _dernierTest?.toIso8601String(),
        'resultats': _resultats,
      }));
    } catch (_) {}
  }

  Future<void> charger() async {
    try {
      final f = await _fichier();
      if (!await f.exists()) return;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      final d = data['date'] as String?;
      if (d != null) _dernierTest = DateTime.tryParse(d);
      final r = data['resultats'] as Map<String, dynamic>?;
      if (r != null) {
        _resultats.clear();
        r.forEach((k, v) => _resultats[k] = v == true);
      }
    } catch (_) {}
  }

  Future<void> effacer() async {
    _resultats.clear();
    _dernierTest = null;
    try {
      final f = await _fichier();
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
