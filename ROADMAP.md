> **Statut : ce qui reste à faire, et seulement cela.** Les chantiers de
> la réécriture, dans l'ordre où ils se font. Aucun n'attend plus un
> autre dépôt : ce que stase, card et card-api devaient livrer l'est
> (`CHANGELOG.md`). Un chantier livré quitte ce fichier et devient une
> entrée de `CHANGELOG.md`. Les décisions qui commandent ces chantiers,
> avec leur raison, sont dans `dev/decisions.md`. Les pistes techniques
> écrites ici viennent de l'audit de l'application R : ce sont des
> propositions, que l'implémentation peut remplacer par mieux
> (décision 9). Pas de calendrier : l'ordre suit les dépendances.

# Feuille de route de MAKAHO (mise à jour 2026-11-10)

La réécriture de l'application R Shiny (tag `v1.0.0`) en Flask sur
card-api, publiée en 2.0.0 à la bascule (M10).

## Les objectifs de la 2.0.0

Dits par l'utilisateur le 2026-11-10. Ils orientent chaque chantier ; ce
qui est abandonné l'est en connaissance de cause, dans
`dev/decisions.md` (hors périmètre).

- **Pour qui.** Les opérationnels de l'eau, gestionnaires et
  chercheurs, mais aussi la pédagogie, l'appui aux médias, le grand
  public et les conférences. L'application doit se comprendre sans mode
  d'emploi.
- **Droit au but, le détail à côté.** Modèle : earth.nullschool.net,
  dont MAKAHO est déjà de la famille. La carte occupe l'écran et dit
  tout de suite ce qu'elle a à dire, les commandes restent discrètes ;
  le détail se trouve à côté, au survol, dans des pages séparées, par
  des renvois vers des ressources externes. Plus direct, plus fluide et
  plus agréable que la version R, dans un style qui reste sobre.
- **Rapide et à jour.** La lenteur et l'absence de mise à jour sont deux
  défauts majeurs de la version R. card-api règle la donnée ; à MAKAHO
  de ne pas réintroduire de lenteur (M3, M8).
- **Changer de jeu de stations simplement.** card-api sert n'importe
  quelle station Hub'Eau ; la liste reste une donnée de MAKAHO, le RRSE
  par défaut (M3).
- **L'export de données reste la porte des usages experts** : ce qui
  permet à chacun de refaire les analyses qu'il souhaite. À pousser et
  à vérifier (M6).
- **Exporter la carte proprement**, en PNG, SVG, PDF voire HTML, avec
  ses données, à la manière de MEANDRE (M6).
- **Un peu plus de statistique, courte** : stations en hausse et en
  baisse, médiane des pentes, ce genre de résumé, sans sur-analyse qui
  noierait le message (M2).
- **Les propositions sont bienvenues** pendant l'implémentation, tant
  qu'elles restent sobres et simples.

## M1. Le socle

Un dépôt qui démarre, se déploie, et sait parler au service. Rien
d'affiché encore.

- Reste à l'utilisateur : vérifier la fiche HAL de la version 1.0.0.
- Arborescence sur le patron de MEANDRE (`../../MEANDRE_project/MEANDRE/`) :
  `app.py`, `templates/`, `static/{css,js,resources}`, `Makefile`,
  `compose.yaml`. Déploiement sur celui de card-api : service sur un
  port local, frontal Apache de la VM (décision 8).
- **`card_client.py` : le seul module qui connaisse card-api.** Il
  expose le catalogue, les stations, les séries et les tendances, porte
  la clé et les reprises sur échec, et **relaie les versions**
  (`card_commit`, `stase_commit`, SWHID, `data_fetched_at`,
  `data_fingerprint`) jusqu'à l'interface. C'est la frontière qui rend
  la décision 3 réversible. Il lit `MAKAHO_CARD_API_URL` et
  `MAKAHO_CARD_API_KEY` (`.env.example`) ; l'adresse est publique par
  défaut, locale si MAKAHO tourne sur la VM de card-api. Ce que le
  service lui impose : `dev/decisions.md`.
- Seule donnée locale : **la liste des 228 codes RRSE**, versionnée et
  sourcée (référence HAL), parce que c'est un choix d'étude et non un
  attribut Hub'Eau.
- Hygiène : `README.md` dès qu'il y a quelque chose à décrire,
  `CITATION.cff`, `codemeta.json`, `AUTHORS`, `LICENSE` en
  AGPL-3.0-or-later, code de conduite, CI qui lance tests et linter.
- `scripts/mesure_sampling.py` lit encore le cache de card-api au format
  CSV d'avant sa 0.8.0, devenu Parquet depuis : le faire passer par
  `/v1/chronicles` (décision 2) avant de relancer la mesure.

