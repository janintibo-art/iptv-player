# Lecteur IPTV — v6

Lecteur de playlists M3U et de serveurs Xtream Codes, écrit en Flutter.
Android, Android TV et Windows depuis un seul code source.

## Nouveautés de la v6 : le mode API Xtream

Jusqu'ici la connexion à un serveur se contentait de fabriquer une URL M3U.
La v6 implémente l'API `player_api.php` complète.

| | Mode M3U | Mode API |
|---|---|---|
| Chargement | playlist entière d'un bloc | à la demande, par catégorie |
| Films | non | catalogue complet |
| Séries | non | saisons et épisodes |
| Rediffusions | non | oui, si le serveur les garde |
| Guide | URL XMLTV à part | fourni par le serveur |
| Compatibilité | tous les serveurs | serveurs Xtream uniquement |

Les deux modes coexistent : le bouton **Mode M3U simple** reste disponible
pour les serveurs qui n'exposent pas correctement l'API.

### Ce que le mode API apporte

- **Direct** : catégories, chaînes, logos, recherche
- **Films** : catalogue par catégorie, notes, lecture directe
- **Séries** : saisons dépliables, épisodes avec résumés, lecture enchaînée
- **Rediffusions** : icône horloge sur les chaînes archivées, liste des
  émissions passées, lecture par `timeshift.php`
- **Comptes multiples** : plusieurs serveurs enregistrés, bascule immédiate

### Détails d'implémentation

Les libellés du guide serveur arrivent encodés en base64, ils sont décodés à
la volée. Le champ `episodes` de `get_series_info` est tantôt un objet tantôt
un tableau selon les serveurs : les deux formes sont gérées. Les réponses sont
mises en cache mémoire par appel, avec un bouton pour vider le cache.

## Menu

- **Toutes les chaînes** — sources M3U fusionnées, avec recherche
- **Mon serveur** — navigation API : direct, films, séries, rediffusions
- **Flux et serveurs** — adresse directe, connexion Xtream, en-têtes HTTP
- **Guide des programmes** — EPG XMLTV
- **Favoris**, **Historique**, **Catégories**, **Pays**, **Langues**
- **Réglages** — sources, guide, tests de flux, sauvegarde

## Arborescence

```
iptv_player/
├── .github/workflows/build.yml
├── assets/icon/{icon,banner}.png
├── tool/patch_android.py           Permissions, Android TV, pont PiP
├── lib/
│   ├── models/
│   │   ├── channel.dart
│   │   └── xtream.dart             Comptes, catégories, films, séries
│   ├── services/
│   │   ├── xtream_service.dart     API player_api.php complète
│   │   ├── m3u_service.dart
│   │   ├── epg_service.dart
│   │   ├── cache_service.dart
│   │   ├── stream_check_service.dart
│   │   ├── transfert_service.dart
│   │   ├── pip_service.dart
│   │   ├── prefs_service.dart
│   │   └── sources.dart
│   ├── screens/
│   │   ├── xtream_screen.dart      Navigation serveur + catch-up
│   │   ├── network_screen.dart
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

- **v1** lecteur de base — **v2** icône, sources FR, sous-titres
- **v3** cache disque, plein écran, releases — **v4** test des flux, fusion
- **v5** EPG, Android TV, PiP — **v5.2** flux manuels, Xtream M3U
- **v6** API Xtream complète : films, séries, rediffusions

## Reste à faire

- Signature de l'APK avec keystore, pour installer les mises à jour
  par-dessus sans désinstaller

## Avertissement

Cette application n'héberge et ne fournit aucun flux vidéo. Elle lit des
listes de liens publics et se connecte aux serveurs que vous lui indiquez.
La légalité du contenu dépend de votre fournisseur et de votre pays.
