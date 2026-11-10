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
CARD$P.variable_en = "TA"
CARD$P.unit_en = "°C"
CARD$P.name_en = "Annual mean temperature"
CARD$P.description_en = ""
CARD$P.method_en = ""
CARD$P.sampling_period_en = "09-01, 08-31"
CARD$P.topic_en = "Temperature, Average, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = "TA"
CARD$P.unit_fr = "°C"
CARD$P.name_fr = "Température moyenne annuelle"
CARD$P.description_fr = ""
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = "01-09, 31-08"
CARD$P.topic_fr = "Température, Moyenne, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "T"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#053061 #2166AC #4393C3 #92C5DE #D1E5F0 #FDDBC7 #F4A582 #D6604D #B2182B #67001F"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(TA=mean)
CARD$P1.funct_args = list("T", na.rm=TRUE)
CARD$P1.time_step = "year"
CARD$P1.sampling_period = "09-01"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

