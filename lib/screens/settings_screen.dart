import 'package:flutter/material.dart';

import '../services/cache_service.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import '../services/sources.dart';
import '../services/stream_check_service.dart';
import '../services/transfert_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _url = TextEditingController();
  final _nom = TextEditingController();

  int _tailleCache = 0;
  bool _occupe = false;

  @override
  void initState() {
    super.initState();
    _infosCache();
  }

  Future<void> _infosCache() async {
    final t = await CacheService.size();
    if (mounted) setState(() => _tailleCache = t);
  }

  @override
  void dispose() {
    _url.dispose();
    _nom.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _basculer(String url) async {
    final avant = Prefs.sourceUrls.length;
    await Prefs.toggleSource(url);
    if (Prefs.sourceUrls.length == avant && avant == 1) {
      _snack('Gardez au moins une source active.');
    }
    M3uService.instance.clearMemory();
    setState(() {});
  }

  Future<void> _ajouterUrl() async {
    final u = _url.text.trim();
    if (u.isEmpty || !u.startsWith('http')) {
      _snack('Entrez une URL commencant par http.');
      return;
    }
    await Prefs.addCustomSource(SourcePreset(
      _nom.text.trim().isEmpty ? u : _nom.text.trim(),
      u,
      'Source ajoutee manuellement.',
    ));
    await Prefs.toggleSource(u);
    _url.clear();
    _nom.clear();
    M3uService.instance.clearMemory();
    setState(() {});
    _snack('Source ajoutee et activee.');
  }

  Future<void> _action(Future<ResultatFichier> Function() f) async {
    setState(() => _occupe = true);
    final r = await f();
    if (!mounted) return;
    setState(() => _occupe = false);
    M3uService.instance.clearMemory();
    _snack(r.message);
  }

  String get _tailleLisible {
    if (_tailleCache < 1024) return '$_tailleCache o';
    if (_tailleCache < 1024 * 1024) {
      return '${(_tailleCache / 1024).toStringAsFixed(0)} Ko';
    }
    return '${(_tailleCache / 1048576).toStringAsFixed(1)} Mo';
  }

  Widget _carteSource(SourcePreset p, {bool supprimable = false}) {
    final actif = Prefs.sourceUrls.contains(p.url);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: actif ? const Color(0xFF17323A) : const Color(0xFF161B22),
      child: ListTile(
        leading: Icon(
          actif ? Icons.check_box : Icons.check_box_outline_blank,
          color: actif ? const Color(0xFF7FD4E8) : null,
        ),
        title: Text(p.name),
        subtitle: Text(p.description, style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
        trailing: supprimable
            ? IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Retirer cette source',
                onPressed: () async {
                  await Prefs.removeCustomSource(p.url);
                  M3uService.instance.clearMemory();
                  setState(() {});
                },
              )
            : null,
        onTap: () => _basculer(p.url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final check = StreamCheckService.instance;
    final perso = Prefs.customSources;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Sources actives',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Cochez plusieurs sources : elles sont fusionnees et les '
              'doublons retires. ${Prefs.sourceUrls.length} active(s).',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            ...Sources.presets.map((p) => _carteSource(p)),

            if (perso.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Vos sources',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...perso.map((p) => _carteSource(p, supprimable: true)),
            ],

            const Divider(height: 40),
            const Text('Ajouter une source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nom,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nom (facultatif)',
                isDense: true,
              ),
            ),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.add_link),
                  label: const Text('Ajouter l URL'),
                  onPressed: _ajouterUrl,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Ouvrir un fichier .m3u'),
                  onPressed: () =>
                      _action(TransfertService.importerPlaylist),
                ),
              ],
            ),

            const Divider(height: 40),
            const Text('Disponibilite des flux',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF161B22),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (check.nbTestes == 0)
                      const Text(
                        'Aucun test effectue. Utilisez le bouton "Tester" '
                        'en haut de la liste des chaines.',
                        style: TextStyle(fontSize: 13),
                      )
                    else ...[
                      Text('${check.nbEnLigne} en ligne, '
                          '${check.nbHorsLigne} hors ligne'),
                      const SizedBox(height: 4),
                      Text('${check.nbTestes} chaine(s) testee(s)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54)),
                    ],
                  ],
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Masquer les chaines hors ligne'),
              subtitle: const Text(
                  'N affiche que les flux qui ont repondu au dernier test.'),
              value: Prefs.hideOffline,
              onChanged: (v) async {
                await Prefs.setHideOffline(v);
                setState(() {});
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Zapping automatique'),
              subtitle: const Text(
                  'Passe a la chaine suivante si le flux ne demarre pas '
                  'en 12 secondes. S arrete apres 15 sauts.'),
              value: Prefs.autoZap,
              onChanged: (v) async {
                await Prefs.setAutoZap(v);
                setState(() {});
              },
            ),
            if (check.nbTestes > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restart_alt),
                title: const Text('Effacer les resultats de test'),
                onTap: () async {
                  await check.effacer();
                  setState(() {});
                  _snack('Resultats effaces.');
                },
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
                  'Active la piste francaise du flux si elle existe.'),
              value: Prefs.autoSubtitles,
              onChanged: (v) async {
                await Prefs.setAutoSubtitles(v);
                setState(() {});
              },
            ),

            const Divider(height: 40),
            const Text('Sauvegarde des favoris',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              '${Prefs.favorites.length} favori(s) enregistre(s).',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Exporter'),
                  onPressed: () => _action(TransfertService.exporterFavoris),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Importer'),
                  onPressed: () => _action(TransfertService.importerFavoris),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'L import ajoute les favoris aux votres sans rien ecraser.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),

            const Divider(height: 40),
            const Text('Donnees',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Cache disque : $_tailleLisible',
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cached),
              title: const Text('Vider le cache des playlists'),
              subtitle: const Text(
                  'Les fichiers .m3u importes devront etre reimportes.'),
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
                setState(() {});
                _snack('Favoris effaces.');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history),
              title: const Text('Effacer l historique'),
              onTap: () async {
                await Prefs.clearRecents();
                setState(() {});
                _snack('Historique efface.');
              },
            ),
          ],
        ),
        if (_occupe)
          Container(
            color: Colors.black54,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
