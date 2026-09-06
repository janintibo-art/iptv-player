# Lecteur IPTV

Lecteur de playlists M3U publiques (projet **iptv-org**), écrit en Flutter.
Un seul code source, deux applications compilées automatiquement par GitHub Actions :

| Plateforme | Fichier produit |
|---|---|
| Android | `app-release.apk` |
| Windows | dossier `Release/` contenant `iptv_player.exe` + DLL |

## Fonctionnalités

- Chargement de la playlist complète iptv-org (~15 000 chaînes)
- Recherche instantanée par nom ou groupe
- Navigation par **catégorie**, **pays** et **langue**
- Favoris et historique enregistrés localement
- Lecture HLS / MPEG-TS via `media_kit` (moteur libmpv)
- Chaîne suivante / précédente depuis le lecteur
- Source M3U personnalisable dans les réglages

## Arborescence

```
iptv_player/
├── .github/workflows/build.yml   Compilation APK + EXE
├── tool/patch_android.py         Ajoute la permission INTERNET
├── pubspec.yaml                  Dépendances
├── lib/
│   ├── main.dart                 Point d'entrée
│   ├── app.dart                  Thème + MaterialApp
│   ├── models/channel.dart       Modèle de chaîne
│   ├── services/
│   │   ├── m3u_service.dart      Téléchargement + parsing M3U
│   │   └── prefs_service.dart    Favoris, historique, réglages
│   ├── screens/
│   │   ├── home_screen.dart      Menu latéral détaillé
│   │   ├── channel_list_screen.dart
│   │   ├── group_list_screen.dart
│   │   ├── player_screen.dart    Lecteur vidéo
│   │   ├── settings_screen.dart
│   │   └── about_screen.dart
│   └── widgets/channel_tile.dart
├── TUTO.md                       Tutoriel Termux + GitHub pas à pas
└── README.md
```

Les dossiers `android/` et `windows/` ne sont pas dans le dépôt : ils sont
régénérés à chaque build par `flutter create --platforms=...`. Cela garde le
dépôt léger et évite des milliers de fichiers à pousser depuis Termux.

## Compiler

Poussez sur la branche `main` : le workflow démarre seul. Les fichiers se
récupèrent dans l'onglet **Actions** → dernier run → section **Artifacts**.

Voir `TUTO.md` pour la procédure complète depuis Termux.

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit une liste
de liens publics maintenue par la communauté iptv-org. La disponibilité et la
légalité de chaque flux dépendent de la chaîne et de votre pays : il vous
appartient de vérifier que vous avez le droit d'accéder aux contenus lus.
