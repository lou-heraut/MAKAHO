> **Statut : repères en vigueur.** Les choix de MAKAHO qui ne se
> déduisent pas du code, chacun avec sa date et sa raison : on les suit
> tant qu'ils servent, et leur raison dit quand l'un d'eux ne tient
> plus. Les rouvrir demande un fait nouveau, pas un avis. Ce qui reste à
> faire est dans `ROADMAP.md`, les consignes de travail dans `CLAUDE.md`.
> Créé le 2026-11-10 à partir du `PLAN.md` du 2026-09-18, qui portait
> aussi les chantiers. Les chemins partent de la racine du dépôt.

# Décisions de MAKAHO

## Les décisions de la migration

Arrêtées entre le 2026-09-18 et le 2026-11-11.

1. **On sort de Shiny pour son modèle de concurrence**, pas parce que le
   calcul est lourd. Une unité d'isolation par personne connectée n'est
   pas tenable pour un service public. Cf. l'audit, 4.2.
2. **MAKAHO passe par card-api pour tout son contenu scientifique**,
   et reste **sans état** : il ne garde ni chronique, ni série agrégée.
   Raison : élégance, science ouverte, et un usage de référence qui
   légitime le service.
3. **Repli connu si la mesure déçoit** : un instantané des séries dans
   MAKAHO, rafraîchi périodiquement, avec le test refait localement par
   stase. C'est pourquoi **un seul module de MAKAHO doit savoir d'où
   viennent les séries** (`card_client.py`).
4. **Le mode échantillon du curseur est supprimé**, le départ d'année
   est conservé avec `preferred` par défaut. Justification mesurée :
   l'audit, section 5, reproductible par `scripts/mesure_sampling.py`
   (`make measure`). Relancée le 2026-11-11 par card-api, mêmes
   conclusions (`dev/audits/2026-11-11_sampling-measure.md`).
