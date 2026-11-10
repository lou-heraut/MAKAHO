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
CARD$P.variable_en = c("RMAs_jan", "RMAs_feb", "RMAs_mar", "RMAs_apr",
                       "RMAs_may", "RMAs_jun", "RMAs_jul", "RMAs_aug",
                       "RMAs_sep", "RMAs_oct", "RMAs_nov", "RMAs_dec")
CARD$P.unit_en = "mm"
CARD$P.name_en = c("Cumulative daily solid precipitation for each January",
                   "Cumulative daily solid precipitation for each February",
                   "Cumulative daily solid precipitation for each March",
                   "Cumulative daily solid precipitation for each April",
                   "Cumulative daily solid precipitation for each May",
                   "Cumulative daily solid precipitation for each June",
                   "Cumulative daily solid precipitation for each July",
                   "Cumulative daily solid precipitation for each August",
                   "Cumulative daily solid precipitation for each September",
                   "Cumulative daily solid precipitation for each October",
                   "Cumulative daily solid precipitation for each November",
                   "Cumulative daily solid precipitation for each December")
CARD$P.description_en = ""
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("01-01, 01-31", "02-01, 02-28(29)", "03-01, 03-31",
                              "04-01, 04-30", "05-01, 05-31", "06-01, 06-30",
                              "07-01, 07-31", "08-01, 08-31", "09-01, 09-30",
                              "10-01, 10-31", "11-01, 11-30", "12-01, 12-31")
CARD$P.topic_en = "Precipitations, Moderate, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = c("RMAs_janv", "RMAs_fevr", "RMAs_mars",
                       "RMAs_avril", "RMAs_mai", "RMAs_juin",
                       "RMAs_juil", "RMAs_aout", "RMAs_sept",
                       "RMAs_oct", "RMAs_nov", "RMAs_dec")
CARD$P.unit_fr = "mm"
CARD$P.name_fr = c("Cumul des précipitations solides journalières de chaque janvier",
                   "Cumul des précipitations solides journalières de chaque février",
                   "Cumul des précipitations solides journalières de chaque mars",
                   "Cumul des précipitations solides journalières de chaque avril",
                   "Cumul des précipitations solides journalières de chaque mai",
                   "Cumul des précipitations solides journalières de chaque juin",
                   "Cumul des précipitations solides journalières de chaque juillet",
                   "Cumul des précipitations solides journalières de chaque août",
                   "Cumul des précipitations solides journalières de chaque septembre",
                   "Cumul des précipitations solides journalières de chaque octobre",
                   "Cumul des précipitations solides journalières de chaque novembre",
                   "Cumul des précipitations solides journalières de chaque décembre")
CARD$P.description_fr = ""
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-01, 31-01", "01-02, 28(29)-02", "01-03, 31-03",
                              "01-04, 30-04", "01-05, 31-05", "01-06, 30-06",
                              "01-07, 31-07", "01-08, 31-08", "01-09, 30-09",
                              "01-10, 31-10", "01-11, 30-11", "01-12, 31-12")
CARD$P.topic_fr = "Précipitations, Modérée, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "Rs"
CARD$P.is_date = FALSE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"
CARD$P.reverse_palette = FALSE


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(RMAs=sumNA)
CARD$P1.funct_args = list("Rs", na.rm=TRUE)
CARD$P1.time_step = "year-month"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

