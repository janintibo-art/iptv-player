import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/xtream.dart';

/// Informations de compte renvoyees par le serveur.
class InfoServeur {
  final bool ok;
  final String message;
  final String? utilisateur;
  final String? statut;
  final DateTime? expiration;
  final int? connexionsMax;

  const InfoServeur({
    required this.ok,
    required this.message,
    this.utilisateur,
    this.statut,
    this.expiration,
    this.connexionsMax,
  });
}

/// Client complet de l API Xtream Codes.
///
/// Deux modes coexistent dans l application :
///   - mode M3U : une seule URL, tout est telecharge d un bloc
///   - mode API : chargement a la demande, avec films, series et catch-up
///
/// Cette classe implemente le second.
class XtreamService {
  XtreamService._();
  static final XtreamService instance = XtreamService._();

  /// Cache memoire des reponses, par cle d appel.
  final Map<String, dynamic> _cache = {};

  void viderCache() => _cache.clear();

  // ------------------------------------------------------------ adresses

  /// Normalise l adresse : ajoute http:// si absent, applique le port,
  /// retire tout chemin colle par erreur.
  static String normaliserBase(String saisie, {String port = ''}) {
    var s = saisie.trim();
    if (s.isEmpty) return '';
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }

    Uri u;
    try {
      u = Uri.parse(s);
    } catch (_) {
      return '';
    }

    final p = port.trim();
    if (p.isNotEmpty) {
      final n = int.tryParse(p);
      if (n != null) u = u.replace(port: n);
    }

