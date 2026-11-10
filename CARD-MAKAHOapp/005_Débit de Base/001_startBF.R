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
CARD$P.variable_en = "startBF"
CARD$P.unit_en = "yearday"
CARD$P.name_en = "Start of low flows"
CARD$P.description_en = "Date when 10 % of the annual cumulative baseflow is reached"
CARD$P.method_en = "1. annual aggregation [09-01, 08-31] - date when the baseflow (Wallingford) sum corresponds to 10 % of the total sum"
CARD$P.sampling_period_en = "09-01, 08-31"
CARD$P.topic_en = "Flow, Baseflow, Seasonality"

### French ___________________________________________________________
CARD$P.variable_fr = "debutQB"
CARD$P.unit_fr = "jour de l'année"
CARD$P.name_fr = "Début des écoulements lents"
CARD$P.description_fr = "Date à laquelle 10 % du cumul annuel du débit de base sont atteints"
CARD$P.method_fr = "1. agrégation annuelle [01-09, 31-08] - date à laquelle la somme du débit de base (Wallingford) correspond à 10 % de la somme totale"
CARD$P.sampling_period_fr = "01-09, 31-08"
CARD$P.topic_fr = "Débit, Débit de Base, Saisonnalité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.source = "TALLAKSEN, L. et H. VAN LANEN, éd. (2004). Hydrological drought. Processes and estimation methods for streamflow and groundwater. English. Developments in water science 48. Netherlands : Elsevier. ISBN : 9780444516886."
CARD$P.preferred_sampling_period = "09-01"
CARD$P.is_date = TRUE
CARD$P.to_normalise = FALSE
CARD$P.palette = "#60265e #893687 #c05fbe #dba3da #edd1ec #f6ddd3 #edbaa7 #e08765 #CD5629 #8f3c1d"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(startBF=compute_tVolSnowmelt)
CARD$P1.funct_args = list("Q", p=0.1, method="Wal")
CARD$P1.time_step = "year"
CARD$P1.sampling_period = '09-01'
CARD$P1.is_date = TRUE
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10

