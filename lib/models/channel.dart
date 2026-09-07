/// Une entree de playlist M3U.
class Channel {
  final String name;
  final String url;
  final String logo;
  final String group;
  final String tvgId;

  /// En-tetes HTTP specifiques, issus des lignes #EXTVLCOPT ou saisis a la
  /// main. Certains serveurs refusent les flux sans User-Agent ou Referer.
  final String userAgent;
  final String referer;

  const Channel({
    required this.name,
    required this.url,
    this.logo = '',
    this.group = '',
    this.tvgId = '',
    this.userAgent = '',
    this.referer = '',
  });

  /// iptv-org suffixe les tvg-id par le code pays : "TF1.fr" -> "FR".
  String get countryCode {
    final i = tvgId.lastIndexOf('.');
    if (i == -1 || i == tvgId.length - 1) return '';
    return tvgId.substring(i + 1).toUpperCase();
  }

  bool get hasEpg => tvgId.isNotEmpty;

  /// Protocole du flux : http, rtsp, rtmp, udp...
  String get protocole {
    final i = url.indexOf(':');
    return i <= 0 ? '' : url.substring(0, i).toLowerCase();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'logo': logo,
        'group': group,
        'tvgId': tvgId,
        if (userAgent.isNotEmpty) 'ua': userAgent,
        if (referer.isNotEmpty) 'ref': referer,
      };

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        name: j['name'] as String? ?? '',
        url: j['url'] as String? ?? '',
        logo: j['logo'] as String? ?? '',
        group: j['group'] as String? ?? '',
        tvgId: j['tvgId'] as String? ?? '',
        userAgent: j['ua'] as String? ?? '',
        referer: j['ref'] as String? ?? '',
      );
}
