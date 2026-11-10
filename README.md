# MAKAHO [<img src="https://github.com/lou-heraut/MAKAHO/blob/cf59042ee48e7ada24d89ae8fa7f7878cff3eb26/www/MAKAHO.png" align="right" width=100 height=100 alt=""/>](https://makaho.sk8.inrae.fr/)

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-green)](https://lifecycle.r-lib.org/articles/stages.html)
![](https://img.shields.io/github/last-commit/lou-heraut/MAKAHO)
[![](https://img.shields.io/badge/Shiny-shinyapps.io-blue?style=flat&labelColor=white&logo=RStudio&logoColor=blue)](https://makaho.sk8.inrae.fr/)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](code_of_conduct.md) 
<!-- badges: end -->

[MAKAHO](https://makaho.sk8.inrae.fr/) stands for MAnn-Kendall Analysis of Hydrological Observations.

It is a [R Shiny](https://shiny.rstudio.com/) website based on [EXstat](https://github.com/lou-heraut/EXstat) package with [CARD](https://github.com/lou-heraut/CARD-R) code bundle. It provides an interactive cartographic solution to analyze the hydrological stationarity of French surface flows based on the data of the hydrometric stations where the flows are little influenced by the human actions.

[<img src="https://github.com/lou-heraut/MAKAHO/blob/2f1ea7fab7c867041d707cee1bd68d5c3b3bfd04/www/screen.png" width="600">](https://makaho.sk8.inrae.fr/)

Data came from [HydroPortail](https://www.hydro.eaufrance.fr/) and the selection of stations follows the Reference Network for Low Water Monitoring (Réseau de référence pour la surveillance des étiages, [RRSE](https://geo.data.gouv.fr/en/datasets/29819c27c73f29ee1a962450da7c2d49f6e11c15) in french).

A part of the data produced by [MAKAHO](https://makaho.sk8.inrae.fr/) can be downloaded from [Recherche Data Gouv](https://doi.org/10.57745/LNBEGZ).

This project was carried out for National Research Institute for Agriculture, Food and the Environment (Institut National de Recherche pour l’Agriculture, l’Alimentation et l’Environnement, [INRAE](https://agriculture.gouv.fr/inrae-linstitut-national-de-recherche-pour-lagriculture-lalimentation-et-lenvironnement) in french).

This projet have won the [2024 Open Science Research Data Award](https://www.enseignementsup-recherche.gouv.fr/fr/remise-des-prix-science-ouverte-des-donnees-de-la-recherche-2024-98045) in the “Creating the Conditions for Reuse” category.


## Installation
If you want to visit the website hosted by the [SK8 project](https://sk8.inrae.fr/), you can go to this URL: [https://makaho.sk8.inrae.fr/](https://makaho.sk8.inrae.fr/).

If you want a local instance, you can download the latest development version using:
```
git clone https://github.com/lou-heraut/MAKAHO.git
```

The input data needed are not hosted on GitHub but can be found on [Recherche Data Gouv](https://doi.org/10.57745/1BBH2Y). This data is in a long format `dplyr::tibble` with concatenated hydrometric station data gathered from [Hydroportail](https://www.hydro.eaufrance.fr/). There is a file named `script_create.R` that can help you format such a data table using the [ASHE](https://github.com/lou-heraut/ASHE) package.

The local personalized instance has not been properly tested yet but can be a potential area for future improvement!


## Help
You can find an interactive help on the website if you press the bottom right interrogation button.


## FAQ
📬 — **I would like an upgrade / I have a question / Need to reach me**  
Feel free to [open an issue](https://github.com/lou-heraut/MAKAHO/issues) ! I’m actively maintaining this project, so I’ll do my best to respond quickly.  
I’m also reachable on my institutional INRAE [email](mailto:louis.heraut@inrae.fr?subject=%5BMAKAHO%5D) for more in-depth discussions.

🛠️ — **I found a bug**  
- *Good Solution* : Search the existing issue list, and if no one has reported it, create a new issue !  
- *Better Solution* : Along with the issue submission, provide a minimal reproducible code sample.  
- *Best Solution* : Fix the issue and submit a pull request. This is the fastest way to get a bug fixed.

🚀 — **Want to contribute ?**  
If you don't know where to start, [open an issue](https://github.com/lou-heraut/MAKAHO/issues).

If you want to try by yourself, why not start by also [opening an issue](https://github.com/lou-heraut/MAKAHO/issues) to let me know you're working on something ? Then:

- Fork this repository  
- Clone your fork locally and make changes (or even better, create a new branch for your modifications)
- Push to your fork and verify everything works as expected
- Open a Pull Request on GitHub and describe what you did and why
- Wait for review
- For future development, keep your fork updated using the GitHub “Sync fork” functionality or by pulling changes from the original repo (or even via remote upstream if you're comfortable with Git). Otherwise, feel free to delete your fork to keep things tidy ! 

If we’re connected through work, why not reach out via email to see if we can collaborate more closely on this repo by adding you as a collaborator !


## Code of Conduct
Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.
