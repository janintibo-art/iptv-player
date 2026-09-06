# Mettre à jour vers la v2 depuis Termux

Le dépôt `iptv-player` existe déjà et `gh` vous a authentifié. Il suffit de
remplacer les fichiers et de pousser : **3 commandes**.

## Les 3 commandes

```bash
cd ~ && rm -rf iptv_player_old && mv iptv_player iptv_player_old && cp /sdcard/Download/iptv_player_v2.zip ~/ && unzip -o iptv_player_v2.zip
```

```bash
cd ~/iptv_player_v2 && cp -r ../iptv_player_old/.git . && git add -A && git commit -m "Version 2 : icone, sources FR, sous-titres"
```

```bash
git push
```

La ligne 2 récupère le `.git` de l'ancien dossier : le dépôt distant, l'historique
et l'authentification `gh` sont conservés, aucun mot de passe ne sera demandé.

Ensuite : github.com → votre dépôt → onglet **Actions**. Le build repart seul,
comptez 10 à 20 minutes. L'APK et le dossier Windows sont dans **Artifacts**.

---

## Si vous repartez de zéro

Au cas où l'ancien dossier aurait été supprimé :

```bash
cd ~ && cp /sdcard/Download/iptv_player_v2.zip ~/ && unzip -o iptv_player_v2.zip && cd iptv_player_v2
```

```bash
git init -b main && git add -A && git commit -m "Version 2"
```

```bash
git remote add origin https://github.com/janintibo-art/iptv-player.git && git push -u origin main --force
```

> `--force` écrase l'ancienne version sur GitHub. À n'utiliser que si vous
> êtes sûr de vouloir remplacer ce qui s'y trouve.

---

## Modifier ensuite

```bash
cd ~/iptv_player_v2
```

```bash
nano lib/services/sources.dart
```

> `Ctrl + O` puis Entrée pour enregistrer, `Ctrl + X` pour quitter.
> Ce fichier contient la liste des sources : ajoutez-y vos propres URLs.

```bash
git add -A && git commit -m "Nouvelles sources" && git push
```

Chaque `push` relance la compilation.

---

## Dépannage

| Problème | Solution |
|---|---|
| `not a git repository` | Le `.git` n'a pas été copié : refaites la ligne 2 |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
| `Authentication failed` | `gh auth login` puis relancez `git push` |
| `nothing to commit` | Les fichiers sont identiques, rien à envoyer |
| Build échoue sur `flutter_launcher_icons` | Vérifiez que `assets/icon/icon.png` est bien présent et versionné |
| Build échoue ailleurs | Actions → run → cherchez la première ligne rouge `Error:` |
| L'icône n'a pas changé sur Android | Désinstallez l'ancienne APK avant d'installer la nouvelle |
| Aucune chaîne ne se charge | Réglages → choisissez « Free-TV France » |
| Le bouton CC dit « aucune piste » | Normal : ce flux ne transporte pas de sous-titres |

## Vérifier que l'icône est bien versionnée

```bash
git ls-files assets/
```

> Doit afficher `assets/icon/icon.png`. Sinon : `git add -f assets/icon/icon.png`
