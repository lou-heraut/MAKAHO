> **Statut : photographie datée, close.** État de MAKAHO R Shiny au
> 2026-09-18 (dépôt `../MAKAHO/`, dernier commit 2026-04-16) et de
> ce que l'écosystème `card` couvre déjà. Ce document établit les
> constats ; il ne dit pas quoi faire, cela vit dans `ROADMAP.md` et
> `dev/decisions.md`. Il n'est pas tenu à jour : quand il aura vieilli,
> il restera le point de départ, daté, et le CHANGELOG racontera la
> suite.
>
> Les mesures des sections 5 et 6 sont **reproductibles** :
> `scripts/mesure_sampling.py`.
>
> **Validité au 2026-11-10.** Le texte ne change pas ; seul ce bandeau
> se tient à jour. Le `PLAN.md` qu'il cite s'est partagé entre
> `ROADMAP.md` et `dev/decisions.md`. Trois de ses affirmations ont été
> démenties depuis (sections 5.5 et 6) : `dev/decisions.md`, « Ce que
> l'audit du 2026-09-18 a de faux ».

# AUDIT : état des lieux de MAKAHO avant migration

## 1. Ce qu'est MAKAHO, et pourquoi ça compte

MAKAHO (MAnn-Kendall Analysis of Hydrological Observations) est un
visualiseur cartographique interactif des tendances hydrologiques
françaises, en ligne sur `makaho.sk8.inrae.fr`, développé à INRAE
(UR RiverLy) et hébergé par le projet SK8.

La question à laquelle il répond tient en une phrase : **les régimes des
cours d'eau français peu influencés par l'homme sont-ils stationnaires,
et si non, dans quel sens et de combien ?** Chaque station du réseau
porte un symbole qui dit le sens (triangle haut, triangle bas, rond si
non significatif) et une couleur qui dit l'ampleur de la pente. Cliquer
ouvre la chronique et la droite de tendance.

Ce qui en fait autre chose qu'une carte de plus :

- **Le réseau interrogé est choisi, pas subi.** 228 stations du Réseau
  de Référence pour la Surveillance des Étiages (RRSE), sélectionnées
  pour la qualité de mesure, plus de 40 ans de profondeur historique et
  une influence anthropique faible. Ce n'est pas un attribut Hub'Eau :
  c'est un choix d'étude, publié (`hal.science/hal-00833431`).
- **La méthode est celle de la littérature.** Mann-Kendall avec
  correction d'autocorrélation d'ordre 1 (Hamed & Rao 1998), pente de
  Theil-Sen, seuil réglable.
- **Tout ressort.** Données agrégées, diagnostics et README de
  provenance se téléchargent depuis l'application ; une partie est
  déposée sur Recherche Data Gouv (`doi:10.57745/LNBEGZ`).

Reconnaissance : **Prix Science Ouverte des données de la recherche
2024**, catégorie « Créer les conditions de la réutilisation » (MESR).
EGU 2024, dépôts HAL (hal-04582254, hal-04837537, hal-04983136). Repris
hors INRAE, par exemple par le Creseb. AGPL-3.0-or-later, avec
`codemeta.json`, `CITATION`, code de conduite.

**Conséquence pour la migration.** Ce qui est primé n'est pas le code
R : c'est la chaîne « données ouvertes, méthode explicite, résultat
réutilisable ». Une réécriture n'a le droit d'exister que si elle rend
cette chaîne plus courte et plus vérifiable. Le `codemeta.json` déclare
`developmentStatus: inactive` : le projet a besoin d'une relance.

## 2. Ce que l'application fait

```
     carte plein écran, 228 marqueurs
              |
   +----------+-----------------------------------+
   |                                              |
 panneau ANALYSE                            clic sur un marqueur
   | reseau (RRSE)                                |
   | selection de stations                        v
   |   (tout / aucun / clic / polygone     panneau graphique :
   |    / recherche par nom)                 chronique Q journaliere
   | regime  (4 choix)                       + serie agregee
   | variable (38 fiches)                    + droite de Sen
   | parametre (proba, mois, saison)         + verdict en clair
   | fenetre d'echantillonnage (slider)
   | periode d'analyse (slider annees)
   | risque alpha (1 / 5 / 10 %)
   |
   +--> bouton ACTUALISER
              |
              v
   recalcul complet, puis re-rendu :
   marqueurs, barre de couleur, compteurs, graphique
```

