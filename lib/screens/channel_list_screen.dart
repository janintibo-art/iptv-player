import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import '../services/stream_check_service.dart';
import '../widgets/channel_tile.dart';
import 'player_screen.dart';

/// Liste filtrable de chaines, avec test de disponibilite des flux.
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
  final _check = StreamCheckService.instance;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Channel> get _filtered {
    var list = widget.channels;

    if (Prefs.hideOffline) {
      list = list.where((c) => !_check.estHorsLigne(c)).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.group.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  void _play(int indexInFiltered) {
    final list = _filtered;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(playlist: list, startIndex: indexInFiltered),
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _lancerTest() async {
    final list = _filtered;
    if (list.isEmpty) return;

    if (list.length > 400) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Test long'),
          content: Text(
            '${list.length} chaines a tester, cela peut prendre plusieurs '
            'minutes et consommer un peu de data.\n\n'
            'Astuce : filtrez d abord la liste, ou testez une categorie.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Lancer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    await _check.testerListe(list, onProgress: (_, __) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  /// Resume du dernier chargement, avec le detail des sources en echec.
  Widget _bandeauSources() {
    final rapport = M3uService.instance.rapport;
    if (rapport.length < 2 && rapport.every((r) => r.ok)) {
      return const SizedBox.shrink();
    }

    final echecs = rapport.where((r) => !r.ok).length;
    final ok = rapport.length - echecs;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF161B22),
          builder: (_) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Chargement des sources',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ...rapport.map((r) => ListTile(
                      leading: Icon(
                        r.ok ? Icons.check_circle : Icons.error_outline,
                        color: r.ok
                            ? const Color(0xFF3FBF5F)
                            : const Color(0xFFC94B4B),
                      ),
                      title: Text(r.nom,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        r.ok
                            ? '${r.ajoutees} ajoutees sur ${r.trouvees}'
                                '${r.doublons > 0 ? ', ${r.doublons} doublons' : ''}'
                            : r.erreur!,
                        style: TextStyle(
                          fontSize: 12,
                          color: r.ok ? null : const Color(0xFFC94B4B),
                        ),
                      ),
                    )),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Text(
                    'Une source en echec est ignoree, les autres continuent. '
                    'Si une adresse est perimee, retirez-la dans Reglages.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: echecs > 0
                ? const Color(0xFF3A1F22)
                : const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                echecs > 0 ? Icons.warning_amber : Icons.layers,
                size: 16,
                color: echecs > 0 ? const Color(0xFFC94B4B) : Colors.white54,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  echecs > 0
                      ? '$ok source(s) chargee(s), $echecs en echec'
                      : '$ok sources fusionnees',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const Icon(Icons.chevron_right, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barreTest() {
    if (_check.enCours) {
      final pct = _check.total == 0 ? 0.0 : _check.fait / _check.total;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test en cours ${_check.fait} / ${_check.total}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: pct, minHeight: 4),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _check.annuler();
                setState(() {});
              },
              child: const Text('Arreter'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: Row(
        children: [
          Text('${_filtered.length} chaine(s)',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const Spacer(),
          if (_check.nbTestes > 0)
            IconButton(
              icon: Icon(
                Prefs.hideOffline ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 20,
              ),
              tooltip: Prefs.hideOffline
                  ? 'Afficher les chaines hors ligne'
                  : 'Masquer les chaines hors ligne',
              onPressed: () async {
                await Prefs.setHideOffline(!Prefs.hideOffline);
                setState(() {});
              },
            ),
          TextButton.icon(
            icon: const Icon(Icons.network_check, size: 18),
            label: const Text('Tester'),
            onPressed: _lancerTest,
          ),
        ],
      ),
    );
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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        _bandeauSources(),
        _barreTest(),
        const SizedBox(height: 4),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      Prefs.hideOffline
                          ? 'Aucun resultat.\nLe filtre "hors ligne" est actif.'
                          : 'Aucun resultat.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
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
