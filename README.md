# Lecteur IPTV — v3

Lecteur de playlists M3U publiques, écrit en Flutter.
Un seul code source, deux applications compilées par GitHub Actions.

## Nouveautés de la v3

- **Cache disque** : les playlists sont enregistrées sur l'appareil.
  Démarrage instantané, liste consultable sans réseau, rechargement
  automatique après 12 h. En cas de panne réseau, l'app se rabat sur la
  dernière version connue au lieu d'afficher une erreur.
- **Plein écran** en paysage avec masquage des barres système.
- **Écran maintenu allumé** pendant toute la lecture.
- **Releases GitHub automatiques** : un tag `v3.0.0` publie une page de
  téléchargement avec l'APK et l'archive Windows. Plus besoin d'aller
  fouiller dans Artifacts, et les fichiers n'expirent pas.
- **APK par architecture** (`--split-per-abi`) : environ 3× plus léger.
- Réglages : date de dernière mise à jour et taille du cache.

## Rappel v2

Icône personnalisée, 8 sources préconfigurées dont 6 francophones,
sélecteur de sous-titres avec activation automatique de la piste française,
sélecteur de piste audio.

## Publier une version téléchargeable

```bash
git tag v3.0.0 && git push --tags
```

La page Release apparaît sous l'onglet **Releases** du dépôt, avec :

| Fichier | Pour qui |
|---|---|
| `app-arm64-v8a-release.apk` | tous les téléphones récents |
| `app-armeabi-v7a-release.apk` | vieux téléphones 32 bits |
| `app-x86_64-release.apk` | émulateurs, Chromebooks |
| `iptv-player-windows.zip` | Windows, décompresser entièrement |

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
│   │   ├── m3u_service.dart      Téléchargement, parsing, repli hors ligne
│   │   ├── cache_service.dart    Cache disque
│   │   ├── prefs_service.dart    Favoris, historique, réglages
│   │   └── sources.dart          Sources préconfigurées
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

## Suite prévue

- **v4** : test de disponibilité des flux et zapping automatique, fusion de
  plusieurs sources avec déduplication, import/export des favoris,
  ouverture d'un `.m3u` local
- **v5** : guide des programmes (EPG XMLTV), Android TV, picture-in-picture
- **v6** : signature de l'APK avec keystore

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit une liste
de liens publics maintenue par des projets communautaires. La disponibilité et
la légalité de chaque flux dépendent de la chaîne et de votre pays.
