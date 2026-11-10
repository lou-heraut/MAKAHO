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
CARD$P.variable_en = c("dtCDDSA_DJF", "dtCDDSA_MAM",
                       "dtCDDSA_JJA", "dtCDDSA_SON")
CARD$P.unit_en = "day"
CARD$P.name_en = c("Maximum number of consecutive dry days in winter",
                   "Maximum number of consecutive dry days in spring",
                   "Maximum number of consecutive dry days in summer",
                   "Maximum number of consecutive dry days in autumn")
CARD$P.description_en = c("Maximum number of consecutive days in winter with less than 1 mm of precipitation (months of December, January, and February)",
                          "Maximum number of consecutive days in spring with less than 1 mm of precipitation (months of March, April, and May)",
                          "Maximum number of consecutive days in summer with less than 1 mm of precipitation (months of June, July, and August)",
                          "Maximum number of consecutive days in autumn with less than 1 mm of precipitation (months of September, October, and November)")
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("12-01, 02-28(29)",
                              "03-01, 05-31",
                              "06-01, 08-31",
                              "09-01, 11-30")
CARD$P.topic_en = "Precipitations, Dry Period, Duration"


### French ___________________________________________________________
CARD$P.variable_fr = c("dtCDDSA_DJF", "dtCDDSA_MAM",
                       "dtCDDSA_JJA", "dtCDDSA_SON")
CARD$P.unit_fr = "jour"
CARD$P.name_fr = c("Nombre maximal de jours secs consécutifs dans l'hiver",
                   "Nombre maximal de jours secs consécutifs au printemps",
                   "Nombre maximal de jours secs consécutifs en été",
                   "Nombre maximal de jours secs consécutifs en automne")
CARD$P.description_fr = c("Nombre maximal de jours consécutifs dans l'hiver avec moins de 1 mm de précipitation (mois de décembre, janvier et février)",
                          "Nombre maximal de jours consécutifs au printemps avec moins de 1 mm de précipitation (mois de mars, avril et mai)",
                          "Nombre maximal de jours consécutifs en été avec moins de 1 mm de précipitation (mois de juin, juillet et août)",
                          "Nombre maximal de jours consécutifs en automne avec moins de 1 mm de précipitation (mois de septembre, octobre et novembre)")
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-12, 28(29)-02",
                              "01-03, 31-05",
                              "01-06, 31-08",
                              "01-09, 30-11")
CARD$P.topic_fr = "Précipitations, Période sèche, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#003C30 #01665E #35978F #80CDC1 #C7EAE5 #F6E8C3 #DFC27D #BF812D #8C510A #543005"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtCDDSA=apply_threshold)
CARD$P1.funct_args = list("R", lim=1, where="<", what="length", select="longest")
CARD$P1.time_step = "year-season"
CARD$P1.Seasons = c("DJF", "MAM", "JJA", "SON")
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

