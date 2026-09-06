import 'package:flutter/material.dart';

import '../services/cache_service.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import '../services/sources.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url =
      TextEditingController(text: Prefs.sourceUrl);

  int _tailleCache = 0;
  DateTime? _maj;

  @override
  void initState() {
    super.initState();
    _infosCache();
  }

  Future<void> _infosCache() async {
    final t = await CacheService.size();
    final m = await CacheService.lastUpdate(Prefs.sourceUrl);
    if (mounted) setState(() {
      _tailleCache = t;
      _maj = m;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _apply(String url) async {
    await Prefs.setSourceUrl(url.trim());
    M3uService.instance.clearMemory();
    _url.text = url.trim();
    await _infosCache();
    _snack('Source changee. Ouvrez "Toutes les chaines".');
  }

  String get _tailleLisible {
    if (_tailleCache < 1024) return '$_tailleCache o';
    if (_tailleCache < 1024 * 1024) {
      return '${(_tailleCache / 1024).toStringAsFixed(0)} Ko';
    }
    return '${(_tailleCache / 1048576).toStringAsFixed(1)} Mo';
  }

  String get _majLisible {
    if (_maj == null) return 'jamais telechargee';
    final d = DateTime.now().difference(_maj!);
    if (d.inMinutes < 1) return 'a l instant';
    if (d.inHours < 1) return 'il y a ${d.inMinutes} min';
    if (d.inDays < 1) return 'il y a ${d.inHours} h';
    return 'il y a ${d.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final active = Prefs.sourceUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Sources francophones',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'Touchez une source pour l activer. Elle est ensuite gardee en '
          'memoire sur l appareil et consultable hors ligne.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 12),
        ...Sources.presets.map((p) {
          final selected = p.url == active;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: selected ? const Color(0xFF17323A) : const Color(0xFF161B22),
            child: ListTile(
              leading: Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? const Color(0xFF7FD4E8) : null,
              ),
              title: Text(p.name),
              subtitle:
                  Text(p.description, style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
              onTap: () => _apply(p.url),
            ),
          );
        }),
        const Divider(height: 40),
        const Text('URL personnalisee',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Lien vers un fichier .m3u ou .m3u8',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer cette URL'),
          onPressed: () => _apply(_url.text),
        ),
        const Divider(height: 40),
        const Text('Affichage et lecture',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Afficher les logos'),
          subtitle: const Text(
              'Desactivez pour economiser la data et fluidifier la liste.'),
          value: Prefs.showLogos,
          onChanged: (v) async {
            await Prefs.setShowLogos(v);
            setState(() {});
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sous-titres automatiques'),
          subtitle: const Text(
              'Active la piste francaise du flux si elle existe. '
              'La plupart des flux publics n en ont aucune.'),
          value: Prefs.autoSubtitles,
          onChanged: (v) async {
            await Prefs.setAutoSubtitles(v);
            setState(() {});
          },
        ),
        const Divider(height: 40),
        const Text('Cache et donnees',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(
          color: const Color(0xFF161B22),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Source active mise a jour $_majLisible'),
                const SizedBox(height: 4),
                Text('Cache disque : $_tailleLisible',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 4),
                const Text(
                  'Les playlists sont retelechargees automatiquement '
                  'apres 12 heures.',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cached),
          title: const Text('Vider le cache des playlists'),
          subtitle: const Text('Force un retelechargement complet.'),
          onTap: () async {
            await M3uService.instance.clearAll();
            await _infosCache();
            _snack('Cache vide.');
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.star_border),
          title: const Text('Effacer tous les favoris'),
          onTap: () async {
            await Prefs.clearFavorites();
            _snack('Favoris effaces.');
            setState(() {});
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history),
          title: const Text('Effacer l historique'),
          onTap: () async {
            await Prefs.clearRecents();
            _snack('Historique efface.');
            setState(() {});
          },
        ),
      ],
    );
  }
}
