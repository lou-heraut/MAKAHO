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
CARD$P.variable_en = "dtCWDA"
CARD$P.unit_en = "day"
CARD$P.name_en = "Maximum number of consecutive rainy days in the year"
CARD$P.description_en = "Maximum number of consecutive days in the year with at least 1 mm of precipitation"
CARD$P.method_en = ""
CARD$P.sampling_period_en = "09-01, 08-31"
CARD$P.topic_en = "Precipitations, Low, Duration"

### French ___________________________________________________________
CARD$P.variable_fr = "dtCWDA"
CARD$P.unit_fr = "jour"
CARD$P.name_fr = "Nombre maximal de jours pluvieux consécutifs dans l'année"
CARD$P.description_fr = "Nombre maximal de jours consécutifs dans l'année avec au moins 1 mm de précipitation"
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = "01-09, 31-08"
CARD$P.topic_fr = "Précipitations, Faibles, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtCWDA=apply_threshold)
CARD$P1.funct_args = list("R", lim=1, where=">=", what="length", select="longest")
CARD$P1.time_step = "year"
CARD$P1.sampling_period = "09-01"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