Autour : thème clair/sombre/terrain, mode capture d'écran, aide guidée
de 16 pages, téléchargement de l'analyse (zip de CSV + README de
provenance + licence), téléchargement de fiches PDF par station.

| | |
|---|---|
| Stations | 228 (RRSE) |
| Fiches atteignables | 38, toutes à entrée `Q`, toutes de sortie `series` |
| Régimes | 4 (hautes eaux 13, basses eaux 14, moyennes eaux 6, débit de base 5) |
| Chronique locale | `data_RRSE.fst`, 5 160 852 lignes, 19 Mo, figée au 2024-09-17 |
| Fiches PDF | 232 fichiers, 364 Mo, plus un zip de 150 Mo |
| Langue | `fr` en dur, dictionnaire `fr`/`en` de 225 entrées |

## 3. Architecture actuelle

```
  navigateur                     processus R Shiny (1 par instance)
 +-----------+                  +-----------------------------------+
 |  leaflet  | <--- websocket ->|  server.R  3394 l.                |
 |  plotly   |                  |  ui.R      1387 l.                |
 |  shinyjs  |                  |  tools.R    790 l.                |
 +-----------+                  |  marker_manager.R 246 l.          |
                                +-----------------+-----------------+
                                                  |
                    +-----------------------------+------------------+
                    |                |                    |          |
              data/fst/*.fst   CARD-MAKAHOapp/      resources/       www/
              chroniques Q     69 fiches .R         895 SVG          ui.css
              + metadonnees    (sourcees a chaud)   de marqueurs     731 l.
                    |                |
                    +-------+--------+
                            v
                 EXstat::CARD_extraction  (agregation)
                 EXstat::process_trend    (MK + Sen)
                 ASHE (E/S), dataSHEEP (couleurs)
```

Tout est dans le processus : la donnée, les définitions de variables, le
calcul, le rendu. Aucune frontière interne, donc aucun endroit où
brancher autre chose. 6 304 lignes de R.

| Fichier | Lignes | Rôle |
|---|---|---|
| `server.R` | 3 394 | logique réactive, calcul, tracés |
| `ui.R` | 1 387 | panneaux, contrôles, 16 pages d'aide |
| `tools.R` | 790 | lecture des fiches CARD, widgets maison, masquage |
| `marker_manager.R` | 246 | génération et lecture des 895 marqueurs SVG |
| `settings.R` | 205 | constantes, couleurs, jeton de tuiles |
| `script_create.R` | 137 | fabrication hors-ligne du `.fst` |
| `global.R` | 103 | chargement des paquets, bascule dev/prod |
| `get_CARD.R` | 42 | extraction du sous-ensemble de fiches |

## 4. Constats

### 4.1. Ce qui est sain et doit être repris

Perdre ces points serait une régression.

- **La boucle d'ergonomie.** Le bouton « Actualiser » n'apparaît que si
  un paramètre a bougé (`rv$need_actualise`) : il sépare le réglage du
  recalcul. À conserver même quand le calcul devient rapide.
- **La sémantique des marqueurs.** Forme = sens et significativité,
  couleur = classe de pente, taille = station affichée, gris = hors
  sélection, jaune/rouge = donnée douteuse ou manquante. Quatre
  informations sur 20 pixels.
- **La barre de couleur qui porte un histogramme.** La distribution des
  pentes est dessinée dans la légende : classe et population au même
  endroit.
- **Le garde-fou des 30 ans.** Le slider de période refuse une fenêtre
  de moins de 30 ans et se réajuste (`server.R:1422`). L'interface
  interdit au lieu de commenter.
- **Le README de provenance livré dans le zip.** `data/README.txt` est
  un gabarit à trous (`[DATE]`, `[PARAM]`) rempli au téléchargement avec
  les paramètres exacts, le DOI, le SWHID du code, la licence. C'est ce
  qui rend l'export citable.
- **La chaîne de sélection sur la carte** (clic, polygone additif ou
  soustractif, recherche par nom, tout/aucun) est complète.

### 4.2. Shiny : le plafond structurel

**C'est le constat qui commande la migration, et il ne dépend d'aucun
choix fait dans MAKAHO.**

