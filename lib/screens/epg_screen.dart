import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../services/epg_service.dart';
import 'player_screen.dart';

/// Grille des programmes : chaines avec l emission en cours,
/// puis le detail d une chaine.
class EpgScreen extends StatefulWidget {
  final List<Channel> channels;

  const EpgScreen({super.key, required this.channels});

  @override
  State<EpgScreen> createState() => _EpgScreenState();
}

class _EpgScreenState extends State<EpgScreen> {
  final _epg = EpgService.instance;
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Chaines de la playlist qui ont bien une grille associee.
  List<Channel> get _avecGuide {
    final list = widget.channels
        .where((c) => c.tvgId.isNotEmpty && _epg.grille(c.tvgId).isNotEmpty)
        .toList();
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _ouvrirGrille(Channel c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GrilleChaine(channel: c, playlist: widget.channels),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_epg.disponible) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_note, size: 48),
              SizedBox(height: 16),
              Text(
                'Aucun guide charge.\n\n'
                'Rendez-vous dans Reglages, section "Guide des programmes", '
                'pour choisir une ou plusieurs sources et lancer le '
                'telechargement.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final list = _avecGuide;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Rechercher une chaine...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${list.length} chaine(s) avec grille, '
                '${_epg.nbProgrammes} emissions',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Aucune chaine de vos sources ne correspond au guide '
                      'charge.\n\nC est le probleme classique du tvg-id : '
                      'la playlist et le guide doivent utiliser le meme '
                      'identifiant. Essayez une autre source de guide.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final c = list[i];
                    final p = _epg.maintenant(c.tvgId);
                    final s = _epg.suivante(c.tvgId);

                    return ListTile(
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: c.logo.isEmpty
                            ? const Icon(Icons.tv)
                            : Image.network(c.logo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.tv)),
                      ),
                      title: Text(c.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p == null
                                ? 'Pas d emission en cours'
                                : '${p.plage}  ${p.titre}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7FD4E8)),
                          ),
                          if (p != null) ...[
                            const SizedBox(height: 3),
                            LinearProgressIndicator(
                              value: p.progression,
                              minHeight: 2,
                              backgroundColor: Colors.white12,
                            ),
                          ],
                          if (s != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(
                                'Ensuite : ${s.titre}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white38),
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _ouvrirGrille(c),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Grille detaillee d une chaine.
class _GrilleChaine extends StatelessWidget {
  final Channel channel;
  final List<Channel> playlist;

  const _GrilleChaine({required this.channel, required this.playlist});

  String _jour(DateTime d) {
    const jours = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche'
    ];
    return '${jours[d.weekday - 1]} ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final grille = EpgService.instance.grille(channel.tvgId);
    String? dernierJour;

    return Scaffold(
      appBar: AppBar(
        title: Text(channel.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Regarder',
            onPressed: () {
              final i = playlist.indexWhere((c) => c.url == channel.url);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    playlist: playlist,
                    startIndex: i < 0 ? 0 : i,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: grille.length,
        itemBuilder: (_, i) {
          final p = grille[i];
          final jour = _jour(p.debut);
          final nouveauJour = jour != dernierJour;
          dernierJour = jour;

          final tuile = Container(
            color: p.enCours ? const Color(0xFF17323A) : null,
            child: ListTile(
              dense: true,
              leading: SizedBox(
                width: 46,
                child: Text(
                  p.plage.split(' - ').first,
                  style: TextStyle(
                    fontSize: 13,
                    color: p.enCours ? const Color(0xFF7FD4E8) : Colors.white70,
                    fontWeight: p.enCours ? FontWeight.bold : null,
                  ),
                ),
              ),
              title: Text(p.titre,
                  style: TextStyle(
                      fontWeight: p.enCours ? FontWeight.bold : null)),
              subtitle: p.description.isEmpty
                  ? null
                  : Text(p.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
            ),
          );

          if (!nouveauJour) return tuile;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: const Color(0xFF161B22),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(jour.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1,
                        color: Colors.white54)),
              ),
              tuile,
            ],
          );
        },
      ),
    );
  }
}
