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
