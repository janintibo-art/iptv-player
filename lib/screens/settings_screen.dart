import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _apply(String url) async {
    await Prefs.setSourceUrl(url.trim());
    M3uService.instance.clearCache();
    _url.text = url.trim();
    setState(() {});
    _snack('Source changee. Ouvrez "Toutes les chaines".');
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
          'Touchez une source pour l activer. Les listes courtes se '
          'chargent en quelques secondes.',
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
