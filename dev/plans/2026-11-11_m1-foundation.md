> **Statut : en cours (ouvert le 2026-11-11).** Fichier de travail de la
> fin du chantier M1 de `ROADMAP.md`, mené en autonomie à la demande de
> l'utilisateur : les étapes, ce qui a été décidé en route et pourquoi,
> et les questions à lui poser, notées ici pour ne pas les perdre. Une
> étape faite reste cochée ici et entre dans `CHANGELOG.md`.

# M1, la fin du socle

Fait avant ce plan (commit `7bb5645`) : le squelette Flask, le client de
card-api et ses tests hors ligne et live, la liste du RRSE.

## Les étapes

1. [x] **Licence.** `LICENSE` en AGPL-3.0-or-later, et un en-tête court
   dans chaque module, comme dans card-api.
2. [x] **Intégration continue : tests et lint, rien d'autre.** Elle tourne
   sur une machine jetable de GitHub et ne touche jamais la production ;
   le déploiement reste `make update` sur la VM. card, stase et card-api
   font de même.
3. [x] **Citation.** `CITATION.cff`, `codemeta.json`, `AUTHORS`. Le numéro
   de version vit dans `pyproject.toml` ; `scripts/set_version.py` le
   propage et `tests/test_citation.py` refuse un désaccord, comme dans
   les trois autres dépôts.
4. [x] **Code de conduite**, repris de la version 1.0.0.
5. [ ] **Attendre un job** : `CardClient.wait`, pour la mesure, les tests
   live, et plus tard le préchauffage (M8).
6. [ ] **`scripts/mesure_sampling.py` par card-api**, puis la relancer et
   comparer aux chiffres de l'audit (section 5).
7. [ ] **Revue** par un sous-agent sur l'ensemble de M1, puis corrections.
8. [ ] **Déploiement** : à la fin, avec l'utilisateur (port et adresse
   sur la VM).

## Décisions prises en route

- **Les crédits de la 2.0.0 reprennent ceux de la 1.0.0 à l'identique**
  (`codemeta.json` et `AUTHORS` du tag `v1.0.0`) : les mêmes personnes,
  les mêmes rôles, les mêmes ORCID. Retirer quelqu'un d'une citation ne
  se décide pas seul ; à confirmer (question 1).

## Questions pour l'utilisateur

1. **Les crédits.** La 1.0.0 nomme sept personnes dans son
   `codemeta.json` : Louis Héraut (développement, maintenance), Michel
   Lang (gestion de projet), Benjamin Renard (développement, gestion),
   Jean-Philippe Vidal, Éric Sauquet, Ignazio Giuntoli et Antoine Bard
   (gestion). Son `AUTHORS` n'en nomme que cinq (pas Giuntoli ni Bard).
   Repris tels quels pour la 2.0.0 ; faut-il les garder tous comme
   auteurs du logiciel, et le financeur (« Ministry of Ecological
   Transition France, INRAE ») vaut-il encore ?
