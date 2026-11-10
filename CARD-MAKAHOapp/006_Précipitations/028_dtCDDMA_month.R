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
CARD$P.variable_en = c("dtCDDMA_jan", "dtCDDMA_feb", "dtCDDMA_mar",
                       "dtCDDMA_apr", "dtCDDMA_may", "dtCDDMA_jun",
                       "dtCDDMA_jul", "dtCDDMA_aug", "dtCDDMA_sep",
                       "dtCDDMA_oct", "dtCDDMA_nov", "dtCDDMA_dec")
CARD$P.unit_en = "day"
CARD$P.name_en = c("Maximum number of consecutive dry days in each January",
                   "Maximum number of consecutive dry days in each February",
                   "Maximum number of consecutive dry days in each March",
                   "Maximum number of consecutive dry days in each April",
                   "Maximum number of consecutive dry days in each May",
                   "Maximum number of consecutive dry days in each June",
                   "Maximum number of consecutive dry days in each July",
                   "Maximum number of consecutive dry days in each August",
                   "Maximum number of consecutive dry days in each September",
                   "Maximum number of consecutive dry days in each October",
                   "Maximum number of consecutive dry days in each November",
                   "Maximum number of consecutive dry days in each December")
CARD$P.description_en = c("Maximum number of consecutive days with less than 1 mm of precipitation in each January",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each February",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each March",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each April",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each May",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each June",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each July",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each August",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each September",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each October",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each November",
                          "Maximum number of consecutive days with less than 1 mm of precipitation in each December")
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("01-01, 01-31", "02-01, 02-28(29)", "03-01, 03-31",
                              "04-01, 04-30", "05-01, 05-31", "06-01, 06-30",
                              "07-01, 07-31", "08-01, 08-31", "09-01, 09-30",
                              "10-01, 10-31", "11-01, 11-30", "12-01, 12-31")
CARD$P.topic_en = "Precipitations, Dry Period, Duration"


### French ___________________________________________________________
CARD$P.variable_fr = c("dtCDDMA_janv", "dtCDDMA_fevr", "dtCDDMA_mars",
                       "dtCDDMA_avril", "dtCDDMA_mai", "dtCDDMA_juin",
                       "dtCDDMA_juil", "dtCDDMA_aout", "dtCDDMA_sept",
                       "dtCDDMA_oct", "dtCDDMA_nov", "dtCDDMA_dec")
CARD$P.unit_fr = "jour"
CARD$P.name_fr = c("Nombre maximal de jours secs consécutifs de chaque janvier",
                   "Nombre maximal de jours secs consécutifs de chaque février",
                   "Nombre maximal de jours secs consécutifs de chaque mars",
                   "Nombre maximal de jours secs consécutifs de chaque avril",
                   "Nombre maximal de jours secs consécutifs de chaque mai",
                   "Nombre maximal de jours secs consécutifs de chaque juin",
                   "Nombre maximal de jours secs consécutifs de chaque juillet",
                   "Nombre maximal de jours secs consécutifs de chaque août",
                   "Nombre maximal de jours secs consécutifs de chaque septembre",
                   "Nombre maximal de jours secs consécutifs de chaque octobre",
                   "Nombre maximal de jours secs consécutifs de chaque novembre",
                   "Nombre maximal de jours secs consécutifs de chaque décembre")
CARD$P.description_fr = c("Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque janvier",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque février",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque mars",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque avril",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque mai",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque juin",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque juillet",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque août",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque septembre",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque octobre",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque novembre",
                          "Nombre maximal de jours consécutifs avec moins de 1 mm de précipitation de chaque décembre")
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-01, 31-01", "01-02, 28(29)-02", "01-03, 31-03",
                              "01-04, 30-04", "01-05, 31-05", "01-06, 30-06",
                              "01-07, 31-07", "01-08, 31-08", "01-09, 30-09",
                              "01-10, 31-10", "01-11, 30-11", "01-12, 31-12")
CARD$P.topic_fr = "Précipitations, Période sèche, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#003C30 #01665E #35978F #80CDC1 #C7EAE5 #F6E8C3 #DFC27D #BF812D #8C510A #543005"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtCDDMA=apply_threshold)
CARD$P1.funct_args = list("R", lim=1, where="<", what="length", select="longest")
CARD$P1.time_step = "year-month"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