Shiny sert toutes les sessions connectées depuis **un seul processus R,
sur une seule boucle d'événements, mono-thread**. Le moindre bloc de
code R synchrone suspend toutes les autres sessions : pas seulement un
calcul, mais la lecture d'un `.fst`, la sérialisation d'une figure
plotly, la comparaison des listes d'URL de marqueurs. La latence perçue
par un usager n'est pas le coût de son geste, c'est la **somme** des
gestes en cours de tous les autres.

Deux réponses existent, aucune n'est bonne :

- **Multiplier les processus** (shinyapps.io, ShinyProxy, SK8). Chaque
  réplique recharge sa copie de tout, 19 Mo de chroniques comprises.
  L'unité d'isolation de Shiny est le **processus**, pas la requête : on
  provisionne du CPU et de la mémoire **par personne connectée**, y
  compris pendant qu'elle regarde la carte sans rien demander. Ce n'est
  pas un réglage, c'est une facture.
- **Passer en asynchrone** (`promises`, `future`) : restructuration du
  code réactif, travailleurs qui rechargent leur contexte, invalidation
  réactive toujours sur le thread principal. Beaucoup de travail pour
  repousser le plafond sans le supprimer.

Dans une application web classique, l'état vit dans le navigateur, la
requête est courte, le travailleur retourne au pot commun aussitôt.
Quelques travailleurs servent bien plus d'usagers qu'il n'y en a, parce
que l'essentiel du temps est passé à **attendre** (ici `card-api`), pas
à calculer. Ce n'est pas une optimisation, c'est un autre modèle de
concurrence, et il justifie la réécriture à lui seul.

**Même si le calcul devenait gratuit, le plafond resterait.** Il
descendrait, il ne disparaîtrait pas.

Ce qu'il faut dire honnêtement de l'autre côté : MAKAHO existe grâce à
Shiny. Un chercheur y transforme une analyse en objet cliquable en un
après-midi. Le défaut n'est pas que Shiny existe, c'est qu'il n'offre
**aucune rampe de sortie** entre « cinq collègues » et « service
public » : le coût du passage est une réécriture totale, payée des
années plus tard.

### 4.3. Le calcul : ce qui fait mordre le plafond tout de suite

À chaque « Actualiser », `server.R:1687` appelle `CARD_extraction` puis
`process_trend` sur **toutes les stations sélectionnées**, dans le
processus Shiny, de façon synchrone. Aucun cache : revenir à une
variable déjà consultée la recalcule intégralement.

1. **Le coût est payé à chaque fois.** L'agrégation journalier vers
   annuel est la partie chère ; son résultat ne dépend que du triplet
   (station, fiche, fenêtre d'échantillonnage), qui bouge rarement.
2. **Le calcul est mélangé au rendu.** `process_trend` est appelé au
   milieu d'un `observeEvent` qui pilote aussi des `hide()` et des
   `leafletProxy()`. Rien n'est extractible ni testable.
3. **Le paramètre bon marché coûte le prix du cher.** Changer alpha (une
   comparaison de p-value) relance toute l'agrégation.

Le découpage juste est celui de `card-api` : l'**extraction** produit la
série annuelle et ne dépend pas des paramètres de test ; la **tendance**
s'applique à cette série et coûte des microsecondes. MAKAHO les a
fusionnés.

**L'ordre compte pour décider : on ne sort pas de Shiny parce que le
calcul est lourd, on sort de Shiny parce que son modèle de concurrence
ne convient pas à un service public.** Alléger le calcul est ce qui rend
l'application agréable ensuite.

### 4.4. La donnée : un instantané sans chemin de mise à jour

`data/fst/data_RRSE.fst` est figé au 2024-09-17, produit hors-ligne par
`script_create.R` depuis des fichiers `*_HYDRO_QJM.txt` scrappés de
l'HydroPortail, sous un chemin absolu de la machine de développement
(`meta_RRSE.fst`, colonne `path`). Le slider d'années est plafonné en
dur à `slider_maxYear = 2024`.

**Pour que l'application dise ce qui s'est passé en 2025, il faut un
geste manuel, sur un poste précis, avec des fichiers absents du dépôt.**
Un site de suivi de tendance qui ne suit pas le temps qui passe perd sa
raison d'être. C'est le constat le plus lourd, et il survivrait à
n'importe quelle réécriture qui ne changerait pas la source.

Point favorable et non acquis d'avance : **les codes de stations du
`meta_RRSE.fst` sont déjà les codes Hub'Eau post-refonte**
(`A234021001`), l'ancien code Banque Hydro étant conservé dans
`code_hydro2`. Vérifié : les 228 codes sont **identiques, à la ligne
près**, à `card-api/examples/stations_rrse.txt`. Aucun travail de
correspondance à faire.

### 4.5. La carte et ses 895 marqueurs

Chaque combinaison (taille, forme, couleur de trait, couleur de
remplissage) est un SVG pré-généré par `ggplot2` dans
`resources/marker/`, soit 895 fichiers pour 3,6 Mo, servis à Leaflet
comme `iconUrl`.

Le rendu (`server.R:396`) compare la liste des URL d'icônes à celle du
tour précédent pour ne redessiner que ce qui change, sépare les
marqueurs en deux groupes selon que la forme vaut 21 ou non, puis pose
une **troisième couche de marqueurs invisibles** (`markerListVoid`) dont
le seul rôle est de porter l'infobulle.

La cause est Shiny : `leaflet::makeIcon` veut une URL, et rien n'invite
à styler un SVG déjà présent dans le DOM. Dans un front web, trois
symboles définis une fois, un `divIcon` par station, la couleur en
propriété CSS personnalisée et l'état en classe. Le gain n'est pas la
disparition des fichiers, c'est que mettre la carte à jour devienne
`el.className = ...` sur des noeuds déjà en place, au lieu de
`removeMarker` puis `addMarkers` avec un diff d'URL.

### 4.6. Le graphique par station

680 lignes pour un seul graphique (`server.R`, section 8.3). Trois
sous-figures plotly (`fig0` précipitations, `fig1` débit journalier,
`fig2` série agrégée et tendance) dont les blocs de configuration sont
recopiés presque à l'identique. Le repérage des lacunes (plages de NA
consécutives à ombrer) est écrit deux fois.

