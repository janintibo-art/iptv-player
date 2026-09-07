# Passer à la v5.1 depuis Termux

## Les 3 commandes

```bash
cd ~ && cp /sdcard/Download/iptv_player_v5_1.zip ~/ && unzip -o iptv_player_v5_1.zip
```

```bash
cd ~/iptv_player_v5 && git add -A && git commit -m "Version 5.1 : sources FAST officielles et leurs guides"
```

```bash
git push
```

> Le zip contient le même dossier `iptv_player_v5`, il se décompresse
> par-dessus l'existant sans toucher au `.git`.

Puis, une fois les deux jobs verts :

```bash
git tag v5.1.0 && git push --tags
```

---

## La combinaison à essayer en premier

Réglages → **Sources actives** → cochez **Pluto TV France**.
Réglages → **Guide des programmes** → cochez **Pluto TV France (recommandé)**
→ **Télécharger le guide**.

C'est le seul couple où playlist et EPG partagent les mêmes identifiants : la
grille doit se remplir immédiatement. Si ça marche, ajoutez Samsung TV Plus
France par-dessus, les deux fusionnent sans doublon.

Ensuite seulement, ajoutez les listes iptv-org si vous voulez du volume — en
sachant qu'une bonne part de leurs liens sont morts, d'où le bouton **Tester**.

## Toutes les sources disponibles

| Source | Type | Fiabilité |
|---|---|---|
| Pluto TV France | FAST officiel | très bonne |
| Samsung TV Plus France | FAST officiel | très bonne |
| Pluto TV Canada | FAST officiel | très bonne |
| Samsung TV Plus Suisse | FAST officiel | très bonne |
| Free-TV France | communautaire filtré | bonne |
| iptv-org France / Belgique / Suisse / Canada | communautaire | moyenne |
| iptv-org langue française | communautaire | moyenne |
| Free-TV Monde | communautaire filtré | bonne |
| iptv-org complet | communautaire | faible, ~15 000 chaînes |

Pour d'autres pays, ajoutez une URL personnalisée sur le motif
`https://iptv-org.github.io/iptv/countries/XX.m3u` — par exemple `sn`, `ci`,
`cm`, `ml`, `cd`, `bf`, `ga`, `tg`, `bj`, `mg` pour l'Afrique francophone,
ou `subdivisions/ca-qc.m3u` pour le Québec seul.

---

## Dépannage

| Problème | Solution |
|---|---|
| Pluto TV ne charge pas | Le service n'est pas distribué partout, essayez Samsung TV Plus |
| Grille toujours vide | Vérifiez que source et guide portent le même nom |
| Coupures pendant les publicités | Normal sur les FAST, le flux se recale seul |
| `Updates were rejected` | `git pull --rebase origin main` puis `git push` |
| Build échoue | Envoyez-moi la ligne d'erreur du log Actions |
