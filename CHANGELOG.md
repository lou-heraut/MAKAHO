# Journal des modifications

Évolutions notables de MAKAHO. Format inspiré de [Keep a
Changelog](https://keepachangelog.com/fr/1.1.0/).

**Numérotation.** La 1.0.0 est l'application R Shiny, figée au tag
`v1.0.0` ; elle n'avait pas de journal. La réécriture en Flask sur
card-api sera publiée en 2.0.0 le jour de la bascule (`ROADMAP.md`,
M10) : d'ici là, tout s'inscrit sous « Non publié ». La règle de coupe
qui suivra la 2.0.0 s'écrira avec elle.

Chaque entrée dit ce qui a changé et renvoie au document qui l'explique.

## Non publié

### Ajouté

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