card-api attend que M1 ait tourné sur son contrat pour passer en 1.0.0
(son `dev/decisions.md`) : ce qui gêne en écrivant `card_client.py` se
signale là-bas, avant cette version.

## M2. La carte

Le coeur, et la première chose qui doit marcher.

- **Le fond de carte, à trancher en premier.** Soit Leaflet et des
  tuiles d'un fournisseur sans jeton (OpenStreetMap, CartoDB), soit une
  carte dessinée en SVG depuis des contours (France, rivières), comme
  MEANDRE. La seconde ne dépend d'aucun fournisseur et s'exporte
  proprement en vectoriel (M6) ; la première donne le zoom et le
  repérage fin. Un seul fond, sobre : les trois thèmes de la version R
  ne reviennent pas. S'il faut un jeton, il passe par l'environnement.
- **Marqueurs en CSS, pas en fichiers.** Un sprite de trois symboles
  (`<symbol>` : triangle haut, triangle bas, rond) défini une fois, un
  `divIcon` par station avec un `<use>`, la couleur en propriété CSS
  personnalisée, **l'état en classe** (`significant-up`,
  `not-significant`, `selected`, `gap`). Mettre la carte à jour devient
  `el.className = ...` sur des noeuds en place. Les 895 SVG, le diff
  d'URL, les trois couches et les `zIndexOffset` disparaissent ensemble.
- Infobulle en `tooltip` lié au marqueur, ce qui tue la couche
  invisible.
- **La barre de couleur avec son histogramme.** Bornes recalculées côté
  MAKAHO à partir des pentes reçues, pour maîtriser sur quel ensemble
  les extrêmes sont pris.
- **Le résumé court** : stations en hausse, en baisse, sans tendance
  significative, médiane des pentes. Rien de plus sans une raison qui
  serve le message.

*Fin :* la carte des tendances de `QA` sur les 228 stations, lue depuis
le service, conforme à
`../../CARD_project/card-api/examples/carte_tendance_QA.png`.

## M3. Le panneau d'analyse

- **Les menus sont construits depuis `/v1/cards` et `/v1/vocabulary`.**
  La facette `phenomenon` donne les quatre régimes aux mêmes effectifs ;
  le regroupement des familles paramétrées se déduit des facettes au
  lieu d'être deviné par expression régulière sur des noms de fichiers.
- **Le jeu de stations** : le RRSE par défaut, et de quoi en changer
  simplement (objectifs). Sa forme est à proposer : listes fournies par
  MAKAHO, liste déposée par l'usager, ou les deux.
- Les cinq modes de sélection : tout, aucun, clic, polygone additif et
  soustractif, recherche par nom.
- Le curseur de période d'analyse, **avec le garde-fou des 30 ans**.
  Changer la période fait recalculer toutes les séries, changer alpha ne
  relance que le test (`dev/decisions.md`, ce que card-api impose).
- Le curseur de départ d'année, `preferred` par défaut. **Pas de mode
  échantillon** (décision 4).
- Le risque alpha, et l'hypothèse `INDE` / `AR1` / `LTP` que le service
  offre et que l'actuel fixe en dur. À exposer ou non : arbitrage
  d'interface.
- **Quand partent les requêtes : à trancher sur mesure.** L'actuel a un
  bouton « Actualiser ». Envoyer au relâchement du curseur, ou après un
  court délai sans mouvement, peut suffire pour les fiches rapides. Pour
  les fiches d'étiage, chaque relâchement lancerait un calcul long, et
  une requête abandonnée par la page continue de calculer côté service.
  Remesurer les coûts depuis la production au moment de M3.
- Une fiche par appel pour la vue complète (`dev/decisions.md`).

## M4. Le graphique par station

Une fonction de tracé paramétrée par (série, unité, couleur, format de
date) rend les trois panneaux. Les 680 lignes de l'actuel sont trois
copies d'un même bloc.

Chronique journalière avec lacunes ombrées (`/v1/chronicles`), série
agrégée, droite de Sen, verdict en clair. `series=true` joint les
séries au diagnostic : un seul appel sert la carte et le graphe.

## M5. L'URL comme état

L'analyse en cours s'écrit dans la barre d'adresse : réseau, variable,
paramètre, départ d'année, période, alpha, station ouverte. Ouvrir
l'URL restitue l'écran.

L'absence la plus coûteuse de l'actuel et la moins chère à corriger.
Pour un outil primé sur la réutilisation, citer un résultat par un lien
n'est pas un confort.

## M6. Les exports