Le contenu est bon, la fabrication ne l'est pas. Une fonction de tracé
paramétrée par (série, unité, couleur, format de date) rend les trois
panneaux.

### 4.7. Ce qui est mort, en double, ou en trop

- **`RRExplore2` est débranché.** Le bouton de choix est commenté
  (`ui.R:322`), seul `RRSE` est proposé. Mais tout ce qui le sert est
  là : `data_RRExplore2.fst` (115 Mo, 573 stations, colonnes
  `Q P Pl Ps T`), 31 fiches de précipitation et de température, le
  sélecteur T/Q/P, la sous-figure `fig0`, quatre branchements
  `if (rv$data_name == "RRExplore2")`. Et il ne pourrait pas être
  rebranché : `meta_RRExplore2.fst` expose `Code`, `Nom`, `Altitude_m`
  quand le code lit `code`, `name`, `elevation_m`, sans `lon_deg` ni
  `lat_deg`. **Du code mort qui ne compile plus contre sa propre
  donnée**, et environ un tiers du poids apparent du projet.
- **Chaque fichier a son jumeau `~`** (sauvegardes emacs) : 16 dans
  l'arbre, dont `server.R~` et `renv.lock~` (300 Ko). Plus
  `.emacs.desktop`, `.Rhistory`, `Dockerfile_old`, `codemeta.json~`.
- **`get_Variable` (`tools.R:34`) parse les 69 fiches `.R` à chaud**,
  avec `assign()` dans l'environnement courant, des expressions
  régulières sur les noms de fichiers pour deviner les familles
  paramétrées, et un `bind_rows` en boucle. Un analyseur syntaxique
  maison pour une information que `/v1/cards` et `/v1/vocabulary`
  servent classée, bilingue et versionnée.

### 4.8. Hygiène et sécurité

- **Le jeton de tuiles Jawg est en clair dans `settings.R:60`, et dans
  l'historique git d'un dépôt public.** À révoquer et à passer par une
  variable d'environnement, indépendamment de ce chantier.
  `resources/theme.txt` propose aussi OpenStreetMap et CartoDB, qui ne
  demandent pas de jeton.
- Un fichier `pw.txt` (15 octets) est à la racine de l'arbre de travail.
  Non ouvert ici ; à vérifier avant toute publication.
- **La bascule dev/production repose sur le nom de la machine**
  (`computer = "LGA-LYP6123"`, `global.R:27`) et sur un chemin absolu
  `/home/lheraut/Documents/INRAE/projects`. Le comportement dépend de
  l'hôte. Le README le reconnaît : « The local personalized instance has
  not been properly tested yet ».
