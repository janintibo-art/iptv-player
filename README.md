# Lecteur IPTV — v5

Lecteur de playlists M3U publiques, écrit en Flutter.
Android, **Android TV** et Windows depuis un seul code source.

## Nouveautés de la v5

### Guide des programmes (EPG)
Chargement de fichiers XMLTV, avec analyse **en flux** : le document n'est
jamais monté en mémoire d'un bloc, et seules les émissions d'une fenêtre de
−3 h / +36 h sont conservées. Gzip détecté et décompressé automatiquement.

L'émission en cours s'affiche sous chaque chaîne dans la liste, en bandeau
sous la vidéo dans le lecteur, et un écran **Guide** donne la grille complète
par chaîne avec séparateurs de jour et surlignage du programme actuel.

Quatre sources préconfigurées (Orange, Programme TV, Télérama, TV Hebdo pour
le Québec) issues du projet iptv-org.

### Android TV
Déclaration `leanback`, écran tactile et téléphonie non requis, bannière
320×180 générée depuis l'icône, et catégorie `LEANBACK_LAUNCHER` pour
apparaître sur l'écran d'accueil des téléviseurs et box.

### Picture-in-picture
Sans plugin tiers : `tool/patch_android.py` réécrit `MainActivity.kt` avec un
`MethodChannel` de quelques lignes qui appelle `enterPictureInPictureMode`.
Un bouton apparaît dans le lecteur sur Android 8+, et reste masqué ailleurs.

## Le compromis du tvg-id

Un EPG ne se rattache aux chaînes que par l'identifiant `tvg-id`. Si la
playlist annonce `tvg-id="FR2"` et que le guide utilise `france2.fr`, la
grille reste vide — ce n'est pas un bug de l'app. Les listes iptv-org et les
guides iptv-org partagent les mêmes identifiants, c'est la combinaison la plus
sûre.

## Arborescence

```
iptv_player/
├── .github/workflows/build.yml
├── assets/icon/icon.png            Icône
├── assets/icon/banner.png          Bannière Android TV
├── tool/patch_android.py           Permissions, Android TV, pont PiP
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/channel.dart
│   ├── services/
│   │   ├── m3u_service.dart            Téléchargement, parsing, fusion
│   │   ├── epg_service.dart            XMLTV en flux
│   │   ├── cache_service.dart          Cache disque
│   │   ├── stream_check_service.dart   Test de disponibilité
│   │   ├── transfert_service.dart      Import / export
│   │   ├── pip_service.dart            Pont picture-in-picture
│   │   ├── prefs_service.dart          Favoris, historique, réglages
│   │   └── sources.dart                Sources préconfigurées
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── channel_list_screen.dart
│   │   ├── epg_screen.dart
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
- **v2** : icône, sources francophones, sous-titres, pistes audio
- **v3** : cache disque, plein écran, releases automatiques, APK par ABI
- **v4** : test des flux, zapping auto, fusion multi-sources, import/export
- **v5** : EPG XMLTV, Android TV, picture-in-picture

## Suite prévue

- **v6** : signature de l'APK avec keystore

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit une liste
de liens publics maintenue par des projets communautaires. La disponibilité et
la légalité de chaque flux dépendent de la chaîne et de votre pays.