    final base = StringBuffer('${u.scheme}://${u.host}');
    if (u.hasPort) base.write(':${u.port}');
    return base.toString();
  }

  static String _e(String v) => Uri.encodeComponent(v);

  /// Playlist M3U complete, pour le mode simple.
  static String urlPlaylist(XtreamAccount c) =>
      '${c.base}/get.php?username=${_e(c.user)}&password=${_e(c.pass)}'
      '&type=m3u_plus&output=ts';

  /// Guide XMLTV fourni par le serveur.
  static String urlEpg(XtreamAccount c) =>
      '${c.base}/xmltv.php?username=${_e(c.user)}&password=${_e(c.pass)}';

  /// Flux d une chaine en direct.
  static String urlLive(XtreamAccount c, String streamId) =>
      '${c.base}/live/${_e(c.user)}/${_e(c.pass)}/$streamId.m3u8';

  /// Flux d un film.
  static String urlFilm(XtreamAccount c, String id, String ext) =>
      '${c.base}/movie/${_e(c.user)}/${_e(c.pass)}/$id.$ext';

  /// Flux d un episode de serie.
  static String urlEpisode(XtreamAccount c, String id, String ext) =>
      '${c.base}/series/${_e(c.user)}/${_e(c.pass)}/$id.$ext';

  /// Rediffusion d une emission passee (catch-up / timeshift).
  ///
  /// Le serveur attend la date de debut au format aaaa-mm-jj:hh-mm et une
  /// duree en minutes.
  static String urlCatchup(
      XtreamAccount c, String streamId, DateTime debut, int minutes) {
    String d2(int v) => v.toString().padLeft(2, '0');
    final start = '${debut.year}-${d2(debut.month)}-${d2(debut.day)}:'
        '${d2(debut.hour)}-${d2(debut.minute)}';
    return '${c.base}/streaming/timeshift.php?username=${_e(c.user)}'
        '&password=${_e(c.pass)}&stream=$streamId'
        '&start=$start&duration=$minutes';
  }

  /// Masque le mot de passe avant tout affichage.
  static String masquer(String url) =>
      url.replaceAll(RegExp(r'password=[^&]*'), 'password=***');

  // ------------------------------------------------------------- requetes

  Future<dynamic> _appel(XtreamAccount c, String action,
      {Map<String, String> params = const {}, bool cacher = true}) async {
    final cle = '${c.id}|$action|'
        '${params.entries.map((e) => '${e.key}=${e.value}').join(',')}';
    if (cacher && _cache.containsKey(cle)) return _cache[cle];

    final q = StringBuffer('${c.base}/player_api.php'
        '?username=${_e(c.user)}&password=${_e(c.pass)}');
    if (action.isNotEmpty) q.write('&action=$action');
    params.forEach((k, v) => q.write('&$k=${_e(v)}'));

    final res = await http
        .get(Uri.parse(q.toString()),
            headers: {'User-Agent': 'IptvPlayer/6.0'})
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Le serveur a repondu ${res.statusCode}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    if (cacher) _cache[cle] = data;
    return data;
  }

  List<Map<String, dynamic>> _liste(dynamic data) {
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    return const [];
  }

  // ---------------------------------------------------------- connexion

  /// Verifie les identifiants et renvoie l etat de l abonnement.
  Future<InfoServeur> tester(XtreamAccount c) async {
    if (c.base.isEmpty || c.user.isEmpty || c.pass.isEmpty) {
      return const InfoServeur(
          ok: false, message: 'Adresse, identifiant et mot de passe requis.');
    }

    try {
      final data = await _appel(c, '', cacher: false);
      if (data is! Map || data['user_info'] is! Map) {
        return const InfoServeur(
          ok: false,
          message: 'Reponse inattendue : ce n est peut-etre pas un '
              'serveur Xtream Codes.',
        );
      }

      final info = data['user_info'] as Map;
      final auth = info['auth'];
      if (auth != 1 && auth != '1') {
        return const InfoServeur(
            ok: false, message: 'Identifiants refuses par le serveur.');
      }

      DateTime? exp;
      final brut = '${info['exp_date'] ?? ''}';
      if (brut.isNotEmpty && brut != 'null') {
        final s = int.tryParse(brut);
        if (s != null) exp = DateTime.fromMillisecondsSinceEpoch(s * 1000);
      }

      final statut = '${info['status'] ?? ''}';
      if (statut.toLowerCase() == 'expired') {
        return InfoServeur(
          ok: false,
          message: 'Compte expire'
              '${exp == null ? '' : ' le ${exp.day}/${exp.month}/${exp.year}'}.',
          expiration: exp,
        );
      }

      return InfoServeur(
        ok: true,
        message: 'Connexion reussie.',
        utilisateur: '${info['username'] ?? ''}',
        statut: statut,
        expiration: exp,
        connexionsMax: int.tryParse('${info['max_connections'] ?? ''}'),
      );
    } catch (e) {
      return InfoServeur(ok: false, message: 'Serveur injoignable : $e');
    }
  }

  // ------------------------------------------------------------- direct

  Future<List<XtreamCategorie>> categoriesLive(XtreamAccount c) async =>
      _liste(await _appel(c, 'get_live_categories'))
          .map(XtreamCategorie.fromJson)
          .toList();

  Future<List<XtreamLive>> live(XtreamAccount c, {String? categorie}) async =>
      _liste(await _appel(c, 'get_live_streams',
              params: categorie == null ? {} : {'category_id': categorie}))
          .map(XtreamLive.fromJson)
          .toList();

  // -------------------------------------------------------------- films

  Future<List<XtreamCategorie>> categoriesFilms(XtreamAccount c) async =>
      _liste(await _appel(c, 'get_vod_categories'))
          .map(XtreamCategorie.fromJson)
          .toList();

  Future<List<XtreamFilm>> films(XtreamAccount c, {String? categorie}) async =>
      _liste(await _appel(c, 'get_vod_streams',
              params: categorie == null ? {} : {'category_id': categorie}))
          .map(XtreamFilm.fromJson)
          .toList();

  // ------------------------------------------------------------- series

  Future<List<XtreamCategorie>> categoriesSeries(XtreamAccount c) async =>
      _liste(await _appel(c, 'get_series_categories'))
          .map(XtreamCategorie.fromJson)
          .toList();

  Future<List<XtreamSerie>> series(XtreamAccount c,
          {String? categorie}) async =>
      _liste(await _appel(c, 'get_series',
              params: categorie == null ? {} : {'category_id': categorie}))
          .map(XtreamSerie.fromJson)
          .toList();

  /// Episodes d une serie, regroupes par saison.
  Future<Map<int, List<XtreamEpisode>>> episodes(
      XtreamAccount c, String serieId) async {
    final data =
        await _appel(c, 'get_series_info', params: {'series_id': serieId});
    if (data is! Map) return {};

    final brut = data['episodes'];
    final out = <int, List<XtreamEpisode>>{};

    void ajouter(int saison, dynamic liste) {
      if (liste is! List) return;
      for (final e in liste) {
        if (e is Map<String, dynamic>) {
          out.putIfAbsent(saison, () => []).add(
                XtreamEpisode.fromJson(e, saison),
              );
        }
      }
    }

    // Selon les serveurs, "episodes" est un objet ou un tableau.
    if (brut is Map) {
      brut.forEach((k, v) => ajouter(int.tryParse('$k') ?? 1, v));
    } else if (brut is List) {
      for (var i = 0; i < brut.length; i++) {
        ajouter(i + 1, brut[i]);
      }
    }

    for (final l in out.values) {
      l.sort((a, b) => a.numero.compareTo(b.numero));
    }
    return out;
  }

  // ------------------------------------------------------------ catch-up

  /// Grille recente d une chaine, pour proposer les rediffusions.
  Future<List<XtreamEmission>> guideChaine(
      XtreamAccount c, String streamId) async {
    try {
      final data = await _appel(c, 'get_simple_data_table',
          params: {'stream_id': streamId}, cacher: false);
      if (data is! Map) return [];
      final l = _liste(data['epg_listings'])
          .map(XtreamEmission.fromJson)
          .whereType<XtreamEmission>()
          .toList();
      l.sort((a, b) => b.debut.compareTo(a.debut));
      return l;
    } catch (_) {
      return [];
    }
  }
}
