# Copyright 2022-2024 Louis Héraut (louis.heraut@inrae.fr)*1,
#                     Éric Sauquet (eric.sauquet@inrae.fr)*1,
#                     Michel Lang (michel.lang@inrae.fr)*1,
#                     Jean-Philippe Vidal (jean-philippe.vidal@inrae.fr)*1,
#                     Benjamin Renard (benjamin.renard@inrae.fr)*1
#                     
# *1   INRAE, France
#
# This file is part of MAKAHO R shiny app.
#
# MAKAHO R shiny app is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# MAKAHO R shiny app is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MAKAHO R shiny app.
# If not, see <https://www.gnu.org/licenses/>.


computer = "LGA-LYP6123"

## 1. PACKAGES _______________________________________________________
### 1.1. Library _____________________________________________________
library(shiny)
library(shinyjs)
library(shinyWidgets)
library(leaflet)
library(icons)
library(dplyr)
library(stringr)
library(lubridate)
library(sf)


### 1.2. Source ______________________________________________________
#### 1.2.0. dev management ___________________________________________
dev_lib_path =
    "/home/lheraut/Documents/INRAE/projects"
if (Sys.info()["nodename"] == computer) {
    dev = TRUE
    verbose = TRUE
} else {
    dev = FALSE
    verbose = FALSE
}

#### 1.2.1. EXstat ___________________________________________________
if (dev) {
    print('Loading EXstat from local directory')
    devtools::load_all(file.path(dev_lib_path,
                                 "EXstat_project/EXstat/"))
    devtools::load_all(file.path(dev_lib_path,
                                 "CARD_project/CARD/"))
} else {
    print('Loading EXstat from package')
    library(EXstat)
    library(CARD)
}

#### 1.2.2. ASHE _____________________________________________________
if (dev) {
    print('Loading ASHE from local directory')
    devtools::load_all(file.path(dev_lib_path,
                                 "ASHE_project/ASHE/"))
} else {
    print('Loading ASHE from package')
    library(ASHE)
}

#### 1.2.3. dataSHEEP ________________________________________________
if (dev) {
    print('Loading dataSHEEP from local directory')
    devtools::load_all(file.path(dev_lib_path,
                                 "dataSHEEP_project/dataSHEEP/"))
} else {
    print('Loading dataSHEEP from package')
    library(dataSHEEP)
}


## 2. INITIALISATION _________________________________________________
# language
lg = "fr"

# Sourcing R files
source('tools.R', encoding='UTF-8')
source('settings.R', encoding='UTF-8')
source('marker_manager.R', encoding='UTF-8')

# Sourcing app
source('server.R', encoding='UTF-8')
source('ui.R', encoding='UTF-8')


# Running app local
shinyApp(ui=ui, server=server)

