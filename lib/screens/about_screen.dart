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
        Text('Version 3.0.0', style: TextStyle(color: Colors.white54)),
        SizedBox(height: 24),
        Text('Comment ca marche', style: gras),
        SizedBox(height: 8),
        Text(
          'L application telecharge une playlist M3U publique, la garde en '
          'memoire sur l appareil, et affiche les chaines qu elle contient. '
          'Touchez une chaine pour lancer la lecture, l etoile pour la mettre '
          'en favori.',
        ),
        SizedBox(height: 20),
        Text('Le menu', style: gras),
        SizedBox(height: 8),
        Text(
          '\u2022 Toutes les chaines : la source active, avec recherche.\n'
          '\u2022 Favoris : vos chaines enregistrees.\n'
          '\u2022 Historique : les 50 dernieres chaines ouvertes.\n'
          '\u2022 Categories : news, sport, musique, documentaires...\n'
          '\u2022 Pays : chaines regroupees par pays de diffusion.\n'
          '\u2022 Langues : chaines regroupees par langue.\n'
          '\u2022 Reglages : source, sous-titres, logos, cache.',
        ),
        SizedBox(height: 20),
        Text('Le lecteur', style: gras),
        SizedBox(height: 8),
        Text(
          'Plein ecran en paysage, selection des sous-titres et des pistes '
          'audio, chaine suivante et precedente. L ecran reste allume tant '
          'que la lecture est ouverte.',
        ),
        SizedBox(height: 20),
        Text('Hors ligne', style: gras),
        SizedBox(height: 8),
        Text(
          'Les playlists sont enregistrees sur l appareil et rechargees '
          'automatiquement apres 12 heures. Sans reseau, la derniere version '
          'connue reste consultable, meme si les flux eux-memes ne pourront '
          'evidemment pas etre lus.',
        ),
        SizedBox(height: 20),
        Text('Sous-titres : ce qu il faut savoir', style: gras),
        SizedBox(height: 8),
        Text(
          'Le bouton CC liste les pistes presentes dans le flux et la piste '
          'francaise est activee automatiquement quand elle existe. En '
          'pratique, la quasi-totalite des chaines francaises n en proposent '
          'aucune : les sous-titres de la TNT sont diffuses en teletexte, et '
          'ce canal disparait lors de la reconversion en flux internet.',
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
