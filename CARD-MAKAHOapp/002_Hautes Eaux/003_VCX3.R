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
CARD$P.variable_en = "VCX3"
CARD$P.unit_en = "m^{3}.s^{-1}"
CARD$P.name_en = "Annual Maximum of the 3-day Moving Average of Daily Flows"
CARD$P.description_en = ""
CARD$P.method_en = "1. no temporal aggregation - 3-day centered moving average
2. annual aggregation [Month of minimum monthly flows] - maximum"
CARD$P.sampling_period_en = "Month of minimum monthly flows"
CARD$P.topic_en = "Flow, High Flows, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = "VCX3"
CARD$P.unit_fr = "m^{3}.s^{-1}"
CARD$P.name_fr = "Maximum annuel de la moyenne mobile sur 3 jours des débits journaliers"
CARD$P.description_fr = ""
CARD$P.method_fr = "1. aucune agrégation temporelle - moyenne mobile centrée sur 3 jours
2. agrégation annuelle [Mois du minimum des débits mensuels] - maximum"
CARD$P.sampling_period_fr = "Mois du minimum des débits mensuels"
CARD$P.topic_fr = "Débit, Hautes Eaux, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.preferred_sampling_period = "09-01"
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(VC3=rollmean_center)
CARD$P1.funct_args = list("Q", k=3)
CARD$P1.time_step = "none"
CARD$P1.keep = "all"
CARD$P1.NAyear_lim = 10

### P2 _______________________________________________________________
CARD$P2.funct = list(VCX3=maxNA)
CARD$P2.funct_args = list("VC3", na.rm=TRUE)
CARD$P2.time_step = "year"
CARD$P2.sampling_period = list(min, list("Q", na.rm=TRUE))
CARD$P2.NApct_lim = 3

