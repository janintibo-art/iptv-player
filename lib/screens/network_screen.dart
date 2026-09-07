import 'package:flutter/material.dart';

import '../models/channel.dart';
import '../models/xtream.dart';
import '../services/m3u_service.dart';
import '../services/prefs_service.dart';
import '../services/sources.dart';
import '../services/xtream_service.dart';
import 'player_screen.dart';
import 'xtream_screen.dart';

/// Ouverture manuelle de flux et connexion a un serveur, dans l esprit du
/// "Ouvrir un flux reseau" de VLC.
class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  // Flux direct
  final _url = TextEditingController();
  final _nom = TextEditingController();
  final _ua = TextEditingController();
  final _ref = TextEditingController();
  bool _optionsAvancees = false;

  // Serveur Xtream
  final _hote = TextEditingController();
  final _port = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _motDePasseVisible = false;
  bool _testEnCours = false;
  InfoServeur? _info;

  @override
  void dispose() {
    for (final c in [_url, _nom, _ua, _ref, _hote, _port, _user, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Channel? _construireChaine() {
    final u = _url.text.trim();
    if (u.isEmpty) {
      _snack('Entrez une adresse de flux.');
      return null;
    }
    if (!u.contains('://')) {
      _snack('Adresse incomplete : il manque http://, rtsp://, udp://...');
      return null;
    }
    return Channel(
      name: _nom.text.trim().isEmpty ? u.split('/').last : _nom.text.trim(),
      url: u,
      group: 'Flux manuel',
      userAgent: _ua.text.trim(),
      referer: _ref.text.trim(),
    );
  }

  Future<void> _lire({bool enregistrer = true}) async {
    final c = _construireChaine();
    if (c == null) return;
    if (enregistrer) await Prefs.ajouterFluxDirect(c);
    if (!mounted) return;
    setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(playlist: [c], startIndex: 0),
      ),
    );
  }

  XtreamAccount _compteSaisi() {
    final base = XtreamService.normaliserBase(_hote.text, port: _port.text);
    return XtreamAccount(
      nom: base.isEmpty ? 'Serveur' : '${Uri.parse(base).host} (${_user.text.trim()})',
      base: base,
      user: _user.text.trim(),
      pass: _pass.text,
    );
  }

  /// Verifie les identifiants, puis enregistre le compte selon le mode.
  Future<void> _connecterServeur({required bool modeApi}) async {
    setState(() {
      _testEnCours = true;
      _info = null;
    });

    final compte = _compteSaisi();
    final info = await XtreamService.instance.tester(compte);

    if (!mounted) return;
    setState(() {
      _testEnCours = false;
      _info = info;
    });

    if (!info.ok) return;

    if (modeApi) {
      // Mode API : rien n est telecharge, tout se charge a la demande.
      await Prefs.ajouterCompte(compte);
      if (!mounted) return;
      setState(() {});
      _snack('Serveur enregistre. Ouvrez "Mon serveur" dans le menu.');
      return;
    }

    // Mode M3U : on ajoute la playlist et le guide aux sources classiques.
    final playlist = XtreamService.urlPlaylist(compte);
    final epg = XtreamService.urlEpg(compte);

    await Prefs.addCustomSource(SourcePreset(
      compte.nom,
      playlist,
      'Serveur Xtream Codes'
      '${info.expiration == null ? '' : ', valide jusqu au '
          '${info.expiration!.day}/${info.expiration!.month}/${info.expiration!.year}'}.',
    ));
    await Prefs.toggleSource(playlist);

    final guides = Prefs.epgUrls;
    if (!guides.contains(epg)) {
      guides.add(epg);
      await Prefs.setEpgUrls(guides);
    }

    M3uService.instance.clearMemory();
    if (!mounted) return;
    setState(() {});
    _snack('Playlist ajoutee aux sources. Ouvrez "Toutes les chaines".');
  }

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );

  @override
  Widget build(BuildContext context) {
    final recents = Prefs.fluxDirects;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _titre('Ouvrir un flux'),
        const Text(
          'Collez une adresse et lisez-la directement, sans passer par une '
          'playlist. Les protocoles http, https, rtsp, rtmp, udp et les '
          'fichiers locaux sont acceptes.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Adresse du flux',
            hintText: 'http://192.168.1.20:8080/live.m3u8',
            isDense: true,
          ),
        ),
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
        InkWell(
          onTap: () => setState(() => _optionsAvancees = !_optionsAvancees),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_optionsAvancees
                    ? Icons.expand_less
                    : Icons.expand_more),
                const SizedBox(width: 6),
                const Text('En-tetes HTTP'),
              ],
            ),
          ),
        ),
        if (_optionsAvancees) ...[
          const Text(
            'Certains serveurs refusent les flux sans User-Agent ou Referer '
            'attendu, et renvoient une erreur 403.',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ua,
            autocorrect: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'User-Agent',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ref,
            autocorrect: false,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Referer',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lire'),
              onPressed: _lire,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Ajouter comme playlist'),
              onPressed: () async {
                final u = _url.text.trim();
                if (!u.contains('://')) {
                  _snack('Adresse incomplete.');
                  return;
                }
                await Prefs.addCustomSource(SourcePreset(
                  _nom.text.trim().isEmpty ? u : _nom.text.trim(),
                  u,
                  'Playlist ajoutee manuellement.',
                ));
                await Prefs.toggleSource(u);
                M3uService.instance.clearMemory();
                _snack('Ajoutee aux sources actives.');
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Lire ouvre le flux tel quel. Ajouter comme playlist traite '
          'l adresse comme un fichier .m3u a analyser.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),

        if (recents.isNotEmpty) ...[
          const Divider(height: 40),
          _titre('Flux recents'),
          ...recents.map((c) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link),
                title: Text(c.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(c.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    await Prefs.retirerFluxDirect(c.url);
                    setState(() {});
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(playlist: [c], startIndex: 0),
                  ),
                ),
              )),
        ],

        const Divider(height: 40),
        _titre('Serveur Xtream Codes'),
        const Text(
          'Le protocole des panels IPTV. Entrez l adresse, l identifiant et '
          'le mot de passe, puis choisissez le mode de connexion.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _hote,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Adresse',
                  hintText: 'monserveur.tv',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Port',
                  hintText: '8080',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _user,
          autocorrect: false,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Identifiant',
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pass,
          obscureText: !_motDePasseVisible,
          autocorrect: false,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'Mot de passe',
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(_motDePasseVisible
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => _motDePasseVisible = !_motDePasseVisible),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_testEnCours)
          const Row(
            children: [
              SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Connexion au serveur...', style: TextStyle(fontSize: 12)),
            ],
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.api),
                label: const Text('Connecter en mode API'),
                onPressed: () => _connecterServeur(modeApi: true),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.playlist_add),
                label: const Text('Mode M3U simple'),
                onPressed: () => _connecterServeur(modeApi: false),
              ),
            ],
          ),
        const SizedBox(height: 10),
        const Text(
          'Mode API : films, series, catch-up et guide charges a la demande, '
          'depuis l entree "Mon serveur" du menu. C est le mode recommande.\n'
          'Mode M3U : la playlist entiere est telechargee et fusionnee avec '
          'vos autres sources. Plus lent, mais compatible avec tout serveur.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        if (_info != null) ...[
          const SizedBox(height: 12),
          Card(
            color: _info!.ok
                ? const Color(0xFF17323A)
                : const Color(0xFF3A1F22),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_info!.ok ? Icons.check_circle : Icons.error_outline,
                          size: 18,
                          color: _info!.ok
                              ? const Color(0xFF3FBF5F)
                              : const Color(0xFFC94B4B)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_info!.message)),
                    ],
                  ),
                  if (_info!.ok) ...[
                    const SizedBox(height: 8),
                    if (_info!.expiration != null)
                      Text(
                        'Abonnement valide jusqu au '
                        '${_info!.expiration!.day}/${_info!.expiration!.month}/'
                        '${_info!.expiration!.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    if (_info!.connexionsMax != null)
                      Text('${_info!.connexionsMax} connexion(s) simultanee(s)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white54)),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Text(
          'Le mot de passe est stocke sur l appareil, en clair dans '
          'l adresse de la playlist comme le veut ce protocole. Ne '
          'partagez pas un export de reglages contenant un serveur prive.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),

        const Divider(height: 40),
        _titre('En-tetes par defaut'),
        const Text(
          'Appliques a tous les flux qui n ont pas les leurs. A ne remplir '
          'que si votre serveur les exige.',
          style: TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 10),
        _ChampPref(
          label: 'User-Agent par defaut',
          valeur: Prefs.userAgent,
          onSave: (v) async {
            await Prefs.setUserAgent(v);
            _snack('User-Agent enregistre.');
          },
        ),
        const SizedBox(height: 8),
        _ChampPref(
          label: 'Referer par defaut',
          valeur: Prefs.referer,
          onSave: (v) async {
            await Prefs.setReferer(v);
            _snack('Referer enregistre.');
          },
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

/// Champ texte avec bouton d enregistrement.
class _ChampPref extends StatefulWidget {
  final String label;
  final String valeur;
  final Future<void> Function(String) onSave;

  const _ChampPref({
    required this.label,
    required this.valeur,
    required this.onSave,
  });

  @override
  State<_ChampPref> createState() => _ChampPrefState();
}

class _ChampPrefState extends State<_ChampPref> {
  late final TextEditingController _c =
      TextEditingController(text: widget.valeur);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      autocorrect: false,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.label,
        isDense: true,
        suffixIcon: IconButton(
          icon: const Icon(Icons.save, size: 20),
          onPressed: () => widget.onSave(_c.text.trim()),
        ),
      ),
    );
  }
}
