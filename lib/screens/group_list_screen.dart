import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/groupes.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import 'channel_list_screen.dart';

/// Affiche les groupes puis les chaines du groupe choisi.
///
/// Deux modes : vos propres sources, ou les listes d iptv-org. Le choix est
/// memorise. Le regroupement par langue n existe qu en mode iptv-org : le
/// format M3U ne transporte aucune information de langue.
class GroupListScreen extends StatefulWidget {
  final String title;
  final TypeGroupe type;
  final String playlistUrl;
  final IconData icon;

  const GroupListScreen({
    super.key,
    required this.title,
    required this.type,
    required this.playlistUrl,
    this.icon = Icons.folder,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late ModeGroupe _mode;
  late Future<Map<String, List<Channel>>> _future;
  final _controller = TextEditingController();
  String _query = '';

  bool get _langueSansChoix => widget.type == TypeGroupe.langue;

  @override
  void initState() {
    super.initState();
    _mode = _langueSansChoix ? ModeGroupe.iptvOrg : Prefs.modeGroupe;
    _future = _charger();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Map<String, List<Channel>>> _charger({bool force = false}) async {
    final m3u = M3uService.instance;

    if (_mode == ModeGroupe.iptvOrg) {
      final channels = await m3u.load(widget.playlistUrl, force: force);
      return m3u.groupBy(channels);
    }

    final channels = await m3u.loadMerged(Prefs.sourceUrls, force: force);
    return switch (widget.type) {
      TypeGroupe.categorie => m3u.groupBy(channels),
      TypeGroupe.pays => _grouperParPays(channels),
      TypeGroupe.langue => m3u.groupBy(channels),
    };
  }

  /// Regroupe d apres le suffixe du tvg-id, seule information de pays
  /// presente dans une playlist M3U.
  Map<String, List<Channel>> _grouperParPays(List<Channel> channels) {
    final map = <String, List<Channel>>{};
    for (final c in channels) {
      final code = c.countryCode;
      final cle = code.isEmpty ? 'Pays inconnu' : (_pays[code] ?? code);
      map.putIfAbsent(cle, () => []).add(c);
    }
    final cles = map.keys.toList()..sort();
    // "Pays inconnu" en dernier, il est rarement ce qu on cherche.
    cles.remove('Pays inconnu');
    if (map.containsKey('Pays inconnu')) cles.add('Pays inconnu');
    return {for (final k in cles) k: map[k]!};
  }

  Future<void> _changerMode(ModeGroupe m) async {
    if (!_langueSansChoix) await Prefs.setModeGroupe(m);
    setState(() {
      _mode = m;
      _future = _charger();
    });
  }

  Widget _selecteurMode() {
    if (_langueSansChoix) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Le regroupement par langue vient d iptv-org : une playlist M3U ne '
          'transporte aucune information de langue.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: SegmentedButton<ModeGroupe>(
        segments: const [
          ButtonSegment(
            value: ModeGroupe.mesSources,
            label: Text('Mes sources'),
            icon: Icon(Icons.layers, size: 16),
          ),
          ButtonSegment(
            value: ModeGroupe.iptvOrg,
            label: Text('iptv-org'),
            icon: Icon(Icons.public, size: 16),
          ),
        ],
        selected: {_mode},
        showSelectedIcon: false,
        onSelectionChanged: (s) => _changerMode(s.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Channel>>>(
      future: _future,
      builder: (context, snap) {
        Widget corps;

        if (snap.connectionState != ConnectionState.done) {
          corps = const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Chargement...'),
              ],
            ),
          );
        } else if (snap.hasError) {
          corps = Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48),
                  const SizedBox(height: 12),
                  Text('Echec du chargement.\n${snap.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reessayer'),
                    onPressed: () =>
                        setState(() => _future = _charger(force: true)),
                  ),
                ],
              ),
            ),
          );
        } else {
          final groups = snap.data!;
          final keys = groups.keys
              .where((k) => k.toLowerCase().contains(_query.toLowerCase()))
              .toList();

          if (groups.isEmpty) {
            corps = const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun groupe.\nVos sources ne fournissent pas cette '
                  'information, essayez le mode iptv-org.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            corps = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Filtrer (${groups.length} groupes)',
                      prefixIcon: const Icon(Icons.filter_list),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: keys.length,
                    itemBuilder: (_, i) {
                      final key = keys[i];
                      final channels = groups[key]!;
                      return ListTile(
                        leading: Icon(widget.icon),
                        title: Text(key),
                        subtitle: Text('${channels.length} chaine(s)',
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChannelListScreen(
                              title: key,
                              channels: channels,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        }

        return Column(
          children: [
            _selecteurMode(),
            Expanded(child: corps),
          ],
        );
      },
    );
  }

  /// Codes pays les plus courants, pour un affichage lisible.
  static const Map<String, String> _pays = {
    'FR': 'France',
    'BE': 'Belgique',
    'CH': 'Suisse',
    'CA': 'Canada',
    'LU': 'Luxembourg',
    'MC': 'Monaco',
    'DZ': 'Algerie',
    'MA': 'Maroc',
    'TN': 'Tunisie',
    'SN': 'Senegal',
    'CI': 'Cote d Ivoire',
    'CM': 'Cameroun',
    'ML': 'Mali',
    'CD': 'Congo (RDC)',
    'CG': 'Congo',
    'BF': 'Burkina Faso',
    'GA': 'Gabon',
    'TG': 'Togo',
    'BJ': 'Benin',
    'NE': 'Niger',
    'TD': 'Tchad',
    'MG': 'Madagascar',
    'MU': 'Maurice',
    'HT': 'Haiti',
    'US': 'Etats-Unis',
    'UK': 'Royaume-Uni',
    'GB': 'Royaume-Uni',
    'DE': 'Allemagne',
    'ES': 'Espagne',
    'IT': 'Italie',
    'PT': 'Portugal',
    'NL': 'Pays-Bas',
    'IE': 'Irlande',
    'AT': 'Autriche',
    'PL': 'Pologne',
    'RO': 'Roumanie',
    'GR': 'Grece',
    'TR': 'Turquie',
    'RU': 'Russie',
    'UA': 'Ukraine',
    'SE': 'Suede',
    'NO': 'Norvege',
    'DK': 'Danemark',
    'FI': 'Finlande',
    'CZ': 'Tchequie',
    'HU': 'Hongrie',
    'BR': 'Bresil',
    'MX': 'Mexique',
    'AR': 'Argentine',
    'CL': 'Chili',
    'CO': 'Colombie',
    'PE': 'Perou',
    'JP': 'Japon',
    'KR': 'Coree du Sud',
    'CN': 'Chine',
    'IN': 'Inde',
    'ID': 'Indonesie',
    'TH': 'Thailande',
    'VN': 'Vietnam',
    'PH': 'Philippines',
    'AU': 'Australie',
    'NZ': 'Nouvelle-Zelande',
    'ZA': 'Afrique du Sud',
    'EG': 'Egypte',
    'SA': 'Arabie saoudite',
    'AE': 'Emirats arabes unis',
    'QA': 'Qatar',
    'IL': 'Israel',
    'IR': 'Iran',
    'PK': 'Pakistan',
    'NG': 'Nigeria',
    'KE': 'Kenya',
    'INT': 'International',
  };
}
