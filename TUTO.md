# Passer à la v6 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v6.zip ~/ && unzip -o iptv_player_v6.zip
```

```bash
cd ~/iptv_player_v5 && git add -A && git commit -m "Version 6 : API Xtream complete, films, series, rediffusions"
```

```bash
git push
```

> Le zip garde le dossier `iptv_player_v5` pour ne pas perdre le `.git`.
> Le nom du dossier ne suit plus la version, c'est volontaire.

Puis :

```bash
git tag v6.0.0 && git push --tags
```

---

## Connecter votre serveur en mode API

Menu → **Flux et serveurs** → section **Serveur Xtream Codes**.

Remplissez adresse, port, identifiant, mot de passe, puis
**Connecter en mode API**.

L'app vérifie d'abord les identifiants et affiche la date d'expiration. Rien
n'est téléchargé : le compte est simplement enregistré.

Ensuite, menu → **Mon serveur** → touchez le compte. Trois onglets :

| Onglet | Contenu |
|---|---|
| Direct | catégories de chaînes, puis les chaînes |
| Films | catégories, puis le catalogue |
| Séries | catégories, puis saisons dépliables |

Chaque écran a un champ de filtre, indispensable au-delà de quelques
centaines d'entrées.

## Revoir une émission

Dans l'onglet Direct, les chaînes archivées portent une **icône horloge** et
la mention du nombre de jours conservés. Touchez l'icône : la liste des
émissions passées apparaît, avec date, horaire et durée. Touchez-en une pour
la revoir depuis le début.

Si la liste est vide, c'est que le serveur ne fournit pas de guide pour cette
chaîne, même s'il annonce l'archivage.

## Mode M3U : quand l'utiliser

Le bouton **Mode M3U simple** reste utile dans deux cas :

- le serveur n'expose pas l'API correctement, ou renvoie « Réponse
  inattendue » alors que la playlist fonctionne dans VLC
- vous voulez fusionner les chaînes du serveur avec vos autres sources dans
  un seul écran « Toutes les chaînes »

Les deux modes peuvent coexister sur le même serveur.

## Plusieurs serveurs

Chaque connexion en mode API ajoute un compte. Menu → **Mon serveur** les
liste tous, et l'icône corbeille en retire un.

---

## Dépannage

| Problème | Solution |
|---|---|
| « Réponse inattendue » | Le serveur n'est pas Xtream, ou l'API est désactivée : utilisez le mode M3U |
| « Identifiants refusés » | Login ou mot de passe faux |
| « Compte expiré » | Abonnement terminé |
| Onglet Films ou Séries vide | Votre offre ne les inclut pas |
| Une série n'affiche aucun épisode | Le serveur renvoie un format non standard, dites-le moi |
| Rediffusion qui ne démarre pas | Le serveur n'a pas d'enregistrement pour ce créneau |
| Lecture qui coupe après quelques secondes | Nombre de connexions simultanées dépassé |
| Liste très lente à s'ouvrir | Catégorie volumineuse : utilisez le filtre |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |

## Mots de passe

Les identifiants sont stockés en clair sur l'appareil : le protocole Xtream
les met de toute façon dans chaque URL de flux. N'exportez pas vos réglages
et ne partagez pas de captures montrant une URL complète.
