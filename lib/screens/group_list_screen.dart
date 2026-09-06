import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/m3u_service.dart';
import 'channel_list_screen.dart';

/// Affiche les groupes d'une playlist (categorie / pays / langue),
/// puis les chaines du groupe choisi.
class GroupListScreen extends StatefulWidget {
  final String title;
  final String playlistUrl;
  final IconData icon;

  const GroupListScreen({
    super.key,
    required this.title,
    required this.playlistUrl,
    this.icon = Icons.folder,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  late Future<Map<String, List<Channel>>> _future;
  final _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, List<Channel>>> _load({bool force = false}) async {
    final channels =
        await M3uService.instance.load(widget.playlistUrl, force: force);
    return M3uService.instance.groupBy(channels);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Channel>>>(
      future: _future,
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
        if (snap.hasError) {
          return Center(
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
                        setState(() => _future = _load(force: true)),
                  ),
                ],
              ),
            ),
          );
        }

        final groups = snap.data!;
        final keys = groups.keys
            .where((k) => k.toLowerCase().contains(_query.toLowerCase()))
            .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
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
      },
    );
  }
}