5. **La durée de vie du cache de card-api passe au mois.** Ce n'est pas
   une demande de MAKAHO. La raison donnée par l'audit (6 : aucune fiche
   plus fine que le mois) a été écartée par card-api : Hub'Eau révise
   n'importe quel point de l'historique, quel que soit le grain de la
   série. Celle qui tient (donnée validée, `max_age` pour qui veut du
   frais, pool qui renouvelle avant l'échéance) est dans
   `../../CARD_project/card-api/dev/plans/2026-09-18_cache.md` (A1), la
   règle dans son `dev/decisions.md` (« La fraîcheur est un besoin du
   client »).
6. **Une chronique se télécharge entière, jamais par morceaux
   recollés.** Hub'Eau révise n'importe quel point de l'historique. Un
   rafraîchissement partiel produirait une chronique qui n'a jamais
   existé chez Hub'Eau, et `data_fingerprint` signerait cet assemblage :
   une empreinte stable qui ne désigne aucun état réel de la source.
   C'est pire que périmé. **Règle, pas préférence.**
7. **Un seul dépôt, `lou-heraut/MAKAHO`, deux histoires** (2026-11-10).
   La version R Shiny est figée au tag `v1.0.0`, posé sur l'état de
   production, au bout de `master`. La réécriture part d'une histoire
   vide, sur une branche `main` sans ancêtre commun avec le R : pas une
   ligne de l'ancienne application, ni sur le disque ni dans
   l'historique de ce dossier (décision 9). `main` devient la branche
   par défaut à la bascule ; le tag garde l'histoire R. Pas de second
   dépôt : MAKAHO est un service, son identité est son nom et son
   adresse, et l'application R s'arrête à la bascule. CARD-R et EXstat
   ont gardé leur dépôt parce qu'un paquet remplacé continue de tourner
   chez ceux qui l'ont installé ; rien de tel ici. Le nom reste MAKAHO,
   la réécriture sera la 2.0.0, et le label « NO AI USED » a quitté le
   README R avant le tag.
8. **MAKAHO quitte SK8 pour une VM**, peut-être celle de card-api
   (2026-11-10). SK8 est, avec Shiny, une raison de la migration. Le but
   est de regrouper les services de la chaîne au même endroit, de la
   collecte des données à leur représentation. Le dépôt de la forge sk8
   sert la production R jusqu'à la bascule, puis s'archive.
9. **La réécriture part de zéro, pas de l'implémentation R**
   (2026-11-10, voulu par l'utilisateur). L'application R est une
   référence fonctionnelle et un point de comparaison : ce qu'elle
   permet doit se retrouver ou être abandonné en connaissance de cause
   (section 2 de l'audit), et la bascule dit ce qu'on gagne et ce qu'on
   perd. Elle n'est pas un modèle : ses choix d'implémentation étaient
   souvent contraints par Shiny, et certains étaient de mauvaises idées.
   Son code ne se lit pas pour écrire le nouveau ; on compare avec
   l'application en ligne. Les pistes techniques de `ROADMAP.md`, tirées
   de l'audit, sont des propositions que l'implémentation peut remplacer
   par mieux ; seules les décisions de ce fichier engagent.
   **Précisé le 2026-11-11 par l'utilisateur** : l'interface de la
   2.0.0 converge vers celle de la 1.0.0 en ligne, earth.nullschool.net
   restant l'inspiration derrière (le CSS de la 1.0.0 avait été
   construit dans son esprit). Une première page, construite d'après une
   figure de card-api sans regarder l'application, a été refusée parce
   qu'elle s'en éloignait trop. Le code reste neuf ; l'allure se
   reprend. Le CSS de la 1.0.0, propre à Shiny, sert de référence et non
   de vérité : seul son `www/ui.css` se lit, dans ce but (confirmé le
   2026-11-11). Les améliorations se proposent une à une, une fois la
   page proche de la 1.0.0, pas avant. Le relevé de l'interface en
   ligne : `dev/audits/2026-11-11_v1-interface.md`.
10. **Leaflet et un fond de carte complet, pas une carte dessinée en
    SVG** (2026-11-11, voulu par l'utilisateur). MAKAHO montre des
    observations de terrain : il faut pouvoir situer une station sur
    sa rivière, ce que des contours de France et de cours d'eau ne
    permettent pas, et une carte dessinée obligerait à tenir ses
    couches. L'export propre n'oblige pas à y renoncer : la figure
    exportée se compose depuis les données, sur le fond de tuiles
    (`ROADMAP.md`, M6).
    **Le fond, choisi le même jour à l'écran** : le Plan IGN de la
    Géoplateforme en gris clair, multiplié par l'estompage du relief,
    les rivières à partir d'un zoom régional. Il est neutre et léger
    comme celui de la version R, et laisse la place aux points ; il
    est français et sans jeton. Écartés : CARTO, dont les tuiles
    portent depuis peu un filigrane « API KEY REQUIRED » sans clé
    (constaté le 2026-11-11) ; Jawg, le fournisseur de la version R
    (audit, 4.8), qui demande un jeton ; le Plan IGN en couleur et
    OpenStreetMap standard, trop chargés pour ne pas concurrencer les
    marqueurs.
11. **La typographie de la 2.0.0 n'est pas celle de la 1.0.0**
    (2026-11-11 et 12, voulu par l'utilisateur). Raleway pour les
    titres, Inter pour le texte, Roboto Mono pour les chiffres et les
    codes, en police d'accent, pour le côté science des données. Inter
    plutôt que Lato : c'est la plus proche de l'Helvetica de la 1.0.0,
    et elle reste lisible aux petites tailles de l'infobulle. Les trois
    sont servies par MAKAHO (`src/makaho/static/vendor/README.md`).
    **Le séparateur décimal est le point, partout**, même en français :
    c'est l'usage en science des données. C'est l'exception à la
    convergence vers la 1.0.0 (décision 9) : ne pas revenir à Helvetica
    ni à la virgule.

## Les principes de conduite (2026-09-18)

1. **card-api est la seule source des chiffres.** Si une valeur
   affichée par MAKAHO ne peut pas être rattachée à une réponse du
   service, c'est un défaut.
2. **Sobre par défaut.** Flask, HTML, CSS et JavaScript écrits à la
   main, Leaflet. Pas de framework front, pas d'étape de construction,
   pas de base de données tant que rien ne la réclame. MEANDRE
   (`../../MEANDRE_project/MEANDRE/`) est l'exemple qui a poussé à
   quitter Shiny pour Flask, pas un patron de code : sa structure ne se
   reprend pas (2026-11-11, voulu par l'utilisateur).
3. **Ce qui manque à un dépôt se corrige dans ce dépôt.** Le
   contournement local est la dette de demain.
4. **On ne traduit pas, on refait.** Les 6 304 lignes de R de la
   version 1.0.0 ne sont pas un cahier des charges. Le cahier des
   charges est la section 2 de l'audit (ce que l'application permet) et
   les objectifs de la 2.0.0 en tête de `ROADMAP.md`, plus ce que
   l'audit juge sain en 4.1 (décision 9).
5. **Aucun décompte ni plafond écrit en clair** dans une description
   d'API, ni recopié d'un dépôt à l'autre. Règle importée de card-api,
   où elle a été payée deux fois.

## Ce que card-api impose au client

Des faits du service, que `card_client.py` et l'interface doivent
respecter. Leurs valeurs et leur détail vivent dans card-api ; vérifiés
le 2026-11-10.

- **Le mode d'emploi est le README de card-api** : quelle porte prendre,
  réponse immédiate ou job (202, ticket et `Location`), station sans
  série, quotas et clés, provenance.
- **La clé de priorité `MAKAHO` ne passe que par l'en-tête
  `X-API-Key`** : `?key=` dans l'URL est refusé (card-api 0.9.0). Son
  jeton vit dans `.env`, jamais dans un fichier suivi. La vue complète
  la demande : ses 228 stations dépassent le plafond public.
- **Un nom inconnu répond 422** (`extra_forbidden`), qu'il soit un
  paramètre de requête ou un champ du corps d'un job (card-api 0.9.1).
  Une faute de frappe dans le client se voit tout de suite.
- **Les plafonds se lisent au démarrage dans `/v1`** (bloc `limits`),
  jamais en dur. L'un d'eux borne le produit stations × fiches d'une
  réponse immédiate : la vue complète demande une fiche par appel,
  sinon elle part en job.
- **La période entre dans l'extraction, pas seulement dans le test.**
  `start` et `end` servent aux deux et entrent dans la clé du second
  étage de cache : changer de période fait recalculer toutes les
  séries, sans rien retélécharger. Changer alpha ne relance que le test.
  Ordres de grandeur sur 200 stations, mesurés le 2026-09-19 : de
  quelques secondes pour `QA` à plus d'une demi-minute pour `dtLF`
  (`../../CARD_project/card-api/dev/plans/2026-09-18_cache.md`).
- **Une requête abandonnée par la page continue de calculer.** Les
  routes de calcul sont synchrones et rien n'annule un calcul quand le
  client se déconnecte (`main.py` de card-api, lu le 2026-11-10) : il
  occupe jusqu'au bout le calcul que tous les usagers partagent.
- **Depuis la clé `MAKAHO` (2026-11-10), les versions de card-api sont
  des engagements** : tout changement visible par un client prend un
  numéro le jour où il part. Deux `data_fingerprint` ne se comparent
  que s'ils ont le même préfixe ; le client les relaie tels quels.
  card-api reste en 0.x jusqu'à ce que M1 ait tourné sur son contrat.

## Hors périmètre

- **`RRExplore2` n'est pas rebranché.** Jeu débranché, schéma de
  métadonnées incompatible avec le code qui le lit, et 31 fiches de
  précipitation et de température hors du périmètre d'un service qui ne
  sert que les débits Hub'Eau. Projet en soi, à décider séparément.
- **L'anglais n'est pas traité.** Le dictionnaire de l'application R
  existe à 225 entrées et card-api est bilingue de bout en bout : le
  jour où la question se pose, la matière est là.
- **Abandonné pour la 2.0.0, en connaissance de cause** (2026-11-10,
  voulu par l'utilisateur) : l'aide guidée imposée en page d'accueil,
  qui gêne plus qu'elle n'aide (l'aide passe à côté, la visite devient
  facultative, M7) ; le mode capture
  d'écran, que remplace un vrai export de cartes (M6) ; les trois
  thèmes de fond de carte ; les fiches PDF par station, à refaire plus
  tard en chaîne automatisée (M9).

## Ce que l'audit du 2026-09-18 a de faux

`dev/audits/2026-09-18_migration.md` est figé. Trois de ses
affirmations ont été démenties depuis, par card-api :

- **5.5, « le curseur de période n'affecte que le test »** : faux,
  MAKAHO R passe la période à l'extraction comme au test, et card-api
  aussi (cf. plus haut). Le dimensionnement de cache qu'en tire l'audit
  ne tient pas.
- **6, le grain mensuel comme raison de la durée de vie du cache** :
  écarté (décision 5).
- **6, « environ 1,2 s de téléchargement contre 0,04 s de calcul par
  station »** : la mesure de juillet était périmée. Remesurée le
  2026-11-06, une chronique entière coûte de l'ordre de dix secondes
  depuis la production (B5 de
  `../../CARD_project/card-api/dev/plans/2026-09-19_cache-followup.md`).
