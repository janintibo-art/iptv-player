import 'package:flutter/material.dart';

import '../services/m3u_service.dart';
import '../services/prefs_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url =
      TextEditingController(text: Prefs.sourceUrl);

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Source de la playlist',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _url,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'URL M3U',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () async {
                await Prefs.setSourceUrl(_url.text.trim());
                M3uService.instance.clearCache();
                _snack('Source enregistree. Rechargez la liste.');
              },
            ),
            OutlinedButton(
              onPressed: () {
                _url.text = Playlists.all;
                setState(() {});
              },
              child: const Text('Playlist iptv-org par defaut'),
            ),
          ],
        ),
        const Divider(height: 40),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Afficher les logos des chaines'),
          subtitle: const Text(
              'Desactivez pour economiser la data et fluidifier la liste.'),
          value: Prefs.showLogos,
          onChanged: (v) async {
            await Prefs.setShowLogos(v);
            setState(() {});
          },
        ),
        const Divider(height: 40),
        const Text('Donnees',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cached),
          title: const Text('Vider le cache des playlists'),
          onTap: () {
            M3uService.instance.clearCache();
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
