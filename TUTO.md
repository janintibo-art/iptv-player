# Passer à la v4 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v4.zip ~/ && unzip -o iptv_player_v4.zip
```

```bash
cd ~/iptv_player_v4 && cp -r ../iptv_player_v3/.git . && git add -A && git commit -m "Version 4 : test des flux, zapping auto, multi-sources, import export"
```

```bash
git push
```

Puis, une fois les deux jobs verts :

```bash
git tag v4.0.0 && git push --tags
```

---

## Prendre en main la v4

### Tester les flux
Liste des chaînes → bouton **Tester** en haut à droite. Au-delà de 400 chaînes
une confirmation s'affiche : le test est long. Le plus efficace est de
filtrer d'abord (recherche, ou une catégorie), puis de tester ce sous-ensemble.

Une fois le test fait, l'icône entonnoir apparaît à côté : elle masque les
chaînes hors ligne.

### Cocher plusieurs sources
Réglages → **Sources actives**. Ce sont des cases à cocher, plus des boutons
radio. Par exemple « Free-TV France » + « iptv-org France » donne une liste
large sans les doublons.

Il faut toujours au moins une source active : décocher la dernière est refusé.

### Importer un fichier .m3u
Réglages → **Ouvrir un fichier .m3u**. Le fichier est copié dans l'app et
devient une source cochable, utilisable hors ligne. Attention : vider le cache
supprime aussi ces fichiers importés, il faudra les réimporter.

### Sauvegarder les favoris
Réglages → **Exporter** produit un JSON. Sur Android, si la boîte de dialogue
système n'apparaît pas, le fichier est écrit dans le dossier de l'application
et le chemin complet s'affiche dans le message.

---

## Dépannage

| Problème | Solution |
|---|---|
| Build échoue sur `file_picker` | Envoyez-moi la ligne d'erreur |
| Le test reste bloqué à 0 | Pas de réseau, ou tous les flux en timeout : attendez 8 s par lot |
| Tout ressort « hors ligne » | Certains réseaux mobiles bloquent les ports non standard : testez en Wi-Fi |
| Le zapping saute trop de chaînes | Réglages → désactivez **Zapping automatique** |
| L'import de favoris ne fait rien | Le fichier doit être un JSON exporté par l'app |
| Fichier .m3u importé introuvable | Le cache a été vidé : réimportez-le |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
| Release non créée | Settings → Actions → Workflow permissions → Read and write |

## Faire le ménage

```bash
rm -rf ~/iptv_player_v2 ~/iptv_player_v2.zip ~/iptv_player_v3.zip
```

> Gardez `~/iptv_player_v3` jusqu'à ce que la v4 soit poussée avec succès.
