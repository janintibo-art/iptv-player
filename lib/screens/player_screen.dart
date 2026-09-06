import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../models/channel.dart';
import '../services/prefs_service.dart';

class PlayerScreen extends StatefulWidget {
  final List<Channel> playlist;
  final int startIndex;

  const PlayerScreen({
    super.key,
    required this.playlist,
    required this.startIndex,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _video;
  late int _index;
  String? _error;

  Channel get _current => widget.playlist[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _player = Player();
    _video = VideoController(_player);
    _player.stream.error.listen((e) {
      if (mounted) setState(() => _error = e);
    });
    _open();
  }

  Future<void> _open() async {
    setState(() => _error = null);
    await Prefs.pushRecent(_current);
    await _player.open(Media(_current.url));
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.playlist.length) return;
    setState(() => _index = next);
    _open();
  }

  @override
  void dispose() {
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fav = Prefs.isFavorite(_current);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_current.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: Icon(fav ? Icons.star : Icons.star_border,
                color: fav ? Colors.amber : null),
            tooltip: 'Favori',
            onPressed: () async {
              await Prefs.toggleFavorite(_current);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Relancer le flux',
            onPressed: _open,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Video(
                  controller: _video,
                  controls: AdaptiveVideoControls,
                  fit: BoxFit.contain,
                ),
                if (_error != null)
                  Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 44, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        const Text(
                          'Ce flux ne repond pas.\n'
                          'Beaucoup de liens publics sont hors ligne : '
                          'essayez une autre chaine.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _open,
                          child: const Text('Reessayer'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF161B22),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  tooltip: 'Chaine precedente',
                  onPressed: _index > 0 ? () => _go(-1) : null,
                ),
                Flexible(
                  child: Text(
                    '${_index + 1} / ${widget.playlist.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  tooltip: 'Chaine suivante',
                  onPressed: _index < widget.playlist.length - 1
                      ? () => _go(1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
