import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import 'about_screen.dart';
import 'channel_list_screen.dart';
import 'group_list_screen.dart';
import 'settings_screen.dart';

enum Section {
  all,
  favorites,
  recents,
  categories,
  countries,
  languages,
  settings,
  about
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Section _section = Section.all;
  Future<List<Channel>>? _allFuture;
  String _loadedUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({bool force = false}) {
    _loadedUrl = Prefs.sourceUrl;
    _allFuture = M3uService.instance.load(_loadedUrl, force: force);
  }

  void _reloadAll() => setState(() => _load(force: true));

  String get _title => switch (_section) {
        Section.all => 'Toutes les chaines',
        Section.favorites => 'Favoris',
        Section.recents => 'Historique',
        Section.categories => 'Categories',
        Section.countries => 'Pays',
        Section.languages => 'Langues',
        Section.settings => 'Reglages',
        Section.about => 'Aide et a propos',
      };

  Widget _erreur(Object e, VoidCallback retry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text('Echec du chargement.\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reessayer'),
                onPressed: retry,
              ),
            ],
          ),
        ),
      );

  Widget _buildBody() {
    switch (_section) {
      case Section.all:
        // La source a change dans les reglages : on recharge.
        if (_loadedUrl != Prefs.sourceUrl) _load();

        return FutureBuilder<List<Channel>>(
          future: _allFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Telechargement de la playlist...'),
                  ],
                ),
              );
            }
            if (snap.hasError) return _erreur(snap.error!, _reloadAll);
            return ChannelListScreen(
              title: _title,
              channels: snap.data!,
              showAppBar: false,
            );
          },
        );

      case Section.favorites:
        final favs = Prefs.favorites;
        if (favs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucun favori.\nTouchez l etoile a cote d une chaine '
                'pour l ajouter ici.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ChannelListScreen(
            title: _title, channels: favs, showAppBar: false);

      case Section.recents:
        final rec = Prefs.recents;
        if (rec.isEmpty) {
          return const Center(child: Text('Aucune chaine ouverte recemment.'));
        }
        return ChannelListScreen(
            title: _title, channels: rec, showAppBar: false);

      case Section.categories:
        return const GroupListScreen(
          title: 'Categories',
          playlistUrl: Playlists.byCategory,
          icon: Icons.category,
        );

      case Section.countries:
        return const GroupListScreen(
          title: 'Pays',
          playlistUrl: Playlists.byCountry,
          icon: Icons.public,
        );

      case Section.languages:
        return const GroupListScreen(
          title: 'Langues',
          playlistUrl: Playlists.byLanguage,
          icon: Icons.translate,
        );

      case Section.settings:
        return const SettingsScreen();

      case Section.about:
        return const AboutScreen();
    }
  }

  Widget _item(Section s, IconData icon, String label, {String? sub}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle:
          sub == null ? null : Text(sub, style: const TextStyle(fontSize: 11)),
      selected: _section == s,
      selectedTileColor: Colors.white10,
      onTap: () {
        Navigator.pop(context);
        setState(() => _section = s);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          if (_section == Section.all)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recharger la playlist',
              onPressed: _reloadAll,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0D1117)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset('assets/icon/icon.png',
                      height: 64,
                      errorBuilder: (_, __, ___) => const Icon(Icons.live_tv,
                          size: 44, color: Color(0xFF7FD4E8))),
                  const SizedBox(height: 10),
                  const Text('Lecteur IPTV', style: TextStyle(fontSize: 20)),
                  const Text('v3 - playlists publiques',
                      style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ),
            _item(Section.all, Icons.list, 'Toutes les chaines',
                sub: 'Source active + recherche'),
            _item(Section.favorites, Icons.star, 'Favoris',
                sub: 'Vos chaines enregistrees'),
            _item(Section.recents, Icons.history, 'Historique',
                sub: '50 dernieres chaines vues'),
            const Divider(),
            _item(Section.categories, Icons.category, 'Categories',
                sub: 'News, sport, musique...'),
            _item(Section.countries, Icons.public, 'Pays',
                sub: 'Regroupe par pays'),
            _item(Section.languages, Icons.translate, 'Langues',
                sub: 'Regroupe par langue'),
            const Divider(),
            _item(Section.settings, Icons.settings, 'Reglages',
                sub: 'Sources FR, sous-titres, cache'),
            _item(Section.about, Icons.help_outline, 'Aide et a propos'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }
}
