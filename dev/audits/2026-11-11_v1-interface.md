> **Statut : photographie datée, close.** L'interface de MAKAHO 1.0.0
> telle qu'elle est en ligne le 2026-11-11 (`makaho.sk8.inrae.fr`),
> relevée pour que la 2.0.0 converge vers elle (décision 9). Ne change
> plus : ses tâches partent dans `ROADMAP.md` (M2 surtout) et dans
> `dev/plans/2026-11-11_m2-map.md`. Elle reste la référence une fois
> l'application R arrêtée (M10).

# L'interface de MAKAHO 1.0.0, en ligne

## Comment le relevé a été fait

- **L'application en ligne**, pilotée par un Chromium sans écran à
  travers son protocole de débogage : captures, clics, survols, et
  lecture des styles calculés et du DOM. Fenêtre de 1440 × 813, puis de
  400 × 820 pour le téléphone. Les captures retenues sont dans
  `dev/audits/2026-11-11_v1-interface/`.
- **`www/ui.css` du tag `v1.0.0`**, lu comme référence d'allure et non
  comme modèle (accord de l'utilisateur, 2026-11-11). Aucun autre
  fichier de l'application R n'a été lu.
- **Le texte de l'aide guidée**, relevé dans la page :
  `dev/audits/2026-11-11_v1-interface/help.md`.
- Un incident : au premier chargement, SK8 a répondu 503 sur la
  bibliothèque Plotly, et la barre de couleur comme le graphique de
  station restaient vides sans message. Un rechargement a suffi.
- La police demandée, Helvetica, n'existe pas sur la machine du relevé :
  les captures montrent sa police de repli.

## La disposition

La carte occupe tout l'écran ; tout le reste flotte par-dessus, dans
des panneaux collés aux bords. Au chargement, l'aide guidée couvre la
carte assombrie (abandonnée comme page d'accueil, M7).

```
+-----------------------------------------------------------------------+
| [recentrer]                              [donnees] [fiches] [photo]   |
|                                                     +-----------------+
|                                                     | QA              |
|                                                     |-----------------|
|                  carte plein ecran                  | nom de la fiche |
|                  zoom 6, centree sur                |-----------------|
|                  46,80 N 2,51 E                     | annee hydro.    |
|                                                     | periode         |
|                                                     | significativite |
|                                                     +-----------------+
|                                                             +---------+
|  +----------------------+                                   | barre   |
|  | panneau Analyse      |                                   | de      |
|  | (ouvert au clic)     |                                   | couleur |
|  +----------------------+                                   +---------+
|                              +-------------------+     +--------------+
|                              | graphique de la   |     | compteurs    |
|  [Analyse]                   | station cliquee   |     +--------------+
|                              +-------------------+   (?) Aide   INRAE |
+-----------------------------------------------------------------------+
```

Positions relevées en 1440 × 813 :

| Élément              | Place                               | Taille (px)    |
|----------------------|-------------------------------------|----------------|
| bouton de recentrage | haut gauche, 11 px des bords        | 32 × 29        |
| trois petits boutons | haut droite, 11 px du haut          | 32 × 29 chacun |
| panneau de résumé    | collé à droite, 100 px du haut      | 184 × 135      |
| barre de couleur     | collée à droite, 170 px du bas      | 82 × 280       |
| compteurs            | collés à droite, 90 px du bas       | 168 × 62       |
| bouton Analyse       | bas gauche, 11 px des bords         | 112 × 33       |
| Aide                 | bas droite, à gauche du logo        | 74 × 23        |
| logo INRAE           | bas droite                          | 92 × 46        |
| graphique de station | centré en bas, 10 px du bord        | 596 × 321      |
| panneau Analyse      | bas gauche, au-dessus de son bouton | 29rem de large |

La carte n'a **ni boutons de zoom ni attribution** visibles : on zoome à
la molette (ou au pincement), et le bouton de recentrage n'apparaît
qu'une fois la carte déplacée. Zoom minimal 5, initial 6. Le fond est
celui de Jawg, en gris clair (remplacé par le Plan IGN, décision 10).

Captures : `main.jpg`, `right-panels.jpg`.

## Les jetons

| Rôle                          | Valeur                                          |
|-------------------------------|-------------------------------------------------|
| police                        | "Helvetica Neue", Helvetica, Arial, sans-serif  |
| taille de base                | 16 px (`medium`)                                |
| panneau sombre                | rgba(5, 5, 10, 0.83), rayon 0.5rem              |
| marges d'un panneau sombre    | 0.5rem 1rem 0.6rem                              |
| bouton sombre                 | rgba(5, 5, 10, 0.90), rayon 0.4rem, texte blanc |
| bouton sombre, survol         | rgba(5, 5, 10, 0.83)                            |
| panneau clair                 | rgb(252, 253, 254), sans marge interne          |
| panneau clair collé au bord   | rayon 0.5rem côté carte, 0 côté bord            |
| texte d'un panneau clair      | #00a3a6 (le turquoise INRAE), marges 10 px      |
| texte courant, panneau sombre | #eeeeee                                         |
| choix inactif                 | #979797 sur transparent, survol blanc           |
| choix actif                   | #66c1bf sur #474747, rayon 0.25rem              |
| séparateur label / choix      | trait vertical de 2 px, #43494c                 |
| lien                          | #979797, survol blanc, jamais souligné          |
| champ de recherche            | fond #181a1b, bord #43494c                      |
| bouton « Actualiser »         | pilule, rgba(39, 86, 98, 0.95), texte #d9d9d9   |
| compteurs                     | 0.8em, #999999, nombres en gras                 |
| attente                       | anneau tournant de 1.6rem (`lds-ring`)          |

Les icônes sont celles de Material Icons (Google, licence Apache 2.0),
reconnues à leurs tracés, en SVG en ligne, hautes de 1em : téléchargement, document, appareil
photo, courbe de tendance (Analyse), point d'interrogation (Aide),
cible (recentrage), roue dentée (affichage).

## Les marqueurs

Un symbole SVG par station, dans une icône de 32 px (repère de 24
unités, soit 4/3 de pixel par unité). Mesuré sur QA, 1968-2024, 10 % :

- **Baisse significative** (60 stations) : triangle pointe en bas,
  23,5 px de large et 20,3 de haut, contour #808080 de 1,5 px.
- **Hausse significative** (2) : le même triangle, pointe en haut.
- **Non significative** (163) : rond de 12,9 px de diamètre, contour
  #B3B3B3 de 1,5 px.
- **Avertissement**, chronique de moins de 30 ans (3) : rond de 13,3 px,
  contour jaune #FDDC5C de 1,9 px.
- **Station cliquée** : son symbole grossit d'une fois et demie, contour
  de 2,1 px.

Ce qui vaut pour tous :

- Le remplissage est toujours la couleur de la classe de la pente,
  ronds compris. La palette est celle de la fiche.
- Une station hors sélection est un rond de couleur neutre ; un
  contour rouge signale une chronique manquante (texte de l'aide, page
  6). Ces deux cas viennent avec la sélection (M3).
- Chaque station porte en plus une zone de clic invisible, un triangle
  un peu plus grand que le symbole.
- Les triangles sont nettement plus gros que les ronds : la carte se
  lit d'abord par les tendances significatives.

## L'infobulle de station

Au survol, une infobulle Leaflet blanche, en 10 px (`tooltip.jpg`) :

```
K518302002 - La Tardes à Évaux-les-Bains          code en gras, nom ; turquoise
-4.37 x 10^-2 [m3.s-1.an-1]   -0.49 [%.an-1]       couleur de la classe, valeurs en gras
Lat : 46.1800        Superficie : 850 km2          gris foncé #333, en gras
Long : 2.44500       Altitude : 324 m
```

La pente absolue s'écrit en notation scientifique, avec exposant ; la
pente relative suit, quand la fiche est relative.

## Le panneau de résumé, la barre de couleur, les compteurs

Trois panneaux clairs collés au bord droit (`right-panels.jpg`) :

- **Le résumé** dit ce que montre la carte : le code de la fiche
  (18 px, gras), un filet turquoise, son nom (12,8 px, gras), un filet,
  puis l'année hydrologique (« du 01 sept. au 31 août »), la période
  (« Période 1968 - 2024 ») et la significativité (« Significativité de
  10% »). Tout en turquoise.
- **La barre de couleur** est verticale : huit cases et, aux deux
  bouts, deux pointes triangulaires pour les classes ouvertes. Les
  bornes des classes sont écrites à droite, arrondies à une décimale
  (1.2, 0.9 ... -1.2). À gauche, le titre court vertical, de bas en
  haut : « TENDANCES OBSERVÉES » en capitales grasses grises, puis
  l'unité, « % par an ». Pas d'histogramme.
- **Les compteurs** : « 228 stations au total », « ∆ 2 hausses
  significatives », « ∇ 60 baisses significatives ».

Le panneau d'affichage (roue dentée du panneau Analyse) permet de
masquer chacun des trois, et de choisir le thème du fond : clair,
terrain ou sombre (les thèmes sont abandonnés, `dev/decisions.md`).

## Les boutons et leurs infobulles

Chaque bouton a une infobulle, toujours au même endroit : un bandeau
sombre en haut à gauche de l'écran, à 47 px du bord, aux coins arrondis
en bas (`button-tooltip.jpg`). Textes relevés :

| Bouton         | Infobulle                                       | Chantier      |
|----------------|-------------------------------------------------|---------------|
| téléchargement | Téléchargement des données                      | M6            |
| document       | Téléchargement de fiches stations               | M9            |
| appareil photo | Mode photo                                      | abandonné, M6 |
| Analyse        | Panneau des paramètres de l'analyse de tendance | M3            |
| Aide           | Aide guidée                                     | M7            |
| recentrage     | Focus sur la sélection de stations              | M2            |
| roue dentée    | Panneau de personnalisation de l'interface      | M3            |

Le logo INRAE, en bas à droite, ouvre le panneau d'information ; au
survol, il prend un fond.

## Le panneau d'information

Panneau sombre en bas à droite, au-dessus du logo (`info-panel.jpg`),
en lignes « libellé | valeur » : le contact (une liste de diffusion),
le développeur et le référent scientifique, le jeu de données sur
Recherche Data Gouv (`doi:10.57745/LNBEGZ`), le code source sur
GitHub, l'hébergeur (SK8), « Interface inspirée de
earth.nullschool.net », la date de mise à jour (janvier 2025) et celle
de l'extraction de l'HydroPortail (septembre 2024).

C'est là que la 1.0.0 dit la fraîcheur de ses données.

## Le clic sur une station

La carte passe au zoom 7 et se recentre pour que la station reste
visible au-dessus du graphique ; le bouton de recentrage apparaît. Le
symbole de la station grossit. Le graphique s'ouvre en bas, au centre,
dans un panneau clair à coins arrondis, fermé par une croix en haut à
gauche (`station.jpg`, `station-graph.jpg`) :

- en tête, les deux lignes de l'infobulle : code et nom, pentes ;
- les boutons de Plotly en haut à droite (capture, déplacement, zoom,
  retour) ;
- en haut, la chronique journalière `Q` en trait noir fin, les lacunes
  ombrées en turquoise pâle ;
- en bas, la série agrégée (`QA`) en points gris, et la droite de Sen
  dans la couleur de la classe ;
- un axe des années commun aux deux, fond gris très clair.

Pas de verdict écrit en clair. C'est le chantier M4.

## Le panneau Analyse

Panneau sombre de 29rem, en bas à gauche (`analysis-panel.jpg`). En
tête, « QA : Moyenne annuelle du débit journalier » ; puis une ligne
par réglage, le libellé à gauche, un séparateur, les choix à droite :

```
Date                 Du 01/09/1968 au 31/08/2024
Données              RRSE
Sélection            Toutes  Aucune  Clic
                     Polygone  Avertissement
                     [ Rechercher               ]
Régime               Hautes Eaux  Moyennes Eaux  Basses Eaux
                     Débit de Base
Variable             QA  QpA  QSA(saison)  QMA(mois)
Année hydrologique   curseur des mois, Janv. à Déc.
                     Optimale  Intervalle
Période              curseur double, 1900 à 2024
Significativité      1%  5%  10%                       (roue dentée)
```

Quand un réglage change, une pilule « Actualiser l'analyse de
tendance » apparaît à droite du bouton Analyse. C'est le chantier M3 ;
le mode échantillon (« Intervalle ») est supprimé (décision 4).

## Sur un téléphone

En 400 × 820 (`phone.jpg`), la disposition reste la même, sans
adaptation : le résumé et la barre de couleur couvrent une bonne part
de la carte, le panneau Analyse prend presque toute la largeur, l'aide
couvre tout l'écran.

## L'aide guidée

Seize pages posées sur la carte assombrie, un grand titre, un
sous-titre et un texte, avec une rangée de points pour naviguer,
« Télécharger la notice » et « Fin de l'aide » (`help-1.jpg`,
`help-2.jpg`). Chaque page éclaire le panneau dont elle parle. Le
texte : `help.md`. C'est le chantier M7.

## Ce que la 2.0.0 ne reprend pas tel quel

Des écarts voulus, à garder en convergeant :

- **L'attribution du fond de carte** : absente de la 1.0.0, elle est
  due au fournisseur des tuiles. Elle reste, discrète.
- **La provenance** : la 1.0.0 la donne en deux dates dans le panneau
  d'information. card-api en donne davantage (date de lecture de
  Hub'Eau, versions de card et de stase) ; sa place naturelle est ce
  même panneau.
- **La superficie et l'altitude** de l'infobulle : card-api ne les sert
  pas. Il lit chez Hub'Eau le code, le libellé, le département, la mise
  en service et la position des stations (`hubeau.py` de card-api, lu
  le 2026-11-11).
- **Le fond** : le Plan IGN en gris, à la place de Jawg (décision 10).
- **Les thèmes, le mode photo, les fiches PDF** : abandonnés ou
  reportés (`dev/decisions.md`, hors périmètre).
