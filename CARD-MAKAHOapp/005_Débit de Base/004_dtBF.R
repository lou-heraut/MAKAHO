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
CARD$P.variable_en = "dtBF"
CARD$P.unit_en = "day"
CARD$P.name_en = "Duration of low flows"
CARD$P.description_en = "Duration between the start and end of low flows"
CARD$P.method_en = "1. annual aggregation [09-01, 08-31] - number of days between the dates when the baseflow (Wallingford) sum corresponds to 10 % and 90 % of the total sum"
CARD$P.sampling_period_en = "09-01, 08-31"
CARD$P.topic_en = "Flow, Baseflow, Duration"

### French ___________________________________________________________
CARD$P.variable_fr = "dtQB"
CARD$P.unit_fr = "jour"
CARD$P.name_fr = "Durée des écoulements lents"
CARD$P.description_fr = "Durée entre le début et la fin des écoulements lents"
CARD$P.method_fr = "1. agrégation annuelle [01-09, 31-08] - nombre de jours entre les dates auxquelles la somme du débit de base (Wallingford) correspond à 10 % et 90 % de la somme totale"
CARD$P.sampling_period_fr = "01-09, 31-08"
CARD$P.topic_fr = "Débit, Débit de Base, Durée"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.source = "TALLAKSEN, L. et H. VAN LANEN, éd. (2004). Hydrological drought. Processes and estimation methods for streamflow and groundwater. English. Developments in water science 48. Netherlands : Elsevier. ISBN : 9780444516886."
CARD$P.preferred_sampling_period = "09-01"
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = "#003C30 #01665E #35978F #80CDC1 #C7EAE5 #F6E8C3 #DFC27D #BF812D #8C510A #543005"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(dtBF=compute_tSnowmelt)
CARD$P1.funct_args = list("Q", p1=0.1, p2=0.9, method="Wal")
CARD$P1.time_step = "year"
CARD$P1.sampling_period = '09-01'
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

