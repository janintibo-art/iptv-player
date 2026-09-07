import 'dart:convert';

import 'package:http/http.dart' as http;

/// Informations renvoyees par un serveur Xtream Codes.
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

/// Construit les adresses d un serveur Xtream Codes / panel IPTV.
///
/// C est le protocole utilise par la quasi-totalite des panels : a partir
/// d une adresse, d un identifiant et d un mot de passe, il expose une
/// playlist M3U et un guide XMLTV a des adresses standardisees.
class XtreamService {
  /// Normalise l adresse : ajoute http:// si absent, retire le / final
  /// et tout chemin parasite colle par l utilisateur.
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

  /// Adresse de la playlist complete (live, films, series).
  static String urlPlaylist(String base, String user, String pass) =>
      '$base/get.php?username=${Uri.encodeQueryComponent(user)}'
      '&password=${Uri.encodeQueryComponent(pass)}'
      '&type=m3u_plus&output=ts';

  /// Adresse du guide des programmes fourni par le serveur.
  static String urlEpg(String base, String user, String pass) =>
      '$base/xmltv.php?username=${Uri.encodeQueryComponent(user)}'
      '&password=${Uri.encodeQueryComponent(pass)}';

  static String _urlApi(String base, String user, String pass) =>
      '$base/player_api.php?username=${Uri.encodeQueryComponent(user)}'
      '&password=${Uri.encodeQueryComponent(pass)}';

  /// Masque le mot de passe pour l affichage et les journaux.
  static String masquer(String url) =>
      url.replaceAll(RegExp(r'password=[^&]*'), 'password=***');

  /// Interroge le serveur pour valider les identifiants.
  static Future<InfoServeur> tester(
      String base, String user, String pass) async {
    if (base.isEmpty || user.isEmpty || pass.isEmpty) {
      return const InfoServeur(
          ok: false, message: 'Adresse, identifiant et mot de passe requis.');
    }

    try {
      final res = await http
          .get(Uri.parse(_urlApi(base, user, pass)),
              headers: {'User-Agent': 'IptvPlayer/5.2'})
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 401 || res.statusCode == 403) {
        return const InfoServeur(
            ok: false, message: 'Identifiants refuses par le serveur.');
      }
      if (res.statusCode != 200) {
        return InfoServeur(
            ok: false, message: 'Le serveur a repondu ${res.statusCode}.');
      }

      final data = jsonDecode(res.body);
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
            ok: false, message: 'Authentification refusee.');
      }

      DateTime? exp;
      final brut = info['exp_date'];
      if (brut != null && '$brut'.isNotEmpty && '$brut' != 'null') {
        final s = int.tryParse('$brut');
        if (s != null) {
          exp = DateTime.fromMillisecondsSinceEpoch(s * 1000);
        }
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
      return InfoServeur(
          ok: false, message: 'Serveur injoignable : $e');
    }
  }
}
