# Copyright 2026 Louis Héraut <louis.heraut@inrae.fr>*1
#
# *1 INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of MAKAHO.
#
# MAKAHO is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version. See the LICENSE file of this repository.

"""Les listes de stations, seule donnée locale de MAKAHO.

Une liste est un choix d'étude, pas un attribut Hub'Eau : elle se
versionne dans `station_lists/`, un code par ligne, avec sa source en
lignes `#` en tête de fichier. Le RRSE est la liste par défaut. Tout le
reste sur une station (nom, position, chronique) vient de card-api.
"""

from importlib.resources import files

DEFAULT = "rrse"


def station_list(name=DEFAULT):
    """Les codes Hub'Eau d'une liste, dans l'ordre du fichier."""
    text = files("makaho").joinpath("station_lists", f"{name}.txt") \
        .read_text(encoding="utf-8")
    return [line.strip() for line in text.splitlines()
            if line.strip() and not line.startswith("#")]
