# Lecteur IPTV — v2

Lecteur de playlists M3U publiques, écrit en Flutter.
Un seul code source, deux applications compilées par GitHub Actions :

| Plateforme | Fichier produit |
|---|---|
| Android | `app-release.apk` |
| Windows | dossier `Release/` avec `iptv_player.exe` + DLL |

## Nouveautés de la v2

- **Icône personnalisée** appliquée à l'APK et à l'exe (`assets/icon/icon.png`)
- **8 sources préconfigurées**, dont 6 francophones, choisies d'un seul appui
- Source par défaut : liste **France de Free-TV** (courte, fiable, rapide)
- **Sélecteur de sous-titres** avec activation automatique de la piste française
- **Sélecteur de piste audio** (chaînes multilingues)
- Rechargement automatique quand on change de source

## Sources incluses

| Nom | Contenu |
|---|---|
| Free-TV France | TF1, France 3, BFM TV, TV5 Monde, régionales |
| iptv-org France | toutes les chaînes FR indexées |
| iptv-org langue française | francophone tous pays |
| iptv-org Belgique / Suisse / Canada | par pays |
| Free-TV Monde | international, peu de liens morts |
| iptv-org complet | ~15 000 chaînes |

Toute autre URL `.m3u` / `.m3u8` peut être saisie à la main dans les Réglages.

## Arborescence

```
iptv_player/
├── .github/workflows/build.yml   Compilation APK + EXE + icônes
├── assets/icon/icon.png          Votre icône (1024×1024)
├── tool/patch_android.py         Permission INTERNET
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── models/channel.dart
│   ├── services/
│   │   ├── m3u_service.dart      Téléchargement + parsing M3U
│   │   ├── prefs_service.dart    Favoris, historique, réglages
│   │   └── sources.dart          Sources préconfigurées
│   ├── screens/
│   │   ├── home_screen.dart      Menu latéral
│   │   ├── channel_list_screen.dart
│   │   ├── group_list_screen.dart
│   │   ├── player_screen.dart    Lecteur + sous-titres + audio
│   │   ├── settings_screen.dart
│   │   └── about_screen.dart
│   └── widgets/channel_tile.dart
├── TUTO.md
└── README.md
```

`android/` et `windows/` ne sont pas versionnés : la CI les régénère à chaque
build avec `flutter create --platforms=...`.

## Sous-titres : les limites

Le bouton CC liste les pistes présentes dans le flux et la piste française est
sélectionnée automatiquement si elle existe. En pratique, presque aucune chaîne
française publique n'en a : les sous-titres TNT passent par le télétexte, qui
disparaît lors de la conversion en flux internet.

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit une liste
de liens publics maintenue par des projets communautaires. La disponibilité et
la légalité de chaque flux dépendent de la chaîne et de votre pays.
