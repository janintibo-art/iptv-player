# Passer à la v5 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v5.zip ~/ && unzip -o iptv_player_v5.zip
```

```bash
cd ~/iptv_player_v5 && cp -r ../iptv_player_v4/.git . && git add -A && git commit -m "Version 5 : EPG XMLTV, Android TV, picture-in-picture"
```

```bash
git push
```

Puis, une fois les deux jobs verts :

```bash
git tag v5.0.0 && git push --tags
```

---

## Prendre en main la v5

### Charger le guide des programmes
Réglages → **Guide des programmes** → cochez une source → **Télécharger le
guide**. Comptez 30 s à 2 min selon la source. Une fois chargé, l'émission en
cours apparaît partout, et l'entrée **Guide des programmes** du menu donne la
grille complète.

Le guide est enregistré sur l'appareil : il survit au redémarrage, et les
émissions terminées sont purgées au lancement.

### Si la grille reste vide
C'est le `tvg-id` qui ne correspond pas entre la playlist et le guide. Deux
pistes, dans cet ordre :
1. Utilisez une playlist iptv-org (Réglages → sources) plutôt que Free-TV :
   elle emploie les mêmes identifiants que les guides iptv-org.
2. Essayez une autre source de guide.

### Fenêtre flottante
Bouton rectangle dans le lecteur, sur Android 8+. Au premier appui Android
peut demander l'autorisation : Paramètres → Applications → Lecteur IPTV →
Picture-in-picture.

### Sur téléviseur
Installez l'APK `arm64-v8a` sur la box ou le téléviseur. L'application
apparaît sur l'écran d'accueil Android TV avec sa bannière. Navigation aux
flèches, OK pour valider, Retour pour remonter.

---

## Dépannage

| Problème | Solution |
|---|---|
| Build échoue sur `xml` | Envoyez-moi la ligne d'erreur |
| Build échoue dans `patch_android.py` | Le script affiche l'étape atteinte, envoyez-la |
| Guide vide après téléchargement | Mismatch de tvg-id, voir plus haut |
| « Echec : 404 » au téléchargement | L'URL du guide a changé, liste à jour sur github.com/iptv-org/epg |
| Téléchargement du guide très lent | Certains guides font plusieurs dizaines de Mo, une seule source suffit |
| Bouton PiP absent | Android 7 ou antérieur, ou Windows : normal |
| PiP ne fait rien | Autorisation Android à donner dans les paramètres de l'app |
| Pas de bannière sur la TV | Désinstallez puis réinstallez l'APK |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |

## Faire le ménage

```bash
rm -rf ~/iptv_player_v3 ~/iptv_player_v3.zip ~/iptv_player_v4_1.zip
```

> Gardez `~/iptv_player_v4` jusqu'à ce que la v5 soit poussée avec succès.
