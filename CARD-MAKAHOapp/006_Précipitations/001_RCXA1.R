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
CARD$P.variable_en = "RCXA1"
CARD$P.unit_en = "mm"
CARD$P.name_en = "Annual maximum of daily precipitation"
CARD$P.description_en = ""
CARD$P.method_en = ""
CARD$P.sampling_period_en = "Month of minimum monthly precipitation"
CARD$P.topic_en = "Precipitations, Heavy, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = "RCXA1"
CARD$P.unit_fr = "mm"
CARD$P.name_fr = "Maximum annuel des précipitations journalières"
CARD$P.description_fr = ""
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = "Mois du minimum des précipitations mensuelles"
CARD$P.topic_fr = "Précipitations, Forte, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "R"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(RCXA1=maxNA)
CARD$P1.funct_args = list("R", na.rm=TRUE)
CARD$P1.time_step = "year"
CARD$P1.sampling_period = list(min, list("R", na.rm=TRUE))
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

