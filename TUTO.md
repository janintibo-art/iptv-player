# Passer à la v3 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v3.zip ~/ && unzip -o iptv_player_v3.zip
```

```bash
cd ~/iptv_player_v3 && cp -r ../iptv_player_v2/.git . && git add -A && git commit -m "Version 3 : cache disque, plein ecran, releases auto"
```

```bash
git push
```

> La ligne 2 récupère le `.git` du dossier v2 : dépôt distant, historique et
> authentification `gh` conservés, aucun mot de passe demandé.
> Si votre dossier précédent porte un autre nom, remplacez `../iptv_player_v2`
> par le bon chemin.

## Publier une vraie page de téléchargement

Nouveau en v3 : au lieu d'aller chercher les fichiers dans Artifacts, un tag
crée une **Release** permanente.

```bash
cd ~/iptv_player_v3 && git tag v3.0.0 && git push --tags
```

Après le build (10-20 min), allez dans l'onglet **Releases** du dépôt. Vous y
trouverez les APK et l'archive Windows, téléchargeables directement, sans
expiration.

**Quel APK prendre ?** `app-arm64-v8a-release.apk` pour tout téléphone acheté
après 2016. Les autres ne servent qu'aux vieux appareils 32 bits et aux
émulateurs.

Pour les versions suivantes, incrémentez le tag :

```bash
git tag v3.1.0 && git push --tags
```

## Modifier ensuite

```bash
cd ~/iptv_player_v3 && nano lib/services/sources.dart
```

> `Ctrl + O` puis Entrée pour enregistrer, `Ctrl + X` pour quitter.

```bash
git add -A && git commit -m "Nouvelles sources" && git push
```

## Faire le ménage dans Termux

Les anciennes versions prennent de la place :

```bash
rm -rf ~/iptv_player_old ~/iptv_player.zip ~/iptv_player_v2.zip
```

> Gardez `~/iptv_player_v2` jusqu'à ce que la v3 soit poussée avec succès.

---

## Dépannage

| Problème | Solution |
|---|---|
| `not a git repository` | Le `.git` n'a pas été copié : refaites la ligne 2 |
| `cp: cannot stat '../iptv_player_v2/.git'` | Vérifiez le nom avec `ls ~` |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
| `Authentication failed` | `gh auth login` puis relancez |
| Le tag ne déclenche rien | Vérifiez qu'il commence par `v` : `v3.0.0`, pas `3.0.0` |
| Release vide ou absente | Actions → job → l'étape « Publier dans la Release » doit être verte |
| `Resource not accessible by integration` | Dépôt → Settings → Actions → General → Workflow permissions → cochez **Read and write** |
| Tag posé par erreur | `git tag -d v3.0.0 && git push --delete origin v3.0.0` |
| Build échoue sur `wakelock_plus` | Envoyez-moi la ligne d'erreur, on le retire du Windows |
| L'app plante au démarrage | Réglages → vider le cache, ou réinstallez |
| L'icône n'a pas changé | Désinstallez l'ancienne APK avant d'installer |

## Vérifier la permission de publication

Une seule fois, avant le premier tag :
dépôt sur github.com → **Settings** → **Actions** → **General** →
section *Workflow permissions* → **Read and write permissions** → **Save**.

Sans ça, la création de Release échoue avec une erreur 403.
