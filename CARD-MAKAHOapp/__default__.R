#   ___                _ 
#  / __| __ _  _ _  __| |
# | (__ / _` || '_|/ _` |
#  \___|\__,_||_|  \__,_|
# Copyright 2022-2025 Louis,Héraut <louis.heraut@inrae.fr>*1
#
# *1 INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of CARD R library.
#
# CARD R library is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# CARD R library is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with CARD R library.
# If not, see <https://www.gnu.org/licenses/>.


## INFO ______________________________________________________________
### English __________________________________________________________
CARD$P.variable_en = "variable"
CARD$P.unit_en = "unit"
CARD$P.name_en = "name"
CARD$P.description_en = "description"
CARD$P.method_en = "1. 'time step' aggregation [month-day, month-day] - function"
CARD$P.sampling_period_en = NULL
CARD$P.topic_en = NULL

### French ___________________________________________________________
CARD$P.variable_fr = "variable"
CARD$P.unit_fr = "unité"
CARD$P.name_fr = "nom"
CARD$P.description_fr = "description"
CARD$P.method_fr = "1. agrégation 'pas de temps' [jour-mois, jour-mois] - fonction"
CARD$P.sampling_period_fr = NULL
CARD$P.topic_fr = NULL

### Global ___________________________________________________________
CARD$P.is_experimental = FALSE
CARD$P.input_vars = "X"
CARD$P.source = NULL
CARD$P.preferred_sampling_period = NULL
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = NULL


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = NULL
CARD$P1.funct_args = NULL
CARD$P1.time_step = "year"
CARD$P1.sampling_period = NULL
CARD$P1.period = NULL
CARD$P1.is_date = FALSE
CARD$P1.NApct_lim = NULL
CARD$P1.NAyear_lim = NULL
CARD$P1.Seasons = c("DJF", "MAM", "JJA", "SON")
CARD$P1.nameEX = "X"
CARD$P1.keep = NULL
CARD$P1.compress = FALSE
CARD$P1.expand = FALSE
