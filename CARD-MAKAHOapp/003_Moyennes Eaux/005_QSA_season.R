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
CARD$P.variable_en = c("QSA_DJF", "QSA_MAM", "QSA_JJA", "QSA_SON")
CARD$P.unit_en = "m^{3}.s^{-1}"
CARD$P.name_en = c("Average daily flows for each winter",
                   "Average daily flows for each spring",
                   "Average daily flows for each summer",
                   "Average daily flows for each autumn")
CARD$P.description_en = c("Months of December, January, and February",
                          "Months of March, April, and May",
                          "Months of June, July, and August",
                          "Months of September, October, and November")
CARD$P.method_en = c("1. seasonal annual aggregation [12-01, 02-28(29)] - mean",
                     "1. seasonal annual aggregation [03-01, 05-31] - mean",
                     "1. seasonal annual aggregation [06-01, 08-31] - mean",
                     "1. seasonal annual aggregation [09-01, 11-30] - mean")
CARD$P.sampling_period_en = c("12-01, 02-28(29)",
                              "03-01, 05-31",
                              "06-01, 08-31",
                              "09-01, 11-30")
CARD$P.topic_en = "Flow, Mean Flows, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = c("QSA_DJF", "QSA_MAM", "QSA_JJA", "QSA_SON")
CARD$P.unit_fr = "m^{3}.s^{-1}"
CARD$P.name_fr = c("Moyenne des débits journaliers de chaque hiver",
                   "Moyenne des débits journaliers de chaque printemps",
                   "Moyenne des débits journaliers de chaque été",
                   "Moyenne des débits journaliers de chaque automne")
CARD$P.description_fr = c("Mois de décembre, janvier et février",
                          "Mois de mars, avril et mai",
                          "Mois de juin, juillet et août",
                          "Mois de septembre, octobre et novembre")
CARD$P.method_fr = c("1. agrégation annuelle saisonnalisé [01-12, 28(29)-02] - moyenne",
                     "1. agrégation annuelle saisonnalisé [01-03, 31-05] - moyenne",
                     "1. agrégation annuelle saisonnalisé [01-06, 31-08] - moyenne",
                     "1. agrégation annuelle saisonnalisé [01-09, 30-11] - moyenne")
CARD$P.sampling_period_fr = c("01-12, 28(29)-02",
                              "01-03, 31-05",
                              "01-06, 31-08",
                              "01-09, 30-11")
CARD$P.topic_fr = "Débit, Moyennes Eaux, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(QSA=mean)
CARD$P1.funct_args = list("Q", na.rm=TRUE)
CARD$P1.time_step = "year-season"
CARD$P1.Seasons = c("DJF", "MAM", "JJA", "SON")
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

