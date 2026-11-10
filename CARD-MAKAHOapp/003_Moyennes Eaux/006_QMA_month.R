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
CARD$P.variable_en = c("QMA_jan", "QMA_feb", "QMA_mar", "QMA_apr",
                       "QMA_may", "QMA_jun", "QMA_jul", "QMA_aug",
                       "QMA_sep", "QMA_oct", "QMA_nov", "QMA_dec")
CARD$P.unit_en = "m^{3}.s^{-1}"
CARD$P.name_en = c("Average daily discharge for each January",
                   "Average daily discharge for each February",
                   "Average daily discharge for each March",
                   "Average daily discharge for each April",
                   "Average daily discharge for each May",
                   "Average daily discharge for each June",
                   "Average daily discharge for each July",
                   "Average daily discharge for each August",
                   "Average daily discharge for each September",
                   "Average daily discharge for each October",
                   "Average daily discharge for each November",
                   "Average daily discharge for each December")
CARD$P.description_en = ""
CARD$P.method_en = ""
CARD$P.sampling_period_en = c("01-01, 01-31", "02-01, 02-28(29)", "03-01, 03-31",
                              "04-01, 04-30", "05-01, 05-31", "06-01, 06-30",
                              "07-01, 07-31", "08-01, 08-31", "09-01, 09-30",
                              "10-01, 10-31", "11-01, 11-30", "12-01, 12-31")
CARD$P.topic_en = "Flow, Mean Flows, Intensity"

### French ___________________________________________________________
CARD$P.variable_fr = c("QMA_janv", "QMA_fevr", "QMA_mars", "QMA_avril",
                       "QMA_mai", "QMA_juin", "QMA_juil", "QMA_aout",
                       "QMA_sept", "QMA_oct", "QMA_nov", "QMA_dec")
CARD$P.unit_fr = "m^{3}.s^{-1}"
CARD$P.name_fr = c("Moyenne des débits journaliers de chaque janvier",
                   "Moyenne des débits journaliers de chaque février",
                   "Moyenne des débits journaliers de chaque mars",
                   "Moyenne des débits journaliers de chaque avril",
                   "Moyenne des débits journaliers de chaque mai",
                   "Moyenne des débits journaliers de chaque juin",
                   "Moyenne des débits journaliers de chaque juillet",
                   "Moyenne des débits journaliers de chaque août",
                   "Moyenne des débits journaliers de chaque septembre",
                   "Moyenne des débits journaliers de chaque octobre",
                   "Moyenne des débits journaliers de chaque novembre",
                   "Moyenne des débits journaliers de chaque décembre")
CARD$P.description_fr = ""
CARD$P.method_fr = ""
CARD$P.sampling_period_fr = c("01-01, 31-01", "01-02, 28(29)-02", "01-03, 31-03",
                              "01-04, 30-04", "01-05, 31-05", "01-06, 30-06",
                              "01-07, 31-07", "01-08, 31-08", "01-09, 30-09",
                              "01-10, 31-10", "01-11, 30-11", "01-12, 31-12")
CARD$P.topic_fr = "Débit, Moyennes Eaux, Intensité"

### Global ___________________________________________________________
CARD$P.input_vars = "Q"
CARD$P.is_date = FALSE
CARD$P.to_normalise = TRUE
CARD$P.palette = "#452C1A #7F4A23 #B3762A #D4B86A #EFE0B0 #BCE6DB #7ACEB9 #449C93 #2A6863 #193830"


## PROCESS ___________________________________________________________
### P1 _______________________________________________________________
CARD$P1.funct = list(QMA=mean)
CARD$P1.funct_args = list("Q", na.rm=TRUE)
CARD$P1.time_step = "year-month"
CARD$P1.NApct_lim = 3
CARD$P1.NAyear_lim = 10
CARD$P1.compress = TRUE

