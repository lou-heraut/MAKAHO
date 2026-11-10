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
CARD$P.variable_en = "Q01A"
CARD$P.unit_en = "m^{3}.s^{-1}"
CARD$P.name_en = "Annual flow exceeded 1 year in 100"
CARD$P.description_en = "Annual flow with an exceedance probability of 1 % (99th percentile)"
CARD$P.method_en = "1. annual aggregation [01-01, 12-31] - quantile at the exceedance probability of 1 %"
CARD$P.sampling_period_en = "01-01, 12-31"
CARD$P.topic_en = "Flow, High Flows, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = "Q01A"
CARD$P.unit_fr = "m^{3}.s^{-1}"
CARD$P.name_fr = "Débit annuel dépassée 1 année sur 100"
CARD$P.description_fr = "Débit annuel avec une probabilité de dépassement de 1 % (centile 99 %)"
CARD$P.method_fr = "1. agrégation annuelle [01-01, 31-12] - quantile à la probabilité de dépassement de 1 %"
CARD$P.sampling_period_fr = "01-01, 31-12"
CARD$P.topic_fr = "Débit, Hautes Eaux, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.preferred_sampling_period = "01-01"
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(Q01A=compute_Qp)
CARD$P1.funct_args = list("Q", p=0.01)
CARD$P1.time_step = "year"
CARD$P1.sampling_period = "01-01"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