- **Aucun test, à aucun niveau.** Pas de `tests/`, pas de CI hors la
  construction d'image SK8. Le seul filet existant est ailleurs :
  `card-api/tests/test_makaho.py`.

### 4.9. Le multi-utilisateur

- **Le téléchargement écrit dans un répertoire partagé qu'il efface
  d'abord** (`server.R:2953` : `unlink(data/tmp)` puis `dir.create`).
  Deux téléchargements simultanés se marchent dessus, et l'un des deux
  reçoit l'analyse de l'autre.
- **Aucune URL ne désigne un résultat** : pas de `session$clientData`,
  pas de `updateQueryString`. On ne peut ni partager « la tendance du
  VCN10 sur la Loire entre 1970 et 2020 », ni la citer, ni y revenir.
  Pour un outil dont la valeur est la réutilisation, c'est l'absence la
  plus coûteuse, et la moins chère à corriger.
- Le dictionnaire `fr`/`en` est complet à 225 entrées mais `lg = "fr"`
  est en dur (`global.R:88`). La moitié anglaise est écrite, maintenue,
  et inatteignable.

## 5. Le curseur d'échantillonnage : ce que MAKAHO permet de produire

**Cette section est la justification écrite d'une suppression de
fonction. Elle sera contestée un jour. Les chiffres sont reproductibles
par `scripts/mesure_sampling.py`.**

Mesures faites le 2026-09-18 sur les 228 chroniques RRSE réelles (cache
local de `card-api`), période 1968-2024, `card` 0.13.0, `stase` 0.6.1.

### 5.1. Le curseur a deux modes, qui ne sont pas de même nature

Le curseur est **mensuel**, donc son espace est fini :

- **mode départ d'année** : 12 valeurs (`01-01` à `12-01`). Il dit quand
  commence l'année de calcul ;
- **mode échantillon** : 144 couples (début, fin). Il restreint
  l'agrégation à une **sous-période intra-annuelle**.

### 5.2. Le départ d'année change les résultats, et c'est légitime

```
  carte    comparaison            verdicts qui basculent   pentes qui changent de SIGNE
  ---------------------------------------------------------------------------------
  QA       preferred vs 01-01       35 / 228   (15,4 %)        8 / 228   ( 3,5 %)
  QA       preferred vs 05-01       22 / 228   ( 9,6 %)        5 / 228   ( 2,2 %)
  VCN10    preferred vs 01-01        0 / 228   ( 0,0 %)        0 / 228   ( 0,0 %)
  VCN10    preferred vs 05-01        6 / 228   ( 2,6 %)        4 / 228   ( 1,8 %)
  tQJXA    preferred vs 01-01       35 / 228   (15,4 %)       73 / 228   (32,0 %)
  tQJXA    preferred vs 05-01       28 / 228   (12,3 %)       56 / 228   (24,6 %)
```

Le zéro sur VCN10 et `01-01` est un contrôle : le `preferred` de VCN10
**est** `01-01`, les deux colonnes sont donc le même calcul. Sa présence
valide la mesure.

**tQJXA est le cas instructif.** C'est une date, donc une variable
circulaire : « la crue arrive plus tôt » n'a de sens que relativement à
un point de coupe. Déplacer le départ d'année retourne le signe de la
pente pour **un tiers du réseau**. Ce n'est pas un défaut, c'est la
nature de l'objet, et c'est la raison d'être de `preferred` : la fiche
déclare le point de coupe qui donne un sens à la question.

Conclusion : le départ d'année reste **le même objet scientifique**. Le
choix est légitime, il doit rester offert, et `preferred` doit être le
défaut parce que c'est lui qui rend les stations comparables.

### 5.3. La fenêtre partielle fabrique une autre variable

Fenêtre février-juillet, parfaitement atteignable avec le curseur
actuel. Où tombent réellement les étiages du RRSE :

```
  jan    1,6 %  ##                                                      hors fenetre
  fev    1,2 %  #
  mar    0,6 %  #
  avr    0,2 %
  mai    0,3 %
  jun    1,6 %  ##
  jui    8,5 %  ##############
  aou   28,7 %  ###############################################         hors fenetre
  sep   36,2 %  ####################################################### hors fenetre
  oct   15,0 %  ########################                                hors fenetre
  nov    3,7 %  ######                                                  hors fenetre
  dec    2,3 %  ###                                                     hors fenetre
```

**87,6 % des étiages annuels tombent hors d'une fenêtre
février-juillet.** Sur 226 stations exploitables :

