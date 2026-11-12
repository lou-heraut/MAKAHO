> **Statut : sources lues, avec ce qui en sert.** Les outils et les
> travaux qui inspirent les propositions faites pour MAKAHO, chacun avec
> la date où il a été lu et ce qu'on en retient. Une proposition retenue
> part dans `ROADMAP.md` ; les références de la méthode elle-même sont
> dans card-api et stase.

# Références

## Outils comparables

- **MAKAHO 1.0.0, décrit par ses auteurs** : « MAKAHO: An interactive
  cartographic Tool for Trend Analysis of hydrological extremes in
  France » (https://core.ac.uk/works/158620717). Le test y est une
  variante de Mann-Kendall qui tient compte de l'autocorrélation
  d'ordre 1, la pente celle de Theil-Sen : c'est `mk=AR1`, le défaut de
  card-api. Vu en résumé de recherche le 2026-11-12.
- **River Flow Trends Explorer de l'UKCEH** (Royaume-Uni), application
  Shiny archivée
  (https://tnaqa.mirrorweb.com/ukgwa/20260303055645mp_/https://shiny-apps.ceh.ac.uk/river-flow-trends-explorer/) :
  tendances des maxima annuels ; seules les stations de plus de 26 ans
  de données y entrent, la significativité est marquée à 5 %. Le plus
  proche cousin de MAKAHO trouvé. Vu en résumé de recherche le
  2026-11-12, à ouvrir.
- **Indicateur « Streamflow » de l'EPA** (États-Unis,
  https://www.epa.gov/climate-indicators/streamflow) : la carte donne
  le changement en pourcentage sur toute la période (1940 à 2022), pas
  une pente par an. Une lecture plus directe pour le grand public. Vu en
  résumé de recherche le 2026-11-12.

## Représentations

- **Les bandes de débit (« streamflow stripes »)** de l'UKCEH, sur le
  modèle des bandes de réchauffement d'Ed Hawkins
  (https://climatelabbook.substack.com/p/visualising-climate-impacts-on-uk) :
  une année par bande, colorée par son écart. Leur constat : les débits
  ne changent pas tous dans le même sens d'un bassin à l'autre,
  contrairement à la température. Vu en résumé de recherche le
  2026-11-12.

## Méthode

- **Renard B., Lang M., Bois P. et al. (2008)**, « Regional methods for
  trend detection: Assessing field significance and regional
  consistency », *Water Resources Research* 44, W08419
  (doi:10.1029/2007WR006268). Quatre façons de juger si un ensemble de
  tests locaux dit quelque chose à l'échelle d'un réseau
  (significativité d'ensemble), comparées par simulation, puis
  appliquées à 195 stations françaises : pas de changement généralisé à
  l'échelle nationale, des changements cohérents dans quelques régions.
  Michel Lang est le référent scientifique de MAKAHO. Vu en résumé de
  recherche le 2026-11-12, à lire en entier.
- **La méthode du taux de fausses découvertes** (Benjamini et
  Hochberg), recommandée par Wilks (2006) pour la significativité
  d'ensemble : plus puissante que le décompte des tests significatifs,
  et robuste à la dépendance spatiale entre stations. Vu à travers une
  étude canadienne des étiages
  (https://espace.inrs.ca/id/eprint/9499/1/P1636.pdf) le 2026-11-12 ;
  l'article de Wilks reste à lire.
