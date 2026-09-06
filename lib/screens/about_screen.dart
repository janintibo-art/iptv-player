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
        Text('Version 4.0.0', style: TextStyle(color: Colors.white54)),
        SizedBox(height: 24),
        Text('Le menu', style: gras),
        SizedBox(height: 8),
        Text(
          '\u2022 Toutes les chaines : vos sources fusionnees, avec recherche.\n'
          '\u2022 Favoris : vos chaines enregistrees.\n'
          '\u2022 Historique : les 50 dernieres chaines ouvertes.\n'
          '\u2022 Categories, Pays, Langues : parcours par theme.\n'
          '\u2022 Reglages : sources, tests, sauvegarde.',
        ),
        SizedBox(height: 20),
        Text('Plusieurs sources a la fois', style: gras),
        SizedBox(height: 8),
        Text(
          'Dans les Reglages, cochez autant de sources que vous voulez : '
          'elles sont telechargees puis fusionnees en une seule liste. Les '
          'doublons sont retires, y compris quand deux listes proposent la '
          'meme chaine sous un nom legerement different.\n\n'
          'Vous pouvez aussi ajouter votre propre URL, ou ouvrir un fichier '
          '.m3u present sur l appareil.',
        ),
        SizedBox(height: 20),
        Text('Tester les flux', style: gras),
        SizedBox(height: 8),
        Text(
          'Le bouton "Tester" en haut de la liste interroge chaque flux pour '
          'savoir s il repond encore. Une pastille verte ou rouge apparait '
          'alors sur chaque chaine, et le filtre permet de masquer celles qui '
          'sont mortes.\n\n'
          'Le test ne telecharge pas la video, seulement les premiers octets. '
          'Comptez tout de meme quelques minutes sur une grosse liste : '
          'filtrez ou testez categorie par categorie.',
        ),
        SizedBox(height: 20),
        Text('Zapping automatique', style: gras),
        SizedBox(height: 8),
        Text(
          'Si un flux ne donne aucune image au bout de 12 secondes, ou renvoie '
          'une erreur, l application passe seule a la chaine suivante. Elle '
          's arrete apres 15 sauts consecutifs pour ne pas defiler '
          'indefiniment. Un zapping manuel remet ce compteur a zero, et '
          'l option se desactive dans les Reglages.',
        ),
        SizedBox(height: 20),
        Text('Sauvegarder ses favoris', style: gras),
        SizedBox(height: 8),
        Text(
          'L export ecrit un fichier JSON que vous pouvez copier ailleurs ou '
          'garder de cote. L import ajoute son contenu a vos favoris actuels '
          'sans jamais les ecraser : les chaines deja presentes sont ignorees.',
        ),
        SizedBox(height: 20),
        Text('Hors ligne', style: gras),
        SizedBox(height: 8),
        Text(
          'Les playlists sont enregistrees sur l appareil et rechargees apres '
          '12 heures. Sans reseau, la derniere version connue reste '
          'consultable, meme si les flux ne pourront evidemment pas etre lus.',
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
