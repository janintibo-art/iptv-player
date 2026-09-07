import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../models/xtream.dart';
import '../services/prefs_service.dart';
import '../services/xtream_service.dart';
import 'player_screen.dart';

/// Navigation dans un serveur Xtream en mode API : les contenus sont
/// charges a la demande, categorie par categorie, au lieu de telecharger
/// toute la playlist d un bloc.
class XtreamBrowserScreen extends StatefulWidget {
  final XtreamAccount compte;

  const XtreamBrowserScreen({super.key, required this.compte});

  @override
  State<XtreamBrowserScreen> createState() => _XtreamBrowserScreenState();
}

class _XtreamBrowserScreenState extends State<XtreamBrowserScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.compte.nom, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Vider le cache et recharger',
            onPressed: () {
              XtreamService.instance.viderCache();
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.live_tv), text: 'Direct'),
            Tab(icon: Icon(Icons.movie), text: 'Films'),
            Tab(icon: Icon(Icons.video_library), text: 'Series'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OngletCategories(
            compte: widget.compte,
            type: TypeContenu.live,
          ),
          _OngletCategories(
            compte: widget.compte,
            type: TypeContenu.films,
          ),
          _OngletCategories(
            compte: widget.compte,
            type: TypeContenu.series,
          ),
        ],
      ),
    );
  }
}

enum TypeContenu { live, films, series }

/// Liste des categories d un type de contenu.
class _OngletCategories extends StatefulWidget {
  final XtreamAccount compte;
  final TypeContenu type;

  const _OngletCategories({required this.compte, required this.type});

  @override
  State<_OngletCategories> createState() => _OngletCategoriesState();
}

class _OngletCategoriesState extends State<_OngletCategories>
    with AutomaticKeepAliveClientMixin {
  late Future<List<XtreamCategorie>> _future;
  final _filtre = TextEditingController();
  String _query = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  @override
  void dispose() {
    _filtre.dispose();
    super.dispose();
  }

  Future<List<XtreamCategorie>> _charger() {
    final x = XtreamService.instance;
    return switch (widget.type) {
      TypeContenu.live => x.categoriesLive(widget.compte),
      TypeContenu.films => x.categoriesFilms(widget.compte),
      TypeContenu.series => x.categoriesSeries(widget.compte),
    };
  }

  IconData get _icone => switch (widget.type) {
        TypeContenu.live => Icons.live_tv,
        TypeContenu.films => Icons.movie,
        TypeContenu.series => Icons.video_library,
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<List<XtreamCategorie>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 44),
                  const SizedBox(height: 12),
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _future = _charger()),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final toutes = snap.data!;
        if (toutes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aucune categorie.\nCe compte ne donne peut-etre pas acces '
                'a ce type de contenu.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final cats = _query.isEmpty
            ? toutes
            : toutes
                .where((c) =>
                    c.nom.toLowerCase().contains(_query.toLowerCase()))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: _filtre,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Filtrer (${toutes.length} categories)',
                  prefixIcon: const Icon(Icons.filter_list),
                  isDense: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: cats.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(_icone),
                  title: Text(cats[i].nom),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _ListeContenu(
                        compte: widget.compte,
                        type: widget.type,
                        categorie: cats[i],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Contenu d une categorie : chaines, films ou series.
class _ListeContenu extends StatefulWidget {
  final XtreamAccount compte;
  final TypeContenu type;
  final XtreamCategorie categorie;

  const _ListeContenu({
    required this.compte,
    required this.type,
    required this.categorie,
  });

  @override
  State<_ListeContenu> createState() => _ListeContenuState();
}

class _ListeContenuState extends State<_ListeContenu> {
  late Future<List<dynamic>> _future;
  final _recherche = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _charger() {
    final x = XtreamService.instance;
    final cat = widget.categorie.id;
    return switch (widget.type) {
      TypeContenu.live => x.live(widget.compte, categorie: cat),
      TypeContenu.films => x.films(widget.compte, categorie: cat),
      TypeContenu.series => x.series(widget.compte, categorie: cat),
    };
  }

  String _nom(dynamic e) => switch (e) {
        XtreamLive l => l.nom,
        XtreamFilm f => f.nom,
        XtreamSerie s => s.nom,
        _ => '',
      };

  String _image(dynamic e) => switch (e) {
        XtreamLive l => l.logo,
        XtreamFilm f => f.affiche,
        XtreamSerie s => s.affiche,
        _ => '',
      };

  void _ouvrir(dynamic e, List<dynamic> tous) {
    final c = widget.compte;

    if (e is XtreamLive) {
      // On construit une playlist avec toutes les chaines de la categorie,
      // pour que les boutons precedent/suivant fonctionnent.
      final chaines = tous
          .whereType<XtreamLive>()
          .map((l) => Channel(
                name: l.nom,
                url: XtreamService.urlLive(c, l.id),
                logo: l.logo,
                group: widget.categorie.nom,
                tvgId: l.epgId,
              ))
          .toList();
      final i = tous.whereType<XtreamLive>().toList().indexOf(e);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            playlist: chaines,
            startIndex: i < 0 ? 0 : i,
          ),
        ),
      );
      return;
    }

    if (e is XtreamFilm) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlayerScreen(
            playlist: [
              Channel(
                name: e.nom,
                url: XtreamService.urlFilm(c, e.id, e.extension),
                logo: e.affiche,
                group: widget.categorie.nom,
              )
            ],
            startIndex: 0,
          ),
        ),
      );
      return;
    }

    if (e is XtreamSerie) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DetailSerie(compte: c, serie: e),
        ),
      );
    }
  }

  void _catchup(XtreamLive l) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CatchupScreen(compte: widget.compte, chaine: l),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categorie.nom)),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final tous = snap.data!;
          final list = _query.isEmpty
              ? tous
              : tous
                  .where((e) =>
                      _nom(e).toLowerCase().contains(_query.toLowerCase()))
                  .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: TextField(
                  controller: _recherche,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Rechercher (${tous.length} elements)',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final e = list[i];
                    final img = _image(e);
                    final live = e is XtreamLive ? e : null;

                    return ListTile(
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: img.isEmpty
                            ? const Icon(Icons.tv)
                            : Image.network(img,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.tv)),
                      ),
                      title: Text(_nom(e),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: e is XtreamFilm && e.note.isNotEmpty
                          ? Text('Note ${e.note}',
                              style: const TextStyle(fontSize: 12))
                          : (live != null && live.archive
                              ? Text('Rediffusion sur ${live.archiveJours} j',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF7FD4E8)))
                              : null),
                      trailing: live != null && live.archive
                          ? IconButton(
                              icon: const Icon(Icons.history),
                              tooltip: 'Revoir',
                              onPressed: () => _catchup(live),
                            )
                          : null,
                      onTap: () => _ouvrir(e, tous),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Saisons et episodes d une serie.