- la valeur que MAKAHO continue d'appeler **VCN10** est en moyenne
  **1,61 fois plus haute** (médiane 1,51 ; de 0,66 à 3,64) ;
- **23 % des stations changent de verdict de stationnarité** ;
- dans le zip téléchargé, `metaEX.csv` dit toujours
  `variable_en: VCN10`, avec le nom et la palette des basses eaux. Seule
  la colonne `sampling_period_en` porte la trace de la fenêtre
  (`CARD_process.R:313` la recopie, ce qui est à mettre au crédit de
  MAKAHO).

L'utilisateur produit un **minimum de printemps**, l'interface l'appelle
**étiage**, la carte le colorie avec la palette étiage, et le fichier
est citable en l'état.

*(Méthode : `card` refuse le couple, la mesure reproduit donc VCN10 hors
de `card`, moyenne mobile 10 jours centrée puis minimum via `stase`.
C'est l'ordre de grandeur qui compte.)*

### 5.4. `card` trace déjà la bonne ligne

`card` distingue la chaîne `"09-01"` de la liste `["02-01","07-31"]` et
refuse de surcharger la seconde (`card/extraction.py:603`, règle énoncée
dans `_override_sampling`). Ce n'est **ni un oubli ni un trou de
documentation** : c'est une décision, vérifiée en exécution
(`stase.extract` accepte le couple, `card.extract` le refuse).

Les chiffres montrent que cette ligne est là où la science la met :

- déplacer le **départ d'année** change le résultat, parfois beaucoup,
  mais on parle toujours de la même variable ;
- imposer une **fenêtre partielle** ne change pas le résultat de la
  variable, ça change **la variable**. « VCN10 sur février-juillet »
  n'est pas VCN10.

CARD-R n'avait pas ce scrupule
(`sampling_period_overwrite=c("02-01","07-31")`, documenté dans
`CARD_process.R:152`), et c'est ce que MAKAHO utilise.

### 5.5. La conséquence de cache

Le curseur de période d'analyse n'affecte que le test, donc une série
agrégée unique couvre toutes les périodes. Le curseur d'échantillonnage,
lui, **entre dans la clé de cache de l'extraction** :

```
  ce qu'on garde                            series          volume
  ---------------------------------------------------------------
  preferred seul                            228 x 38 =   8 664     ~4 Mo
  + les 12 departs d'annee                  228 x 38 x 12 = 104 k  ~50 Mo
  + les 144 fenetres partielles             228 x 38 x 144 = 1,2 M ~600 Mo
```

Supprimer le mode échantillon divise la grille par douze **et** rend la
sortie citable. Les deux raisons pointent dans le même sens.

## 6. Ce que l'écosystème `card` couvre déjà

Mesuré le 2026-09-18 contre `https://card-api.riverly.inrae.fr`
(`api_version` 0.3.1, `card` 0.4.0, `stase` 0.6.1 en production).

| Besoin MAKAHO | Couverture |
|---|---|
| Les 38 fiches Q | **totale.** Les 69 identifiants de `CARD-MAKAHOapp/` existent dans le corpus `card` (472 fiches). Aucun manquant. |
| Les 4 régimes | **exacte.** `phenomenon` vaut `high-flows` 13, `low-flows` 14, `mean-flows` 6, `baseflow` 5 : les quatre menus, aux mêmes effectifs. |
| Le catalogue | `/v1/cards`, `/v1/vocabulary` : bilingue, six facettes, palette, unité, méthode en prose, `is_date`, `relative`, version et SWHID par fiche. Remplace `get_Variable`. |
| Les 228 stations | liste identique à `examples/stations_rrse.txt` ; positions et libellés par `stations_meta=true`. Remplace `meta_RRSE.fst`. |
| L'agrégation | `/v1/extract`, même moteur porté. |
| Mann-Kendall + Sen | `/v1/trend`, défauts `mk=AR1` et `level=0.1` : les défauts de MAKAHO. |
| Le protocole MAKAHO | `sampling=preferred`, `start=1968-01-01`, documentés comme la fenêtre d'analyse du projet. |
| Les bornes de la barre de couleur | `a_min`, `a_max`, `a_relative_min`, `a_relative_max` sont les extrêmes **sur l'ensemble demandé**, écrêtés aux centiles comme `extreme_prob = 0.01`. |
| Les points du graphique | `series=true` joint la série agrégée au diagnostic, issue du même calcul. Un appel sert la carte et le graphe. |
| La provenance | `card_commit`, `stase_commit`, SWHID, `data_fetched_at`, `data_fingerprint`, bloc `rights` dans chaque réponse. |

