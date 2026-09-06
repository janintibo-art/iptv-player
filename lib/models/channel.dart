/// Une entree de playlist M3U.
class Channel {
  final String name;
  final String url;
  final String logo;
  final String group;
  final String tvgId;

  const Channel({
    required this.name,
    required this.url,
    this.logo = '',
    this.group = '',
    this.tvgId = '',
  });

  /// iptv-org suffixe les tvg-id par le code pays : "TF1.fr" -> "FR".
  String get countryCode {
    final i = tvgId.lastIndexOf('.');
    if (i == -1 || i == tvgId.length - 1) return '';
    return tvgId.substring(i + 1).toUpperCase();
  }

  bool get hasEpg => tvgId.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'tvgId': tvgId,
      };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        name: j['name'] as String? ?? '',
        url: j['url'] as String? ?? '',
        logo: j['logo'] as String? ?? '',
        group: j['group'] as String? ?? '',
        tvgId: j['tvgId'] as String? ?? '',
      );
}
