import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const gras = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text('Lecteur IPTV', style: TextStyle(fontSize: 22)),
        SizedBox(height: 4),
        Text('Version 1.0.0', style: TextStyle(color: Colors.white54)),
        SizedBox(height: 24),
        Text('Comment ca marche', style: gras),
        SizedBox(height: 8),
        Text(
          'L application telecharge une playlist M3U publique et affiche '
          'les chaines qu elle contient. Touchez une chaine pour lancer '
          'la lecture, l etoile pour la mettre en favori.',
        ),
        SizedBox(height: 20),
        Text('Le menu', style: gras),
        SizedBox(height: 8),
        Text(
          '• Toutes les chaines : la playlist complete, avec recherche.\n'
          '• Favoris : vos chaines enregistrees, hors ligne.\n'
          '• Historique : les 50 dernieres chaines ouvertes.\n'
          '• Categories : news, sport, musique, documentaires...\n'
          '• Pays : chaines regroupees par pays de diffusion.\n'
          '• Langues : chaines regroupees par langue.\n'
          '• Reglages : source M3U, logos, cache.',
        ),
        SizedBox(height: 20),
        Text('Pourquoi certaines chaines ne marchent pas ?', style: gras),
        SizedBox(height: 8),
        Text(
          'Les liens proviennent d une liste communautaire. Beaucoup de flux '
          'tombent hors ligne, changent d adresse ou sont bloques selon le '
          'pays (geo-blocage). Ce n est pas un bug de l application : '
          'passez simplement a une autre chaine.',
        ),
        SizedBox(height: 20),
        Text('Sources et licence', style: gras),
        SizedBox(height: 8),
        Text(
          'Playlists : projet open source iptv-org. L application n heberge '
          'aucun flux video et ne fournit aucun contenu : elle se contente '
          'de lire une liste de liens publics.',
        ),
        SizedBox(height: 20),
        Text('Avertissement legal', style: gras),
        SizedBox(height: 8),
        Text(
          'La disponibilite et la legalite d un flux dependent de la chaine '
          'et de votre pays de residence. Il vous appartient de verifier que '
          'vous avez le droit d acceder aux contenus que vous lisez.',
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
