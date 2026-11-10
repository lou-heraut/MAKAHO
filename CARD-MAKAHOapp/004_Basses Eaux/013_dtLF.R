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
CARD$P.variable_en = "dtLF"
CARD$P.unit_en = "day"
CARD$P.name_en = "Duration of low flows"
CARD$P.description_en = "Duration of the longest continuous sequence with 10-day mean flows below the threshold set at the maximum of VCN10"
CARD$P.method_en = "1. no temporal aggregation - 10-day centered moving average
2. annual aggregation [Month of maximum monthly flows] - minimum (extraction from the series of VCN10)
3. no temporal aggregation - the maximum of the previous series is taken as the threshold
4. annual aggregation [Month of maximum monthly flows] - number of days in the longest period below the previous threshold"
CARD$P.sampling_period_en = "Month of maximum monthly flows"
CARD$P.topic_en = "Flow, Low Flows, Duration"

### French ___________________________________________________________
CARD$P.variable_fr = "dtBE"
CARD$P.unit_fr = "jour"
CARD$P.name_fr = "Durée des basses eaux"
CARD$P.description_fr = "Durée de la plus longue séquence continue avec des débits moyens sur 10 jours sous le seuil fixé au maximum des VCN10"
CARD$P.method_fr = "1. aucune agrégation temporelle - moyenne mobile centrée sur 10 jours
2. agrégation annuelle [Mois du maximum des débits mensuels] - minimum (extraction de la série des VCN10
3. aucune agrégation temporelle - le maximum de la précédente série est pris comme seuil
4. agrégation annuelle [Mois du maximum des débits mensuels] - nombre de jours de la plus longue période sous le précédent seuil"
CARD$P.sampling_period_fr = "Mois du maximum des débits mensuels"
CARD$P.topic_fr = "Débit, Basses Eaux, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.preferred_sampling_period = "01-01"
CARD$P.is_date = FALSE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#003C30 #01665E #35978F #80CDC1 #C7EAE5 #F6E8C3 #DFC27D #BF812D #8C510A #543005"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(VC10=rollmean_center)
CARD$P1.funct_args = list("Q", k=10)
CARD$P1.time_step = "none"
CARD$P1.keep = "all"

### P2 _______________________________________________________________
CARD$P2.funct = list(VCN10=minNA)
CARD$P2.funct_args = list("VC10", na.rm=TRUE)
CARD$P2.time_step = "year"
CARD$P2.sampling_period = list(max, list("Q", na.rm=TRUE))
CARD$P2.NApct_lim = 3
CARD$P2.NAyear_lim = 10
CARD$P2.keep = "all"

### P3 _______________________________________________________________
CARD$P3.funct = list(upLim=maxNA)
CARD$P3.funct_args = list("VCN10", na.rm=TRUE)
CARD$P3.time_step = "none"
CARD$P3.keep = "all"

### P4 _______________________________________________________________
CARD$P4.funct = list(dtLF=apply_threshold)
CARD$P4.funct_args = list("VC10", lim="upLim", where="<=", what="length", select="longest")
CARD$P4.time_step = "year"
CARD$P4.sampling_period = list(max, list("Q", na.rm=TRUE))
CARD$P4.NApct_lim = 3

