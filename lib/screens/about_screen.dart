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
        Text('Version 5.0.0', style: TextStyle(color: Colors.white54)),
        SizedBox(height: 24),
        Text('Guide des programmes', style: gras),
        SizedBox(height: 8),
        Text(
          'Reglages, section "Guide des programmes" : cochez une ou plusieurs '
          'sources XMLTV puis lancez le telechargement. L emission en cours '
          'apparait alors sous chaque chaine, dans le lecteur, et dans '
          'l ecran Guide qui donne la grille complete.\n\n'
          'Si la grille reste vide, c est presque toujours le tvg-id : la '
          'playlist et le guide doivent employer le meme identifiant de '
          'chaine. Changez de source de guide, ou de source de playlist.',
        ),
        SizedBox(height: 20),
        Text('Fenetre flottante', style: gras),
        SizedBox(height: 8),
        Text(
          'Sur Android 8 et plus, le bouton en forme de rectangle reduit la '
          'video dans une petite fenetre par-dessus les autres applications. '
          'Si rien ne se passe, l autorisation se donne dans les parametres '
          'Android de l application, rubrique "Picture-in-picture".',
        ),
        SizedBox(height: 20),
        Text('Sur televiseur', style: gras),
        SizedBox(height: 8),
        Text(
          'L application se declare compatible Android TV : elle apparait sur '
          'l ecran d accueil des televiseurs et box, avec sa banniere, et '
          'fonctionne sans ecran tactile. La navigation se fait a la '
          'telecommande, les fleches deplacent la selection et OK valide.',
        ),
        SizedBox(height: 20),
        Text('Le menu', style: gras),
        SizedBox(height: 8),
        Text(
          '\u2022 Toutes les chaines : vos sources fusionnees, avec recherche.\n'
          '\u2022 Guide des programmes : ce qui passe maintenant.\n'
          '\u2022 Favoris et Historique.\n'
          '\u2022 Categories, Pays, Langues.\n'
          '\u2022 Reglages : sources, guide, tests, sauvegarde.',
        ),
        SizedBox(height: 20),
        Text('Tester les flux', style: gras),
        SizedBox(height: 8),
        Text(
          'Le bouton "Tester" interroge chaque flux pour savoir s il repond. '
          'Une pastille verte ou rouge apparait sur chaque chaine, et le '
          'filtre masque celles qui sont mortes. Le test ne telecharge pas la '
          'video, seulement les premiers octets.',
        ),
        SizedBox(height: 20),
        Text('Zapping automatique', style: gras),
        SizedBox(height: 8),
        Text(
          'Sans image au bout de 12 secondes, ou en cas d erreur, '
          'l application passe seule a la chaine suivante. Elle s arrete '
          'apres 15 sauts consecutifs.',
        ),
        SizedBox(height: 20),
        Text('Plusieurs sources a la fois', style: gras),
        SizedBox(height: 8),
        Text(
          'Cochez autant de sources que vous voulez : elles sont fusionnees '
          'et les doublons retires, y compris quand deux listes proposent la '
          'meme chaine sous un nom legerement different. Vous pouvez ajouter '
          'votre propre URL ou ouvrir un fichier .m3u de l appareil.',
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
