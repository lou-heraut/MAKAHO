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
CARD$P.variable_en = "tQJXA"
CARD$P.unit_en = "yearday"
CARD$P.name_en = "Date of the annual maximum daily discharge"
CARD$P.description_en = ""
CARD$P.method_en = "1. annual aggregation [Month of minimum monthly flows] - date of maximum"
CARD$P.sampling_period_en = "Month of minimum monthly flows"
CARD$P.topic_en = "Flow, High Flows, Seasonality"

### French ___________________________________________________________
CARD$P.variable_fr = "tQJXA"
CARD$P.unit_fr = "jour de l'année"
CARD$P.name_fr = "Date du débit journalier maximal annuel"
CARD$P.description_fr = ""
CARD$P.method_fr = "1. agrégation annuelle [Mois du minimum des débits mensuels] - date du maximum"
CARD$P.sampling_period_fr = "Mois du minimum des débits mensuels"
CARD$P.topic_fr = "Débit, Hautes Eaux, Saisonnalité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.preferred_sampling_period = "09-01"
CARD$P.is_date = TRUE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#60265e #893687 #c05fbe #dba3da #edd1ec #f6ddd3 #edbaa7 #e08765 #CD5629 #8f3c1d"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(tQJXA=which.maxNA)
CARD$P1.funct_args = list("Q")
CARD$P1.time_step = "year"
CARD$P1.sampling_period = list(min, list("Q", na.rm=TRUE))
CARD$P1.is_date = TRUE
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

