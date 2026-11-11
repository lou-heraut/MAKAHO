> **Statut : terminé le 2026-11-11, sauf le déploiement.** Fichier de
> travail de la fin du chantier M1 de `ROADMAP.md`, mené en autonomie à
> la demande de l'utilisateur : les étapes, ce qui a été décidé en route
> et pourquoi, et les questions posées. Le déploiement attend qu'il y ait
> une carte à montrer ; il reste dans `ROADMAP.md`.

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
5. [x] **Attendre un job** : `CardClient.wait`, pour la mesure, les tests
   live, et plus tard le préchauffage (M8).
6. [x] **`scripts/mesure_sampling.py` par card-api**, puis la relancer et
   comparer aux chiffres de l'audit (section 5).
7. [x] **Revue** par un sous-agent sur l'ensemble de M1, puis corrections.
8. [ ] **Déploiement** : reporté après la carte (M2), quand il y aura
   quelque chose à montrer (2026-11-11) ; avec l'utilisateur, qui donne
   le port et l'adresse sur la VM. Suivi dans `ROADMAP.md`.

## Décisions prises en route

- **Les crédits de la 2.0.0** (réponse de l'utilisateur à la question 1,
  2026-11-11) : les sept personnes de la 1.0.0 restent, avec des rôles
  précisés. Louis Héraut, auteur et mainteneur ; Michel Lang, référent
  scientifique ; Benjamin Renard, Jean-Philippe Vidal, Éric Sauquet,
  Ignazio Giuntoli et Antoine Bard, en encadrement. Benjamin Renard n'a
  pas développé MAKAHO (il est l'auteur de la partie statistique de
  stase) : la 1.0.0 le notait à tort « développeur ». Le financeur reste.

- **La revue du 2026-11-11** (un sous-agent, en lecture seule, sur tout
  M1) n'a rien trouvé de grave et a relevé huit points, tous vérifiés
  puis corrigés :
  - le catalogue n'accepte que les clés du vocabulaire (`low-flows`),
    pas les libellés : l'exemple du client était faux, et un test live
    appelle désormais le catalogue ;
  - un 502 n'est plus rejoué : il arrive aussi quand le service tombe en
    plein calcul ;
  - le reste de l'application lit `CardApiError.kind` (`no_data`,
    `busy`, `unreachable`...) et plus le code HTTP de card-api, qui
    reste dans `card_client` (décision 3) ;
  - `wait` suit le `Retry-After` du service et n'attend plus après son
    dernier relevé ;
  - la mesure vérifie que ses neuf appels ont lu la même donnée
    (empreintes), calcule la moyenne sur 10 jours sur le calendrier
    complet et non sur les lignes (Hub'Eau omet les jours manquants ; le
    défaut était déjà dans la version de l'audit), et un paquet de
    chroniques en échec ne coupe plus la mesure B ;
  - `set_version.py` ne suggère plus `git commit -am`.

## Questions pour l'utilisateur

Aucune en attente. La question des crédits est réglée (décisions,
plus haut).
