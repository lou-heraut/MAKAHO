#   ___                _ 
#  / __| __ _  _ _  __| |
# | (__ / _` || '_|/ _` |
#  \___|\__,_||_|  \__,_|
# Copyright 2022-2025 Louis, Héraut <louis.heraut@inrae.fr>*1
#
# *1 INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of CARD R package.
#
# CARD R package is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# CARD R package is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CARD R package.
# If not, see <https://www.gnu.org/licenses/>.


## INFO ______________________________________________________________
### English __________________________________________________________
CARD$P.variable_en = c("dtRMA01mm_jan", "dtRMA01mm_feb", "dtRMA01mm_mar",
                       "dtRMA01mm_apr", "dtRMA01mm_may", "dtRMA01mm_jun",
                       "dtRMA01mm_jul", "dtRMA01mm_aug", "dtRMA01mm_sep",
                       "dtRMA01mm_oct", "dtRMA01mm_nov", "dtRMA01mm_dec")
CARD$P.unit_en = "day"
CARD$P.name_en = c("Number of rainy days of each January",
                   "Number of rainy days of each February",
                   "Number of rainy days of each March",
                   "Number of rainy days of each April",
                   "Number of rainy days of each May",
                   "Number of rainy days of each June",
                   "Number of rainy days of each July",
                   "Number of rainy days of each August",
                   "Number of rainy days of each September",
                   "Number of rainy days of each October",
                   "Number of rainy days of each November",
                   "Number of rainy days of each December")
CARD$P.description_en = c("Number of days with at least 1 mm of precipitation of each January",
                          "Number of days with at least 1 mm of precipitation of each February",
                          "Number of days with at least 1 mm of precipitation of each March",
                          "Number of days with at least 1 mm of precipitation of each April",
                          "Number of days with at least 1 mm of precipitation of each May",
                          "Number of days with at least 1 mm of precipitation of each June",
                          "Number of days with at least 1 mm of precipitation of each July",
                          "Number of days with at least 1 mm of precipitation of each August",
                          "Number of days with at least 1 mm of precipitation of each September",
                          "Number of days with at least 1 mm of precipitation of each October",
                          "Number of days with at least 1 mm of precipitation of each November",
                          "Number of days with at least 1 mm of precipitation of each December")
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("01-01, 01-31", "02-01, 02-28(29)", "03-01, 03-31",
                              "04-01, 04-30", "05-01, 05-31", "06-01, 06-30",
                              "07-01, 07-31", "08-01, 08-31", "09-01, 09-30",
                              "10-01, 10-31", "11-01, 11-30", "12-01, 12-31")
CARD$P.topic_en = "Precipitations, Low, Duration"

### French ___________________________________________________________
CARD$P.variable_fr = c("dtRMA01mm_janv", "dtRMA01mm_fevr", "dtRMA01mm_mars",
                       "dtRMA01mm_avril", "dtRMA01mm_mai", "dtRMA01mm_juin",
                       "dtRMA01mm_juil", "dtRMA01mm_aout", "dtRMA01mm_sept",
                       "dtRMA01mm_oct", "dtRMA01mm_nov", "dtRMA01mm_dec")
CARD$P.unit_fr = "jour"
CARD$P.name_fr = c("Nombre de jours pluvieux de chaque janvier",
                   "Nombre de jours pluvieux de chaque février",
                   "Nombre de jours pluvieux de chaque mars",
                   "Nombre de jours pluvieux de chaque avril",
                   "Nombre de jours pluvieux de chaque mai",
                   "Nombre de jours pluvieux de chaque juin",
                   "Nombre de jours pluvieux de chaque juillet",
                   "Nombre de jours pluvieux de chaque août",
                   "Nombre de jours pluvieux de chaque septembre",
                   "Nombre de jours pluvieux de chaque octobre",
                   "Nombre de jours pluvieux de chaque novembre",
                   "Nombre de jours pluvieux de chaque décembre")
CARD$P.description_fr = c("Nombre de jours avec au moins 1 mm de précipitations de chaque janvier",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque février",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque mars",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque avril",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque mai",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque juin",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque juillet",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque août",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque septembre",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque octobre",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque novembre",
                          "Nombre de jours avec au moins 1 mm de précipitations de chaque décembre")
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-01, 31-01", "01-02, 28(29)-02", "01-03, 31-03",
                              "01-04, 30-04", "01-05, 31-05", "01-06, 30-06",
                              "01-07, 31-07", "01-08, 31-08", "01-09, 30-09",
                              "01-10, 31-10", "01-11, 30-11", "01-12, 31-12")
CARD$P.topic_fr = "Précipitations, Faible, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtRMA01mm=apply_threshold)
CARD$P1.funct_args = list("R", lim=1, where=">=", what="length", select="all")
CARD$P1.time_step = "year-month"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

