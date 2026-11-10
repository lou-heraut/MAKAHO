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
CARD$P.variable_en = "fQ05A"
CARD$P.unit_en = "day.year^{-1}"
CARD$P.name_en = "Annual frequency of exceeding Q05"
CARD$P.description_en = "Annual frequency of exceeding Q > Q05, where Q05 is the flow exceeded 5 % of the time, extracted from the ranked flow curve"
CARD$P.method_en = "1. no temporal aggregation - the quantile at the 5 % exceedance probability is taken as the threshold
2. annual aggregation [Month of minimum monthly flows] - ratio of the number of days with flow exceeding the threshold to the number of days in the year"
CARD$P.sampling_period_en = "Month of minimum monthly flows"
CARD$P.topic_en = "Flow, High Flows, Frequency"

### French ___________________________________________________________
CARD$P.variable_fr = "fQ05A"
CARD$P.unit_fr = "jour.an^{-1}"
CARD$P.name_fr = "Fréquence annuelle de dépassement du Q05"
CARD$P.description_fr = "Fréquence annuelle de dépassement de Q > Q05, Q05 est le débit dépassé 5 % du temps, extrait de la courbe des débits classés"
CARD$P.method_fr = "1. aucune agrégation temporelle - le quantile à la probabilité au dépassement de 5 % est pris comme seuil
2. agrégation annuelle [Mois du minimum des débits mensuels] - rapport du nombre de jours où le débit dépasse le seuil par le nombre de jours dans l’année"
CARD$P.sampling_period_fr = "Mois du minimum des débits mensuels"
CARD$P.topic_fr = "Débit, Hautes Eaux, Fréquence"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.preferred_sampling_period = "09-01"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(lowLim=compute_Qp)
CARD$P1.funct_args = list("Q", p=0.05)
CARD$P1.time_step = "none"
CARD$P1.NApct_lim = NULL
CARD$P1.NAyear_lim = 10
CARD$P1.keep = "all"

### P2 _______________________________________________________________
CARD$P2.funct = list(fQ05A=compute_fAp)
CARD$P2.funct_args = list("Q", lowLim="lowLim")
CARD$P2.time_step = "year"
CARD$P2.sampling_period = list(min, list("Q", na.rm=TRUE))
CARD$P2.NApct_lim = 3

