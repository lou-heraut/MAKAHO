# Journal des modifications

Évolutions notables de MAKAHO. Format inspiré de [Keep a
Changelog](https://keepachangelog.com/fr/1.1.0/).

**Numérotation.** La 1.0.0 est l'application R Shiny, figée au tag
`v1.0.0` ; elle n'avait pas de journal. La réécriture en Flask sur
card-api sera publiée en 2.0.0 le jour de la bascule (`ROADMAP.md`,
M10) : d'ici là, tout s'inscrit sous « Non publié », et le paquet porte
`2.0.0.dev0`. La règle de coupe qui suivra la 2.0.0 s'écrira avec elle.
Le numéro vit dans `pyproject.toml` ; `scripts/set_version.py` le
propage à `CITATION.cff` et `codemeta.json`, et `--etat` donne les faits
avant de couper.

Chaque entrée dit ce qui a changé et renvoie au document qui l'explique.

## Non publié

### Ajouté

- **La mesure de l'audit passe par card-api, et confirme la décision 4
  (2026-11-11).** `scripts/mesure_sampling.py` (`make measure`) prend
  ses tendances à `/v1/trend` et ses chroniques à `/v1/chronicles`, au
  lieu de lire le cache de card-api sur le disque. Relancée : les
  conclusions de la section 5 de l'audit tiennent, à une ou deux
  stations près (`dev/audits/2026-11-11_sampling-measure.md`).
- **Après revue de M1 (2026-11-11)**, le client ne rejoue plus un 502,
  suit l'attente que le service annonce pour un job (`CardClient.wait`,
  nouveau), et dit un refus par son sens (`CardApiError.kind`) plutôt
  que par le code HTTP de card-api, qui ne sort plus de `card_client`.
  Le détail : `dev/plans/2026-11-11_m1-foundation.md`.
- **La licence, l'intégration continue et la citation (2026-11-11).**
  `LICENSE` en AGPL-3.0-or-later (texte identique à celui de la 1.0.0)
  et un en-tête dans chaque module. `.github/workflows/tests.yml` lance
  `make test` et `make lint` sur GitHub, sans rien déployer.
  `CITATION.cff`, `codemeta.json` et `AUTHORS` reprennent les crédits de
  la 1.0.0 ; `CODE_OF_CONDUCT.md` aussi. Le numéro de version a un seul
  endroit (« Numérotation », plus haut), tenu par
  `tests/test_citation.py`.
- **Le squelette de l'application et le client de card-api
  (2026-11-11).** Le paquet `makaho` sous `src/`, fabriqué par
  `create_app`, avec `pyproject.toml` et un `Makefile` (`make` liste
  les commandes). `src/makaho/card_client.py` est le seul module qui
  connaisse card-api (décision 3) : la clé en en-tête, `sampling=
  preferred` envoyé explicitement, les autres défauts laissés au
  service, une demande partie en file rendue comme ticket, des reprises
  limitées aux demandes qui n'ont rien calculé. Tenu par des tests hors
  ligne sur un card-api simulé (`tests/`) ; `make test-live` vérifie la
  simulation contre le service en ligne : passé le jour même, en accès
  public puis avec la clé. M1 dans `ROADMAP.md` dit ce qui reste.
- **La liste des 228 stations du RRSE (2026-11-11)**, seule donnée
  locale de MAKAHO, dans `src/makaho/station_lists/rrse.txt` : extraite
  de la table des stations de l'application R, identique à celle de
  card-api, avec sa source en tête (Giuntoli et al. 2013,
  `hal-00833431`). `makaho.stations` la lit.
- **`.env.example` et `.gitignore` (2026-11-10)**, pour la clé de
  priorité `MAKAHO` de card-api : le jeton vit dans `.env`, que git
  ignore comme tout `.env*` sauf le modèle.
- **Le cadre de la migration (2026-09-18).** L'audit de MAKAHO R Shiny
  et de ce que l'écosystème card couvre déjà
  (`dev/audits/2026-09-18_migration.md`), le plan, et trois consignes
  autoportantes pour stase, card et card-api
  (`dev/plans/2026-09-18_upstream-handover/`). Toutes livrées les
  2026-09-18 et 19, chacune dans son dépôt et son CHANGELOG : stase
  0.6.5, card, card-api 0.5.0 à 0.8.0. `scripts/mesure_sampling.py`
  reproduit la section 5 de l'audit.

### Documentation

- **Le fond de carte et MEANDRE (2026-11-11).** Décision 10 de
  `dev/decisions.md` : Leaflet et un vrai fond de carte, parce que
  MAKAHO montre des observations de terrain qu'il faut pouvoir situer ;
  l'export de cartes (M6) se compose depuis les données, sur ce fond.
  Le fond est choisi après essais à l'écran : le Plan IGN de la
  Géoplateforme en gris clair et l'estompage du relief, sans jeton.
  MEANDRE n'est plus présenté comme un patron de code : c'est l'exemple
  qui a poussé à quitter Shiny, et ses exports restent une référence
  d'usage.
- **Les objectifs de la 2.0.0 (2026-11-10)**, en tête de `ROADMAP.md` :
  pour qui, droit au but sur le modèle d'earth.nullschool.net, export de
  données et de cartes, résumé statistique court. Les chantiers M2, M3,
  M6, M7 et M9 suivent ; ce qui est abandonné est dans
  `dev/decisions.md` (hors périmètre).
- **Dépôt, hébergement et version R figée (2026-11-10).** Décisions 7
  à 9 de `dev/decisions.md` : un seul dépôt `lou-heraut/MAKAHO`, la
  réécriture sur une branche `main` à l'histoire neuve, une VM à la
  place de SK8, et une implémentation qui part de zéro. L'état de
  production de l'application R est publié sur GitHub, figé au tag
  `v1.0.0` et archivé sur Software Heritage. Ce dossier est mis sous
  git sur `main`, poussée sur GitHub ; `master` reste la branche par
  défaut jusqu'à la bascule.
- **Les suites de card-api 0.9.0 et 0.9.1 sont reportées
  (2026-11-10)**, dans `dev/decisions.md` (« Ce que card-api impose au
  client ») : la clé par en-tête seulement, le refus des noms inconnus,
  la période qui entre dans l'extraction, les versions devenues des
  engagements. La raison de la décision 5 est corrigée, et trois
  affirmations de l'audit sont relevées comme démenties.
- **Les documents de développement prennent la structure commune aux
  dépôts de l'écosystème (2026-11-10).** `docs/dev/PLAN.md` se partage
  entre `ROADMAP.md` (les chantiers) et `dev/decisions.md` (les
  décisions, les principes, ce que card-api impose, le hors-périmètre).
  L'audit et les consignes changent de place sans changer de texte ;
  seul leur bandeau de statut dit maintenant leur validité. Les
  documents figés qui citent un ancien chemin (ici, dans card et dans
  card-api) se résolvent ainsi :
  - `docs/dev/PLAN.md` : `ROADMAP.md` et `dev/decisions.md`
  - `docs/dev/AUDIT.md` : `dev/audits/2026-09-18_migration.md`
  - `docs/dev/passation/POUR_STASE.md` :
    `dev/plans/2026-09-18_upstream-handover/stase.md`
  - `docs/dev/passation/POUR_CARD.md` :
    `dev/plans/2026-09-18_upstream-handover/card.md`
  - `docs/dev/passation/POUR_CARD_API.md` :
    `dev/plans/2026-09-18_upstream-handover/card-api.md`

  Campagne commune :
  `../../CARD_project/card/dev/plans/2026-11-06_layout-alignment.md`.
