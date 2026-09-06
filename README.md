# Lecteur IPTV — v4

Lecteur de playlists M3U publiques, écrit en Flutter.
Un seul code source, deux applications compilées par GitHub Actions.

## Nouveautés de la v4

### Détection des flux morts
Un bouton **Tester** en haut de la liste interroge chaque flux (premiers
octets seulement, pas la vidéo) et pose une pastille verte ou rouge sur chaque
chaîne. Un filtre masque ensuite les chaînes hors ligne. Les résultats sont
enregistrés sur l'appareil et survivent au redémarrage. 8 tests en parallèle,
annulable à tout moment.

### Zapping automatique
Si un flux ne donne aucune image en 12 secondes ou renvoie une erreur, l'app
passe seule à la suivante. Elle s'arrête après 15 sauts consécutifs pour ne
pas défiler indéfiniment ; un zapping manuel remet le compteur à zéro.

### Fusion multi-sources
Les sources sont désormais des cases à cocher : cochez-en autant que vous
voulez, elles sont téléchargées puis fusionnées. Déduplication sur l'URL **et**
sur le nom normalisé, donc « TF1 (1080p) » et « TF1 HD » ne font qu'une entrée.
Une source injoignable ne fait plus tomber les autres.

### Import / export
- Export des favoris en JSON, import additif qui n'écrase jamais l'existant
- Ouverture d'un fichier `.m3u` local, ajouté comme source à part entière
- Ajout d'URL personnalisées avec un nom

## Arborescence

```
iptv_player/
├── .github/workflows/build.yml
├── assets/icon/icon.png
├── tool/patch_android.py
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/channel.dart
│   ├── services/
│   │   ├── m3u_service.dart            Téléchargement, parsing, fusion
│   │   ├── cache_service.dart          Cache disque
│   │   ├── stream_check_service.dart   Test de disponibilité
│   │   ├── transfert_service.dart      Import / export
│   │   ├── prefs_service.dart          Favoris, historique, réglages
│   │   └── sources.dart                Sources préconfigurées
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── channel_list_screen.dart
│   │   ├── group_list_screen.dart
│   │   ├── player_screen.dart
│   │   ├── settings_screen.dart
│   │   └── about_screen.dart
│   └── widgets/channel_tile.dart
├── TUTO.md
└── README.md
```

## Historique

- **v1** : lecteur de base, menu, favoris
- **v2** : icône, 8 sources dont 6 francophones, sous-titres, pistes audio
- **v3** : cache disque, plein écran, releases automatiques, APK par ABI
- **v4** : test des flux, zapping auto, fusion multi-sources, import/export

## Suite prévue

- **v5** : guide des programmes (EPG XMLTV), Android TV, picture-in-picture
- **v6** : signature de l'APK avec keystore

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit une liste
de liens publics maintenue par des projets communautaires. La disponibilité et
la légalité de chaque flux dépendent de la chaîne et de votre pays.
