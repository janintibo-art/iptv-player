/// Sources M3U proposees dans les reglages.
class SourcePreset {
  final String name;
  final String url;
  final String description;

  const SourcePreset(this.name, this.url, this.description);
}

class Sources {
  static const String defaultUrl =
      'https://iptv-org.github.io/iptv/index.m3u';

  /// Sources francophones et generales.
  ///
  /// Note : les playlists Pluto TV et Samsung TV Plus ne sont plus
  /// publiees par i.mjh.nz, qui ne diffuse desormais que leurs guides.
  /// Elles ont donc ete retirees d ici.
  static const List<SourcePreset> presets = [
    SourcePreset(
      'Free-TV France',
      'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlists/playlist_france.m3u8',
      'Liste courte et bien entretenue : TF1, France 3, BFM TV, '
          'TV5 Monde, chaines regionales. Recommandee.',
    ),
    SourcePreset(
      'iptv-org - France',
      'https://iptv-org.github.io/iptv/countries/fr.m3u',
      'Toutes les chaines francaises indexees par iptv-org.',
    ),
    SourcePreset(
      'iptv-org - Langue francaise',
      'https://iptv-org.github.io/iptv/languages/fra.m3u',
      'Tout le contenu francophone, tous pays confondus.',
    ),
    SourcePreset(
      'iptv-org - Belgique',
      'https://iptv-org.github.io/iptv/countries/be.m3u',
      'Chaines belges.',
    ),
    SourcePreset(
      'iptv-org - Suisse',
      'https://iptv-org.github.io/iptv/countries/ch.m3u',
      'Chaines suisses.',
    ),
    SourcePreset(
      'iptv-org - Canada',
      'https://iptv-org.github.io/iptv/countries/ca.m3u',
      'Chaines canadiennes, dont le Quebec.',
    ),
    SourcePreset(
      'Free-TV - Monde',
      'https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8',
      'Toutes les chaines Free-TV. Peu de liens, mais fiables.',
    ),
    SourcePreset(
      'iptv-org - Tout le monde',
      defaultUrl,
      'Playlist complete, environ 15 000 chaines. Longue a charger.',
    ),
  ];
}
