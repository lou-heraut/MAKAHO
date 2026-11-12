# MAKAHO

**MAnn-Kendall Analysis of Hydrological Observations** : une carte des
tendances des débits sur les cours d'eau français peu influencés par
l'homme, les 228 stations du Réseau de Référence pour la Surveillance
des Étiages (RRSE). Pour chaque station, le test de Mann-Kendall dit si
une variable hydrologique (le débit moyen annuel, l'étiage, la crue...)
évolue de façon significative, et la pente de Sen de combien.

> **Version 2.0.0 en cours d'écriture.** Ce dépôt réécrit l'application
> en ligne sur [makaho.sk8.inrae.fr](https://makaho.sk8.inrae.fr/),
> une application R Shiny figée au tag
> [`v1.0.0`](https://github.com/lou-heraut/MAKAHO/tree/v1.0.0). La
> réécriture affiche aujourd'hui la carte des tendances du débit moyen
> annuel ; les menus, les graphiques par station et les exports
> suivent. Où en est le travail : [`ROADMAP.md`](ROADMAP.md) ; ce qui a
> été fait : [`CHANGELOG.md`](CHANGELOG.md).

## D'où viennent les chiffres

MAKAHO ne calcule rien lui-même. Tout vient du service
[card-api](https://card-api.riverly.inrae.fr/), qui lit les débits
journaliers de [Hub'Eau](https://hubeau.eaufrance.fr/) (Licence
Ouverte), les agrège selon les fiches
[card](https://github.com/lou-heraut/card) et teste leur tendance avec
[stase](https://github.com/lou-heraut/stase). Le panneau
d'information, qui s'ouvre sur le logo INRAE, donne la date des données
et les versions qui ont produit la carte.

Le fond de carte est celui de la Géoplateforme de l'IGN.

## Lancer MAKAHO chez soi

Python 3.11 ou plus récent.

```
make install          # crée .python_env et y installe MAKAHO
cp .env.example .env  # puis compléter .env
make run              # http://127.0.0.1:5000
```

`.env.example` décrit les réglages. La carte du RRSE entier demande une
clé de priorité de card-api, qui se demande par courriel (voir le
README de card-api). `make` liste les autres commandes, dont les tests.

## Citer, réutiliser

- Licence : [AGPL-3.0-or-later](LICENSE).
- Citation : [`CITATION.cff`](CITATION.cff) ; auteurs :
  [`AUTHORS`](AUTHORS).
- Le réseau RRSE : Giuntoli I., Renard B., Vidal J.-P., Bard A. (2013).
  Low flows in France and their relationship to large scale climate
  indices. *Journal of Hydrology*.
  [doi:10.1016/j.jhydrol.2012.12.038](https://doi.org/10.1016/j.jhydrol.2012.12.038)

MAKAHO 1.0.0 a reçu le Prix Science Ouverte des données de la recherche
2024, catégorie « Créer les conditions de la réutilisation ».
