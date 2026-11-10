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
CARD$P.variable_en = c("dtRMA20mm_jan", "dtRMA20mm_feb", "dtRMA20mm_mar",
                       "dtRMA20mm_apr", "dtRMA20mm_may", "dtRMA20mm_jun",
                       "dtRMA20mm_jul", "dtRMA20mm_aug", "dtRMA20mm_sep",
                       "dtRMA20mm_oct", "dtRMA20mm_nov", "dtRMA20mm_dec")
CARD$P.unit_en = "day"
CARD$P.name_en = c("Number of heavy rain days for each January",
                   "Number of heavy rain days for each February",
                   "Number of heavy rain days for each March",
                   "Number of heavy rain days for each April",
                   "Number of heavy rain days for each May",
                   "Number of heavy rain days for each June",
                   "Number of heavy rain days for each July",
                   "Number of heavy rain days for each August",
                   "Number of heavy rain days for each September",
                   "Number of heavy rain days for each October",
                   "Number of heavy rain days for each November",
                   "Number of heavy rain days for each December")
CARD$P.description_en = c("Number of days with at least 20 mm of precipitation for each January",
                          "Number of days with at least 20 mm of precipitation for each February",
                          "Number of days with at least 20 mm of precipitation for each March",
                          "Number of days with at least 20 mm of precipitation for each April",
                          "Number of days with at least 20 mm of precipitation for each May",
                          "Number of days with at least 20 mm of precipitation for each June",
                          "Number of days with at least 20 mm of precipitation for each July",
                          "Number of days with at least 20 mm of precipitation for each August",
                          "Number of days with at least 20 mm of precipitation for each September",
                          "Number of days with at least 20 mm of precipitation for each October",
                          "Number of days with at least 20 mm of precipitation for each November",
                          "Number of days with at least 20 mm of precipitation for each December")
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("01-01, 01-31", "02-01, 02-28(29)", "03-01, 03-31",
                              "04-01, 04-30", "05-01, 05-31", "06-01, 06-30",
                              "07-01, 07-31", "08-01, 08-31", "09-01, 09-30",
                              "10-01, 10-31", "11-01, 11-30", "12-01, 12-31")
CARD$P.topic_en = "Precipitations, Heavy, Duration"

### French ___________________________________________________________
CARD$P.variable_fr = c("dtRMA20mm_janv", "dtRMA20mm_fevr", "dtRMA20mm_mars",
                       "dtRMA20mm_avril", "dtRMA20mm_mai", "dtRMA20mm_juin",
                       "dtRMA20mm_juil", "dtRMA20mm_aout", "dtRMA20mm_sept",
                       "dtRMA20mm_oct", "dtRMA20mm_nov", "dtRMA20mm_dec")
CARD$P.unit_fr = "jour"
CARD$P.name_fr = c("Nombre de jours de forte pluie de chaque janvier",
                   "Nombre de jours de forte pluie de chaque février",
                   "Nombre de jours de forte pluie de chaque mars",
                   "Nombre de jours de forte pluie de chaque avril",
                   "Nombre de jours de forte pluie de chaque mai",
                   "Nombre de jours de forte pluie de chaque juin",
                   "Nombre de jours de forte pluie de chaque juillet",
                   "Nombre de jours de forte pluie de chaque août",
                   "Nombre de jours de forte pluie de chaque septembre",
                   "Nombre de jours de forte pluie de chaque octobre",
                   "Nombre de jours de forte pluie de chaque novembre",
                   "Nombre de jours de forte pluie de chaque décembre")
CARD$P.description_fr = c("Nombre de jours avec au moins 20 mm de précipitations de chaque janvier",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque février",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque mars",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque avril",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque mai",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque juin",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque juillet",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque août",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque septembre",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque octobre",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque novembre",
                          "Nombre de jours avec au moins 20 mm de précipitations de chaque décembre")
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-01, 31-01", "01-02, 28(29)-02", "01-03, 31-03",
                              "01-04, 30-04", "01-05, 31-05", "01-06, 30-06",
                              "01-07, 31-07", "01-08, 31-08", "01-09, 30-09",
                              "01-10, 31-10", "01-11, 30-11", "01-12, 31-12")
CARD$P.topic_fr = "Précipitations, Forte, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtRMA20mm=apply_threshold)
CARD$P1.funct_args = list("R", lim=20, where=">=", what="length", select="all")
CARD$P1.time_step = "year-month"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

