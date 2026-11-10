# CLAUDE.md (MAKAHO)

Réécriture de [MAKAHO](https://makaho.sk8.inrae.fr/) sans Shiny : Flask,
HTML/CSS/JS écrits à la main, Leaflet, et
[card-api](../../CARD_project/card-api/) comme seule source des chiffres.

**Le dossier et le dépôt.** Ce dossier s'appelle `MAKAHO-next` pour ne
pas se confondre avec `../MAKAHO/`, l'application R en production ; il
prendra le nom `MAKAHO` à la bascule. Le dépôt est le même pour les
deux : `lou-heraut/MAKAHO`, l'application R figée au tag `v1.0.0` sur
`master`, la réécriture sur `main`, une histoire neuve sans ancêtre
commun avec le R (décision 7). Chaque dossier reste sur sa branche.
Ce dossier ne suit que `main`, sans les tags (réglage de `origin`) :
ne pas y récupérer `master` ni `v1.0.0`, qui y ramèneraient le R.

Où en est le travail : `ROADMAP.md`. Ce qui a été fait : `CHANGELOG.md`.

## Où lire quoi

Un rôle par fichier, chacun l'annonce dans un bandeau de statut en tête ;
ne jamais recopier d'un fichier à l'autre, renvoyer. Les chemins cités
dans les documents partent de la racine du dépôt.

- `ROADMAP.md` : les objectifs de la 2.0.0, les chantiers M1 à M10 dans
  l'ordre, et les questions ouvertes.
- `CHANGELOG.md` : ce qui a été fait, et la doctrine des numéros en
  tête. Il porte aussi la correspondance des anciens chemins
  (`docs/dev/...`) cités par les documents figés.
- `dev/decisions.md` : les décisions de la migration avec leur raison,
  les principes de conduite, **ce que card-api impose au client**, le
  hors-périmètre, et ce que l'audit a de faux.
- `dev/audits/2026-09-18_migration.md` : photographie datée, close, de
  MAKAHO R Shiny et de ce que l'écosystème couvrait. Le point de départ,
  jamais tenu à jour.
- `dev/plans/2026-09-18_upstream-handover/` : les trois consignes
  données à stase, card et card-api. Livrées, figées.
- `scripts/mesure_sampling.py` : reproduit les chiffres de la section 5
  de l'audit, qui justifient la suppression d'une fonction de
  l'interface. À relancer plutôt qu'à croire.
- Principes documentaires communs aux dépôts de l'écosystème :
  `../../CARD_project/card/dev/decisions.md`.
- `README.md` : à écrire quand il y aura un logiciel à décrire. Un
  README qui décrit un logiciel qui n'existe pas est un mensonge daté.

## L'écosystème, et qui fait quoi

```
  Hub'Eau            debits journaliers observes (QmnJ), Licence Ouverte
     |
  card               les fiches : ce qu'EST une variable (YAML)
  stase              le moteur : agregation, Mann-Kendall, Sen
     |
  card-api           la facade web : catalogue, extraction, tendance, jobs
     |               card-api.riverly.inrae.fr
  MAKAHO             la carte, les curseurs, les graphes  <-- ce depot
```

card, stase et card-api sont maintenus par l'utilisateur, dans
`../../CARD_project/{card,card-api}` et `../../EXstat_project/stase`.
card et stase sont les ports Python de CARD (dépôt CARD-R) et d'EXstat,
les paquets R de la version 1.0.0. **Lire le `CLAUDE.md` de card-api
avant de toucher au client** : il porte les règles du service et les
arbitrages qui expliquent sa forme.

Patron technique de référence, en production et maintenu par
l'utilisateur : `../../MEANDRE_project/MEANDRE/`
(`meandre.explore2.inrae.fr`), Flask mince, `static/` en trois dossiers,
pas d'étape de construction.

L'application R est dans `../MAKAHO/`. **Ne pas la modifier** : elle est
en production. **Ne pas lire son code pour écrire le nouveau** : elle
est une référence fonctionnelle et un point de comparaison, jamais un
modèle ; on compare avec l'application en ligne (décision 9). Elle a
deux historiques git : `git` y vise GitHub,
`gitsk8` (alias de `git.sh`, à sourcer) la forge sk8 d'où SK8 déploie.
Y committer, taguer ou pousser revient à l'utilisateur.

## Les décisions à ne pas rouvrir

Détaillées avec leur raison dans `dev/decisions.md`. En bref :

1. **On sort de Shiny pour son modèle de concurrence**, pas parce que le
   calcul est lourd.
2. **MAKAHO reste sans état** et prend tout son contenu scientifique de
   card-api.
3. **Repli connu** si la mesure déçoit : un instantané des séries dans
   MAKAHO, test refait par stase. D'où : **un seul module doit savoir
   d'où viennent les séries.**
4. **Le mode échantillon du curseur est supprimé**, le départ d'année
   est conservé, `preferred` par défaut.
5. **La durée de vie du cache de card-api passe au mois**, et ce n'est
   pas MAKAHO qui le demande.
6. **Une chronique se télécharge entière, jamais par morceaux
   recollés.**
7. **Un seul dépôt, `lou-heraut/MAKAHO`** : le R figé au tag `v1.0.0`,
   la réécriture sur `main`, histoire neuve. Le nom reste, la version
   passe à 2.0.0.
8. **MAKAHO quitte SK8 pour une VM**, peut-être celle de card-api.
9. **La réécriture part de zéro.** L'application R dit ce qu'il faut
   permettre, pas comment le faire ; les pistes techniques de
   `ROADMAP.md` sont des propositions.

## Ce qui ne se déduit pas du code

- **Le RRSE n'est pas un attribut Hub'Eau.** Les 228 stations sont un
  choix d'étude publié (`hal.science/hal-00833431`). La liste est une
  donnée de MAKAHO, à versionner et à sourcer. Vérifié le 2026-09-18 :
  identique à la ligne près entre `meta_RRSE.fst` du dépôt R et
  `examples/stations_rrse.txt` de card-api.
- **Les codes de stations sont déjà post-refonte Hydro.** Aucun travail
  de correspondance vers Hub'Eau.
- **Le protocole MAKAHO, c'est `sampling=preferred`.** L'application
  n'utilise pas l'échantillonnage adaptatif des fiches : elle impose à
  chaque fiche la fenêtre fixe qu'elle déclare, ce qui rend les stations
  comparables. Documenté et testé dans `tests/test_makaho.py` de card-api.
  **Il se passe explicitement** : sans `sampling`, une fiche à fenêtre
  adaptative ne rend pas la même série (mesure dans
  `dev/plans/2026-09-18_cache.md` de card-api). Ses autres défauts
  (`mk=AR1`, `level=0.1`, `start=1968`) sont ceux du service.
- **La parité numérique est déjà démontrée**, à 1e-12 sur `p` et sur
  `a`, par ce même test. Ce n'est pas un risque du chantier.
- **Aller chercher coûte des dizaines à des centaines de fois calculer.**
  C'est le fait qui commande l'architecture. Les mesures datées sont
  dans card-api (B5 de `dev/plans/2026-09-19_cache-followup.md`) ; celle
  de l'audit était fausse.
- **Le jeton de tuiles Jawg du dépôt R est dans un historique public**
  (`settings.R:60`). À révoquer, indépendamment de ce chantier. Ne
  jamais le reprendre ici.
- **Prix Science Ouverte 2024**, catégorie « Créer les conditions de la
  réutilisation ». Ce qui est primé est la chaîne « données ouvertes,
  méthode explicite, résultat réutilisable », pas le code R. Une
  décision qui raccourcit cette chaîne est bonne ; une décision qui
  l'allonge doit se justifier.

## Règles de travail

- **Pas de fenêtre de choix à cocher.** Une décision à prendre s'expose
  en prose dans la réponse, avec une recommandation et ce qui distingue
  les options, et se discute dans le fil. Les tableaux, schémas et
  maquettes ASCII sont en revanche bienvenus.
- **Pas de tiret cadratin** dans la prose (docs, messages, commentaires,
  réponses) : reformuler.
- **Aucun décompte ni plafond écrit en clair dans une description
  d'API**, ni recopié d'un dépôt à l'autre. La phrase reste, la valeur
  bouge, et le texte ment sans que rien ne rougisse. Les valeurs se
  lisent où elles vivent : `/v1` bloc `limits`, `versions()`. Règle
  importée de card-api, où elle a été payée deux fois.
- **Une session par dépôt.** Ce qui manque à card-api, card ou stase se
  fait depuis une session ouverte dans ce dépôt, qui charge son
  `CLAUDE.md` et ses règles ; jamais d'ici par chemin relatif.
- **Un chantier à la fois**, et à chaque fois : ouvrir les docs de dev
  du dépôt concerné, faire, ajouter l'entrée `## Non publié` de son
  CHANGELOG, retirer le chantier de son registre. Le travail doit se
  lire dans le dépôt qui le porte, pas seulement ici.
- **Rien n'est fait tant qu'un test ne le tient pas.**
- **Pas de `git add -A` ni de `git add .`** : stager nommément les
  fichiers que l'on a soi-même modifiés.
- **Ne jamais signaler un fichier non suivi.** Il appartient à
  l'utilisateur.
- **Les fichiers de notes de l'utilisateur ne s'ouvrent pas**
  (`note.txt` et assimilés) : ni lecture, ni résumé, ni « au passage
  j'ai vu que ».
