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
  /// Les quatre premieres sont des services FAST officiels, gratuits et
  /// finances par la publicite. Leurs flux sont maintenus par les
  /// diffuseurs : ils ne tombent quasiment jamais, et leur EPG assorti
  /// utilise les memes identifiants, donc la grille se remplit du premier
  /// coup.
  static const List<SourcePreset> presets = [
    SourcePreset(
      'Pluto TV France',
      'https://i.mjh.nz/PlutoTV/fr.m3u8',
      'Service officiel gratuit, une quarantaine de chaines francaises. '
          'Guide assorti disponible. Le plus fiable.',
    ),
    SourcePreset(
      'Samsung TV Plus France',
      'https://i.mjh.nz/SamsungTVPlus/fr.m3u8',
      'Service officiel gratuit de Samsung, chaines francaises. '
          'Guide assorti disponible.',
    ),
    SourcePreset(
      'Pluto TV Canada',
      'https://i.mjh.nz/PlutoTV/ca.m3u8',
      'Service officiel gratuit, chaines canadiennes dont du francophone.',
    ),
    SourcePreset(
      'Samsung TV Plus Suisse',
      'https://i.mjh.nz/SamsungTVPlus/ch.m3u8',
      'Service officiel gratuit, chaines suisses.',
    ),
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