class _DetailSerie extends StatefulWidget {
  final XtreamAccount compte;
  final XtreamSerie serie;

  const _DetailSerie({required this.compte, required this.serie});

  @override
  State<_DetailSerie> createState() => _DetailSerieState();
}

class _DetailSerieState extends State<_DetailSerie> {
  late final Future<Map<int, List<XtreamEpisode>>> _future =
      XtreamService.instance.episodes(widget.compte, widget.serie.id);

  void _lire(XtreamEpisode e, List<XtreamEpisode> saison) {
    final c = widget.compte;
    final playlist = saison
        .map((ep) => Channel(
              name: '${widget.serie.nom} S${ep.saison}E${ep.numero} - ${ep.titre}',
              url: XtreamService.urlEpisode(c, ep.id, ep.extension),
              logo: widget.serie.affiche,
              group: widget.serie.nom,
            ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          playlist: playlist,
          startIndex: saison.indexOf(e),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serie.nom, overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<Map<int, List<XtreamEpisode>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }

          final saisons = snap.data!;
          if (saisons.isEmpty) {
            return const Center(child: Text('Aucun episode disponible.'));
          }

          final cles = saisons.keys.toList()..sort();

          return ListView(
            children: [
              if (widget.serie.resume.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.serie.resume,
                      style: const TextStyle(fontSize: 13)),
                ),
              ...cles.map((s) {
                final eps = saisons[s]!;
                return ExpansionTile(
                  title: Text('Saison $s'),
                  subtitle: Text('${eps.length} episode(s)',
                      style: const TextStyle(fontSize: 12)),
                  children: eps
                      .map((e) => ListTile(
                            dense: true,
                            leading: SizedBox(
                              width: 34,
                              child: Text('E${e.numero}',
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            title: Text(e.titre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            subtitle: e.resume.isEmpty
                                ? null
                                : Text(e.resume,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11)),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () => _lire(e, eps),
                          ))
                      .toList(),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Rediffusions disponibles pour une chaine.
class _CatchupScreen extends StatelessWidget {
  final XtreamAccount compte;
  final XtreamLive chaine;

  const _CatchupScreen({required this.compte, required this.chaine});

  String _jour(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revoir - ${chaine.nom}', overflow: TextOverflow.ellipsis),
      ),
      body: FutureBuilder<List<XtreamEmission>>(
        future: XtreamService.instance.guideChaine(compte, chaine.id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final tout = snap.data ?? [];
          final passees = tout.where((e) => e.passee).toList();

          if (passees.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune emission passee disponible.\n\n'
                  'Le serveur doit fournir un guide pour cette chaine et '
                  'conserver les enregistrements.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: passees.length,
            itemBuilder: (_, i) {
              final e = passees[i];
              return ListTile(
                leading: SizedBox(
                  width: 46,
                  child: Text(_jour(e.debut),
                      style: const TextStyle(fontSize: 12)),
                ),
                title: Text(e.titre,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${e.plage}  -  ${e.dureeMinutes} min',
                    style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.play_circle_outline),
                onTap: () {
                  final url = XtreamService.urlCatchup(
                      compte, chaine.id, e.debut, e.dureeMinutes);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        playlist: [
                          Channel(
                            name: '${chaine.nom} - ${e.titre}',
                            url: url,
                            logo: chaine.logo,
                            group: 'Rediffusion',
                          )
                        ],
                        startIndex: 0,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Liste des comptes enregistres, point d entree du mode API.
class XtreamAccountsScreen extends StatefulWidget {
  const XtreamAccountsScreen({super.key});

  @override
  State<XtreamAccountsScreen> createState() => _XtreamAccountsScreenState();
}

class _XtreamAccountsScreenState extends State<XtreamAccountsScreen> {
  @override
  Widget build(BuildContext context) {
    final comptes = Prefs.comptes;

    if (comptes.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'Aucun serveur enregistre.\n\n'
            'Ajoutez-en un depuis "Flux et serveurs", section '
            'Serveur Xtream Codes.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView(
      children: comptes
          .map((c) => ListTile(
                leading: const Icon(Icons.dns),
                title: Text(c.nom),
                subtitle: Text(c.base, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Retirer ce compte',
                  onPressed: () async {
                    await Prefs.retirerCompte(c.id);
                    XtreamService.instance.viderCache();
                    setState(() {});
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => XtreamBrowserScreen(compte: c),
                  ),
                ),
              ))
          .toList(),
    );
  }
}
