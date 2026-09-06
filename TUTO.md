# Tutoriel complet : du ZIP à l'APK et à l'EXE

Objectif : envoyer ce projet sur GitHub depuis Termux, puis laisser GitHub
compiler l'APK Android et l'exécutable Windows.

---

## Étape 0 — Créer le jeton GitHub (une seule fois)

GitHub n'accepte plus le mot de passe en HTTPS : il faut un **jeton**.

1. Sur github.com → photo de profil → **Settings**
2. Tout en bas → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)** → **Generate new token (classic)**
4. Note : `termux`. Expiration : 90 jours (ou plus).
5. Cochez la case **repo** (toute la section).
6. **Generate token**, puis **copiez le jeton** (`ghp_xxxxxxxx`).
   Il ne sera plus jamais réaffiché : collez-le dans une note.

## Étape 0 bis — Créer le dépôt vide

1. github.com → bouton **+** en haut à droite → **New repository**
2. Nom : `iptv-player`
3. Visibilité : Public (ou Private, ça marche aussi)
4. **Ne cochez rien** (pas de README, pas de .gitignore, pas de licence)
5. **Create repository**

---

## Étape 1 — Préparer Termux

Une commande à la fois, validez avec Entrée et attendez la fin.

```bash
pkg update -y && pkg upgrade -y
```

```bash
pkg install -y git unzip nano python
```

```bash
termux-setup-storage
```

> Une fenêtre Android demande l'accès aux fichiers : acceptez.

## Étape 2 — Votre identité Git

Remplacez par vos vraies valeurs.

```bash
git config --global user.name "VotrePseudoGitHub"
```

```bash
git config --global user.email "votre@email.com"
```

```bash
git config --global credential.helper store
```

> `credential.helper store` mémorise le jeton : vous ne le taperez qu'une fois.

## Étape 3 — Décompresser le projet

Le ZIP est dans les téléchargements. **Important : on le copie dans le dossier
personnel de Termux.** Git fonctionne mal directement sur `/sdcard`.

```bash
cp /sdcard/Download/iptv_player.zip ~/
```

```bash
cd ~ && unzip -o iptv_player.zip
```

```bash
cd iptv_player && ls -la
```

> Vous devez voir `lib`, `pubspec.yaml`, `README.md`, `tool`.
> Si le dossier `.github` n'apparaît pas, c'est normal : `ls -a` le montre.

## Étape 4 — Créer le dépôt local et envoyer

```bash
git init -b main
```

```bash
git add .
```

```bash
git commit -m "Premiere version du lecteur IPTV"
```

Remplacez `VOTREPSEUDO` par votre nom d'utilisateur GitHub :

```bash
git remote add origin https://github.com/VOTREPSEUDO/iptv-player.git
```

```bash
git push -u origin main
```

> **Username** : votre pseudo GitHub
> **Password** : collez le **jeton** `ghp_...` (rien ne s'affiche, c'est normal)

## Étape 5 — Récupérer l'APK et l'EXE

1. Ouvrez votre dépôt sur github.com
2. Onglet **Actions**
3. Le workflow « Build APK et EXE » démarre tout seul (10 à 20 min la première fois)
4. Cliquez sur le run → en bas, section **Artifacts** :
   - `iptv-player-android-apk` → contient `app-release.apk`
   - `iptv-player-windows` → dossier avec `iptv_player.exe` et ses DLL

> Les artifacts se téléchargent en `.zip`. Pour Windows, gardez **tout le
> dossier** décompressé : l'exe ne démarre pas sans les DLL à côté.

### Installer l'APK

Téléchargez-le sur le téléphone, ouvrez-le, autorisez
« Installer des applications inconnues » pour votre navigateur.

---

## Modifier le projet plus tard

```bash
cd ~/iptv_player
```

```bash
nano lib/screens/home_screen.dart
```

> `Ctrl + O` puis Entrée pour enregistrer, `Ctrl + X` pour quitter.

```bash
git add . && git commit -m "Modification" && git push
```

Chaque `push` relance automatiquement la compilation.

---

## Dépannage

| Problème | Solution |
|---|---|
| `Permission denied` sur /sdcard | Travaillez dans `~/iptv_player`, pas dans /sdcard |
| `Authentication failed` | Le jeton est faux ou expiré : refaites l'étape 0 |
| `remote origin already exists` | `git remote set-url origin https://github.com/PSEUDO/iptv-player.git` |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
| Build Android échoue | Ouvrez le log dans Actions, cherchez la ligne rouge `Error:` |
| Le build Windows échoue sur media_kit | Vérifiez que `media_kit_libs_video` est bien dans pubspec.yaml |
| L'app se lance mais aucune chaîne | Pas de réseau, ou le patch de permission n'a pas tourné |
| Une chaîne ne démarre pas | Normal : beaucoup de flux publics sont hors ligne, essayez-en une autre |

## Effacer le jeton mémorisé

```bash
rm ~/.git-credentials
```
