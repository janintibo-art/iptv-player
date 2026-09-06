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
        Text('Version 2.0.0', style: TextStyle(color: Colors.white54)),
        SizedBox(height: 24),
        Text('Comment ca marche', style: gras),
        SizedBox(height: 8),
        Text(
          'L application telecharge une playlist M3U publique et affiche les '
          'chaines qu elle contient. Touchez une chaine pour lancer la '
          'lecture, l etoile pour la mettre en favori.',
        ),
        SizedBox(height: 20),
        Text('Le menu', style: gras),
        SizedBox(height: 8),
        Text(
          '• Toutes les chaines : la source active, avec recherche.\n'
          '• Favoris : vos chaines enregistrees.\n'
          '• Historique : les 50 dernieres chaines ouvertes.\n'
          '• Categories : news, sport, musique, documentaires...\n'
          '• Pays : chaines regroupees par pays de diffusion.\n'
          '• Langues : chaines regroupees par langue.\n'
          '• Reglages : choix de la source, sous-titres, logos, cache.',
        ),
        SizedBox(height: 20),
        Text('Choisir une bonne source', style: gras),
        SizedBox(height: 8),
        Text(
          'Par defaut l application utilise la liste France du projet '
          'Free-TV : peu de chaines, mais elles fonctionnent. Les listes '
          'iptv-org sont beaucoup plus fournies, au prix de nombreux liens '
          'morts. Changez de source dans les Reglages.',
        ),
        SizedBox(height: 20),
        Text('Sous-titres : ce qu il faut savoir', style: gras),
        SizedBox(height: 8),
        Text(
          'Le bouton CC du lecteur liste les pistes de sous-titres presentes '
          'dans le flux, et l application active automatiquement la piste '
          'francaise quand elle existe.\n\n'
          'En pratique, la quasi-totalite des chaines francaises n en '
          'proposent aucune : les sous-titres de la TNT sont diffuses en '
          'teletexte, et ce canal disparait lors de la reconversion en flux '
          'internet. Un sous-titrage genere automatiquement en direct '
          'demanderait une reconnaissance vocale permanente, irrealiste sur '
          'telephone.',
        ),
        SizedBox(height: 20),
        Text('Pourquoi certaines chaines ne marchent pas', style: gras),
        SizedBox(height: 8),
        Text(
          'Les liens proviennent de listes communautaires. Beaucoup de flux '
          'tombent hors ligne, changent d adresse ou sont bloques selon le '
          'pays. Ce n est pas un bug : passez a une autre chaine.',
        ),
        SizedBox(height: 20),
        Text('Avertissement legal', style: gras),
        SizedBox(height: 8),
        Text(
          'Cette application n heberge et ne fournit aucun flux video : elle '
          'lit une liste de liens publics. La disponibilite et la legalite de '
          'chaque flux dependent de la chaine et de votre pays de residence. '
          'Il vous appartient de verifier que vous avez le droit d acceder '
          'aux contenus lus.',
        ),
        SizedBox(height: 30),
      ],
    );
  }
}