La porte des usages experts, et ce qui sert aux médias et aux
conférences.

- **Les données** : le zip de la version R (`meta.csv`, `metaEX.csv`,
  `dataEX.csv`, `trendEX.csv`, la licence, et **le README de provenance
  à trous**, qui est une réussite de l'actuel), qui gagne le commit et
  le SWHID de `card` et de `stase`. À vérifier : qu'un export se
  recharge et se recalcule ailleurs (R, Python) sans deviner quoi que
  ce soit.
- **La carte** : en PNG, SVG, PDF, voire HTML autonome, composée avec
  sa barre de couleur, son titre et ses paramètres, et accompagnée de
  ses données. Modèle : MEANDRE (`exportSVG` et `exportData` dans
  `../../MEANDRE_project/MEANDRE/static/js/script.js`), où le nom du
  fichier porte les paramètres et l'archive sa notice. Remplace le mode
  capture d'écran de la version R.
- **Écrit par requête, pas dans un répertoire partagé** (audit, 4.9).
- `/v1/extract.csv` et `/v1/trend.csv` portent déjà leur provenance en
  lignes de commentaire : à réutiliser plutôt qu'à refaire.

## M7. L'aide

**L'application s'ouvre sur la carte, jamais sur l'aide.** L'aide vit
à côté : une page séparée, des explications au survol, des renvois
vers des ressources externes (la méthode, le RRSE, card-api). Le contenu
des 16 pages guidées de la version R se reprend là où il sert ; la
visite guidée disparaît.

## M8. Le préchauffage

MAKAHO demande sa grille une fois avant le premier visiteur, pour que
celui-ci ne paie jamais un remplissage à froid : pour la vue complète,
il se compte en dizaines de minutes et part en job.

À redéfinir avant de l'écrire : le pool de card-api ne rafraîchit pas
tout d'un coup une fois par mois. Il renouvelle chaque chronique un peu
avant l'âge accepté, au fil de passes régulières, et `/v1/health`
publie la fin de sa dernière passe et l'échéance de la suivante (bloc
`pool`). « Après chaque rafraîchissement » n'a donc plus de sens tel
quel.

Il ne chauffe que la période par défaut : toute autre période paie son
calcul (cf. M3).

**Ce n'est pas un cache dans MAKAHO** : il ne stocke rien, il est juste
le premier appelant. La décision 2 tient.

## M9. Les fiches PDF, après la 2.0.0

Retirées de la 2.0.0 (`dev/decisions.md`). La version R en sert 232,
pré-générées par une chaîne extérieure et jamais mises à jour. Elles
reviendront produites par une chaîne automatisée, à concevoir une fois
la 2.0.0 en ligne.

## M10. La bascule

- Déploiement sur la VM (décision 8), à une adresse à choisir, à côté
  de l'actuel le temps de comparer écran par écran.
- **Comparaison fonctionnelle** : chaque usage de l'application R
  (section 2 de l'audit) retrouvé, amélioré ou abandonné en
  connaissance de cause, et écrit : ce qu'on gagne, ce qu'on perd.
- **Comparaison numérique** : rejouer les analyses de référence de
  `../../CARD_project/card-api/tests/data/makaho/` et vérifier les mêmes
  verdicts.
- `makaho.sk8.inrae.fr` renvoie vers la nouvelle adresse, si SK8 le
  permet (à demander à son équipe) ; le dépôt de la forge sk8 s'archive.
- Sur GitHub, `main` devient la branche par défaut ; `master` peut
  disparaître, l'histoire R restant au tag `v1.0.0`. Le README renvoie
  vers `v1.0.0` pour la version R Shiny. Version 2.0.0.
- En local, `../MAKAHO/` (l'application R) libère son nom, que ce
  dossier reprend.

## Questions ouvertes

Posées, pas tranchées. Aucune ne bloque le démarrage.

- **Comment mesurer l'usage de MAKAHO correctement.** Question
  légitime, pour plus tard. Elle touche à l'évaluation d'impact, donc
  aux dossiers de financement, et elle se pose mieux une fois qu'on voit
  du trafic réel. Le journal anonymisé de card-api en montrera déjà une
  partie. **Ne pas laisser un compteur d'usage piloter
  l'architecture** : la légitimité vient de ce que le lien soit réel et
  vérifiable, pas du volume de requêtes.
- **Comment MAKAHO sert les chroniques journalières.** Le service les
  donne (`/v1/chronicles`) ; reste à décider si l'appel part du
  navigateur ou du serveur Flask, et s'il y a une mémoire courte côté
  MAKAHO pour la station qu'on vient de fermer et de rouvrir. À trancher
  au moment de M4.
