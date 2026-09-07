# Passer à la v5.2 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v5_2.zip ~/ && unzip -o iptv_player_v5_2.zip
```

```bash
cd ~/iptv_player_v5 && git add -A && git commit -m "Version 5.2 : flux manuels, Xtream Codes, en-tetes HTTP"
```

```bash
git push
```

> Le zip contient le même dossier `iptv_player_v5`, il se décompresse
> par-dessus sans toucher au `.git`.

Puis :

```bash
git tag v5.2.0 && git push --tags
```

---

## Se connecter à votre serveur

Menu → **Flux et serveurs** → section **Serveur Xtream Codes**.

| Champ | Exemple |
|---|---|
| Adresse | `monserveur.tv` ou `http://192.168.1.50` |
| Port | `8080` (laissez vide si l'adresse le contient déjà) |
| Identifiant | votre login |
| Mot de passe | votre mot de passe |

**Se connecter** interroge `player_api.php`. En cas de succès, l'app affiche
la date d'expiration et le nombre de connexions autorisées, puis ajoute
automatiquement deux choses : la playlist dans les sources actives, et le
guide XMLTV du serveur dans la section EPG.

Ouvrez ensuite **Toutes les chaînes**.

### Messages d'erreur

| Message | Cause |
|---|---|
| Identifiants refusés | Login ou mot de passe faux |
| Compte expiré le ... | Abonnement terminé |
| Réponse inattendue | Ce n'est pas un serveur Xtream Codes |
| Serveur injoignable | Adresse ou port faux, serveur hors ligne, ou pare-feu |

## Ouvrir un flux isolé

Même écran, section **Ouvrir un flux**. Collez l'adresse, appuyez sur
**Lire**. Deux boutons à ne pas confondre :

- **Lire** traite l'adresse comme un flux vidéo et l'ouvre directement
- **Ajouter comme playlist** traite l'adresse comme un fichier `.m3u` à
  analyser, et l'ajoute aux sources

Exemples qui fonctionnent :

```
http://192.168.1.20:8080/live.m3u8
rtsp://192.168.1.30:554/stream1
udp://@239.0.0.1:1234
```

## Erreur 403 sur un flux

Certains serveurs vérifient le `User-Agent` ou le `Referer`. Dépliez
**En-têtes HTTP** avant de lire, et renseignez la valeur attendue. Pour
l'appliquer à tous les flux, utilisez la section **En-têtes par défaut** en
bas de l'écran.

Une valeur qui débloque beaucoup de cas :

```
Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36
```

## Note sur les mots de passe

Le protocole Xtream Codes met les identifiants en clair dans l'URL de la
playlist, c'est ainsi qu'il est conçu. Ils sont donc stockés tels quels sur
l'appareil. N'exportez pas et ne partagez pas vos réglages si vous avez
enregistré un serveur privé.

---

## Dépannage

| Problème | Solution |
|---|---|
| Le flux `udp://` ne marche pas sur mobile | Le multicast passe mal en Wi-Fi, testez en filaire sur la box |
| `rtsp://` saccadé | Essayez d'ajouter `?tcp` selon la caméra |
| Serveur local injoignable | Vérifiez que le téléphone est sur le même réseau |
| Playlist Xtream vide | Le serveur répond mais n'expose rien : vérifiez le type de compte |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
