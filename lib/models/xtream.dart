import 'dart:convert';

/// Un compte serveur Xtream Codes enregistre sur l appareil.
class XtreamAccount {
  final String nom;
  final String base; // http://hote:port, sans chemin
  final String user;
  final String pass;

  const XtreamAccount({
    required this.nom,
    required this.base,
    required this.user,
    required this.pass,
  });

  /// Identifiant stable, sert de cle de stockage.
  String get id => '$base|$user';

  Map<String, dynamic> toJson() =>
      {'n': nom, 'b': base, 'u': user, 'p': pass};

  factory XtreamAccount.fromJson(Map<String, dynamic> j) => XtreamAccount(
        nom: j['n'] as String? ?? '',
        base: j['b'] as String? ?? '',
        user: j['u'] as String? ?? '',
        pass: j['p'] as String? ?? '',
      );
}

/// Categorie de contenu (direct, film ou serie).
class XtreamCategorie {
  final String id;
  final String nom;

  const XtreamCategorie(this.id, this.nom);

  factory XtreamCategorie.fromJson(Map<String, dynamic> j) => XtreamCategorie(
        '${j['category_id'] ?? ''}',
        '${j['category_name'] ?? 'Sans nom'}',
      );
}

/// Chaine en direct.
class XtreamLive {
  final String id;
  final String nom;
  final String logo;
  final String epgId;
  final String categorieId;

  /// Le serveur conserve-t-il un enregistrement, et sur combien de jours.
  final bool archive;
  final int archiveJours;

  const XtreamLive({
    required this.id,
    required this.nom,
    this.logo = '',
    this.epgId = '',
    this.categorieId = '',
    this.archive = false,
    this.archiveJours = 0,
  });

  factory XtreamLive.fromJson(Map<String, dynamic> j) {
    final arc = j['tv_archive'];
    return XtreamLive(
      id: '${j['stream_id'] ?? ''}',
      nom: '${j['name'] ?? 'Sans nom'}',
      logo: '${j['stream_icon'] ?? ''}',
      epgId: '${j['epg_channel_id'] ?? ''}',
      categorieId: '${j['category_id'] ?? ''}',
      archive: arc == 1 || arc == '1',
      archiveJours: int.tryParse('${j['tv_archive_duration'] ?? 0}') ?? 0,
    );
  }
}

/// Film du catalogue a la demande.
class XtreamFilm {
  final String id;
  final String nom;
  final String affiche;
  final String extension;
  final String categorieId;
  final String note;

  const XtreamFilm({
    required this.id,
    required this.nom,
    this.affiche = '',
    this.extension = 'mp4',
    this.categorieId = '',
    this.note = '',
  });

  factory XtreamFilm.fromJson(Map<String, dynamic> j) => XtreamFilm(
        id: '${j['stream_id'] ?? ''}',
        nom: '${j['name'] ?? 'Sans nom'}',
        affiche: '${j['stream_icon'] ?? ''}',
        extension: '${j['container_extension'] ?? 'mp4'}',
        categorieId: '${j['category_id'] ?? ''}',
        note: '${j['rating'] ?? ''}',
      );
}

/// Serie du catalogue.
class XtreamSerie {
  final String id;
  final String nom;
  final String affiche;
  final String categorieId;
  final String resume;

  const XtreamSerie({
    required this.id,
    required this.nom,
    this.affiche = '',
    this.categorieId = '',
    this.resume = '',
  });

  factory XtreamSerie.fromJson(Map<String, dynamic> j) => XtreamSerie(
        id: '${j['series_id'] ?? ''}',
        nom: '${j['name'] ?? 'Sans nom'}',
        affiche: '${j['cover'] ?? ''}',
        categorieId: '${j['category_id'] ?? ''}',
        resume: '${j['plot'] ?? ''}',
      );
}

/// Episode d une serie.
class XtreamEpisode {
  final String id;
  final String titre;
  final String extension;
  final int saison;
  final int numero;
  final String resume;

  const XtreamEpisode({
    required this.id,
    required this.titre,
    this.extension = 'mp4',
    this.saison = 1,
    this.numero = 0,
    this.resume = '',
  });

  factory XtreamEpisode.fromJson(Map<String, dynamic> j, int saison) {
    final info = j['info'];
    return XtreamEpisode(
      id: '${j['id'] ?? ''}',
      titre: '${j['title'] ?? 'Episode'}',
      extension: '${j['container_extension'] ?? 'mp4'}',
      saison: int.tryParse('${j['season'] ?? saison}') ?? saison,
      numero: int.tryParse('${j['episode_num'] ?? 0}') ?? 0,
      resume: info is Map ? '${info['plot'] ?? ''}' : '',
    );
  }
}

/// Une entree du guide renvoyee par le serveur, utilisee pour le catch-up.
class XtreamEmission {
  final String titre;
  final String description;
  final DateTime debut;
  final DateTime fin;

  const XtreamEmission({
    required this.titre,
    required this.description,
    required this.debut,
    required this.fin,
  });

  /// Duree en minutes, ce que reclame l URL de timeshift.
  int get dureeMinutes => fin.difference(debut).inMinutes.clamp(1, 600);

  bool get passee => fin.isBefore(DateTime.now());

  String get plage {
    String h(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${h(debut)} - ${h(fin)}';
  }

  /// Le serveur encode les libelles en base64.
  static String _decoder(dynamic v) {
    final s = '${v ?? ''}';
    if (s.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(s), allowMalformed: true);
    } catch (_) {
      return s;
    }
  }

  static DateTime? _date(dynamic v) {
    final s = '${v ?? ''}';
    if (s.isEmpty) return null;
    // Format habituel : "2026-09-07 20:00:00"
    return DateTime.tryParse(s.replaceFirst(' ', 'T'));
  }

  static XtreamEmission? fromJson(Map<String, dynamic> j) {
    final d = _date(j['start']);
    final f = _date(j['end'] ?? j['stop']);
    if (d == null || f == null) return null;
    return XtreamEmission(
      titre: _decoder(j['title']),
      description: _decoder(j['description']),
      debut: d,
      fin: f,
    );
  }
}