**La parité numérique est déjà démontrée.** `card-api/tests/test_makaho.py`
rejoue `stase.trend` sur les exports `dataEX` de MAKAHO (QA, tQJXA,
dtLF, QSA_DJF, 228 stations) et exige l'égalité des `h`, et un écart
inférieur à 1e-12 sur `p` et sur `a`. Comparaison à trois voies sur les
mêmes chroniques Hub'Eau : CARD-R et `card`/`stase` identiques, séries
concordantes à 94-100 %, `h` à 99-100 %.

Latences mesurées :

| | |
|---|---|
| un couple (station, fiche), à froid | 7,5 s |
| le même, chronique en cache | 0,21 s |
| 3 stations x 2 fiches, à froid | 12,3 s |

Coûts publiés par le service : environ **1,2 s de téléchargement contre
0,04 s de calcul par station**, soit trente fois plus cher d'aller
chercher que de calculer. C'est le chiffre qui commande l'architecture.

Grain temporel du corpus, vérifié sur les 472 fiches : **aucune fiche ne
produit une série plus fine que le mois** (133 par mois, 57 annuelles,
44 par saison, 17 estivales, 16 hivernales). Un rafraîchissement plus
fréquent que mensuel ne peut donc changer aucune sortie de série.

## 7. Ce qui manque, et à qui

| Dépôt | Ce qui manque | Pourquoi |
|---|---|---|
| **stase** | le **nombre de points** sur lequel la tendance est calculée | une pente sur 12 points ne se lit pas comme une pente sur 55 ; c'est l'ingrédient qui permet à MAKAHO d'appliquer son seuil de 30 ans sans toucher au journalier. Sortie actuelle : `level, h, p, a, b, period_start, period_end, mean_period, a_relative, variable, a_min, a_max, a_relative_min, a_relative_max` |
| **card** | rien à changer ; l'arbitrage de la 5.4 est à **consigner** | pour qu'il ne soit pas rouvert par inadvertance |
| **card-api** | TTL de cache **écrite en dur** (`hubeau.py:40`, 24 h) | une décision de politique doit être réglable ; et le grain du corpus est le mois |
| | pas de moyen pour un client de **demander du frais** | celui qui suit l'étiage en cours a un besoin réel que la TTL longue ne sert pas |
| | rien ne **garde chaud** ce qui est consulté souvent | le téléchargement coûte trente fois le calcul |
| | pas de **cache d'extraction** (le second étage prévu dans `API.md`) | c'est lui qui supprime les 9 s d'agrégation, pour tous les usagers |
| | `SYNC_STATIONS_CACHED` vaut 60, MAKAHO en demande 228 | à régler **après** mesure, jamais à l'intuition |
| | la **chronique journalière** n'est pas servie | MAKAHO en a besoin pour tracer la station cliquée ; le service l'a déjà en cache. Sans cela, la même page affiche deux provenances pour un même débit |
| **MAKAHO** | tout le reste | cf. `PLAN.md` |

Hors périmètre : les 31 fiches de précipitation et de température ne
peuvent pas passer par un service qui ne sert que les débits Hub'Eau.
Sans conséquence aujourd'hui, `RRExplore2` étant débranché.

## 8. Verdict

**La migration est faisable, et la partie difficile est déjà faite.**

Ce qui aurait pu bloquer ne bloque pas : les identifiants de fiches
coïncident (69 sur 69), les codes de stations coïncident (228 sur 228),
les défauts statistiques coïncident (`AR1`, 0,1, 1968, `preferred`), et
l'égalité numérique est tenue par un test à 1e-12.

Ce que la migration fait gagner : l'application redevient **tenable**
(le modèle de concurrence cesse de facturer au connecté), **vivante**
(la chronique se met à jour), **citable** (chaque résultat porte le
commit qui l'a produit) et **partageable** (une analyse a une URL).

Les 6 304 lignes de R ne se traduisent pas : entre le code mort de
`RRExplore2`, les 895 marqueurs, l'analyseur de fiches maison et les
680 lignes d'un graphique, la moitié disparaît sans remplacement.

La suite, étape par étape et dépôt par dépôt, est dans `PLAN.md`.
