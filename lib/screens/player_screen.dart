import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/channel.dart';
import '../services/epg_service.dart';
import '../services/pip_service.dart';
import '../services/prefs_service.dart';
import '../services/stream_check_service.dart';

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
  /// Au-dela, on arrete de zapper tout seul pour ne pas boucler indefiniment.
  static const int _maxSautsAuto = 15;

  /// Delai avant de considerer qu un flux ne demarrera pas.
  static const Duration _delaiDemarrage = Duration(seconds: 12);

  late final Player _player;
  late final VideoController _video;
  late int _index;

  String? _error;
  bool _subsApplied = false;
  bool _pleinEcran = false;
  bool _aDemarre = false;
  int _sautsAuto = 0;
  Timer? _minuteur;
  bool _pipDispo = false;

  Channel get _current => widget.playlist[_index];

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex;
    _player = Player();
    _video = VideoController(_player);

    WakelockPlus.enable();

    PipService.disponible().then((v) {
      if (mounted) setState(() => _pipDispo = v);
    });

    // Le flux repond : on annule le zapping automatique.
    _player.stream.playing.listen((joue) {
      if (joue && mounted) {
        _aDemarre = true;
        _sautsAuto = 0;
        _minuteur?.cancel();
      }
    });

    _player.stream.error.listen((e) {
      if (!mounted) return;
      setState(() => _error = e);
      _zapperSiPossible('flux en erreur');
    });

    _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      setState(() {});
      if (Prefs.autoSubtitles && !_subsApplied) {
        final fr = _chercherPisteFr(tracks.subtitle);
        if (fr != null) {
          _subsApplied = true;
          _player.setSubtitleTrack(fr);
        }
      }
    });

    _open();
  }

  SubtitleTrack? _chercherPisteFr(List<SubtitleTrack> pistes) {
    for (final t in pistes) {
      final code = '${t.language ?? ''} ${t.title ?? ''}'.toLowerCase();
      if (code.contains('fr') ||
          code.contains('fra') ||
          code.contains('french') ||
          code.contains('franc')) {
        return t;
      }
    }
    return null;
  }

  Future<void> _open() async {
    _minuteur?.cancel();
    setState(() {
      _error = null;
      _subsApplied = false;
      _aDemarre = false;
    });

    await Prefs.pushRecent(_current);
    await _player.open(Media(_current.url));

    // Si rien ne demarre dans le delai imparti, on passe a la suite.
    _minuteur = Timer(_delaiDemarrage, () {
      if (!mounted || _aDemarre) return;
      _zapperSiPossible('aucune image apres 12 s');
    });
  }

  /// Passe a la chaine suivante quand le flux courant ne repond pas.
  void _zapperSiPossible(String raison) {
    if (!Prefs.autoZap) return;
    if (_sautsAuto >= _maxSautsAuto) return;
    if (_index >= widget.playlist.length - 1) return;

    _sautsAuto++;
    final ancienne = _current.name;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Text('$ancienne : $raison, passage a la suivante'),
      ));

    _go(1, auto: true);
  }

  void _go(int delta, {bool auto = false}) {
    final next = _index + delta;
    if (next < 0 || next >= widget.playlist.length) return;
    if (!auto) _sautsAuto = 0; // un zapping manuel remet le compteur a zero
    setState(() => _index = next);
    _open();
  }

  Future<void> _basculerPleinEcran() async {
    _pleinEcran = !_pleinEcran;

    if (_pleinEcran) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    if (mounted) setState(() {});
  }

  void _menuSousTitres() {
    final pistes = _player.state.tracks.subtitle;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sous-titres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (pistes.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  'Ce flux ne contient aucune piste de sous-titres.\n\n'
                  'C est le cas de la quasi-totalite des chaines publiques : '
                  'les sous-titres de la TNT passent par le teletexte, qui '
                  'disparait lors de la conversion en flux internet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: pistes.map((t) {
                    final actif = _player.state.track.subtitle.id == t.id;
                    return ListTile(
                      leading: Icon(actif
                          ? Icons.check_circle
                          : Icons.subtitles_outlined),
                      title: Text(t.title ?? t.language ?? 'Piste ${t.id}'),
                      subtitle: t.language == null
                          ? null
                          : Text(t.language!,
                              style: const TextStyle(fontSize: 12)),
                      onTap: () {
                        _player.setSubtitleTrack(t);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Desactiver les sous-titres'),
              onTap: () {
                _player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  void _menuAudio() {
    final pistes = _player.state.tracks.audio;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Pistes audio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            if (pistes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune piste detectee pour le moment.'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: pistes.map((t) {
                    final actif = _player.state.track.audio.id == t.id;
                    return ListTile(
                      leading:
                          Icon(actif ? Icons.check_circle : Icons.audiotrack),
                      title: Text(t.title ?? t.language ?? 'Piste ${t.id}'),
                      onTap: () {
                        _player.setAudioTrack(t);
                        Navigator.pop(context);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _player.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Emission en cours sur la chaine, si le guide est charge.
  Widget _bandeauEpg() {
    final p = EpgService.instance.maintenant(_current.tvgId);
    if (p == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: const Color(0xFF17323A),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${p.plage}   ${p.titre}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: p.progression,
            minHeight: 2,
            backgroundColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _zoneVideo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Video(
          controller: _video,
          controls: AdaptiveVideoControls,
          fit: BoxFit.contain,
          subtitleViewConfiguration: const SubtitleViewConfiguration(
            visible: true,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              backgroundColor: Colors.black54,
            ),
          ),
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
                Text(
                  Prefs.autoZap && _sautsAuto >= _maxSautsAuto
                      ? 'Trop de flux morts d affilee.\n'
                          'Le zapping automatique s est arrete.'
                      : 'Ce flux ne repond pas.\n'
                          'Beaucoup de liens publics sont hors ligne.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: _open,
                      child: const Text('Reessayer'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _index < widget.playlist.length - 1
                          ? () => _go(1)
                          : null,
                      child: const Text('Suivante'),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pleinEcran) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _basculerPleinEcran();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Positioned.fill(child: _zoneVideo()),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit,
                      color: Colors.white70, size: 30),
                  onPressed: _basculerPleinEcran,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fav = Prefs.isFavorite(_current);
    final nbSubs = _player.state.tracks.subtitle.length;
    final etat = StreamCheckService.instance.etat(_current);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            if (etat != EtatFlux.inconnu)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.circle,
                  size: 10,
                  color: etat == EtatFlux.enLigne
                      ? const Color(0xFF3FBF5F)
                      : const Color(0xFFC94B4B),
                ),
              ),
            Expanded(
              child: Text(_current.name, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          if (_pipDispo)
            IconButton(
              icon: const Icon(Icons.picture_in_picture_alt),
              tooltip: 'Fenetre flottante',
              onPressed: () async {
                final ok = await PipService.entrer();
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Fenetre flottante refusee. Autorisez-la dans '
                          'les parametres Android de l application.'),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Plein ecran',
            onPressed: _basculerPleinEcran,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: nbSubs > 1,
              label: Text('${nbSubs - 1}'),
              child: const Icon(Icons.closed_caption),
            ),
            tooltip: 'Sous-titres',
            onPressed: _menuSousTitres,
          ),
          IconButton(
            icon: const Icon(Icons.audiotrack),
            tooltip: 'Piste audio',
            onPressed: _menuAudio,
          ),
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
          Expanded(child: _zoneVideo()),
          _bandeauEpg(),
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
