import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';

/// Liste filtrable de chaines. Utilisee pour "Toutes les chaines",
/// les favoris, l'historique et le contenu d'un groupe.
class ChannelListScreen extends StatefulWidget {
  final String title;
  final List<Channel> channels;
  final bool showAppBar;

  const ChannelListScreen({
    super.key,
    required this.title,
    required this.channels,
    this.showAppBar = true,
  });

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Channel> get _filtered {
    if (_query.isEmpty) return widget.channels;
    final q = _query.toLowerCase();
    return widget.channels
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.group.toLowerCase().contains(q))
        .toList();
  }

  void _play(int indexInFiltered) {
    final list = _filtered;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          playlist: list,
          startIndex: indexInFiltered,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher une chaine...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${list.length} chaine(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.white54)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Aucun resultat.'))
              : ListView.builder(
                  itemCount: list.length,
                  itemExtent: 68,
                  itemBuilder: (_, i) => ChannelTile(
                    channel: list[i],
                    onTap: () => _play(i),
                    onFavoriteChanged: () => setState(() {}),
                  ),
                ),
        ),
      ],
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: body,
    );
  }
}
