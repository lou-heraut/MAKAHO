"""Les listes de stations versionnées dans `src/makaho/station_lists/`."""

import re
from importlib.resources import files

from makaho.stations import station_list

# Code du référentiel Hub'Eau d'après la refonte Hydro : une lettre, neuf
# chiffres. Un ancien code Banque Hydro (huit caractères) n'y passe pas.
CODE = re.compile(r"[A-Z][0-9]{9}")


def test_le_rrse_compte_ses_228_stations_sans_doublon():
    codes = station_list("rrse")
    assert len(codes) == 228
    assert len(set(codes)) == len(codes)


def test_chaque_code_est_un_code_hub_eau():
    assert all(CODE.fullmatch(c) for c in station_list("rrse"))


def test_chaque_liste_dit_sa_source():
    for path in files("makaho").joinpath("station_lists").iterdir():
        header = [line for line in path.read_text(encoding="utf-8")
                  .splitlines() if line.startswith("#")]
        assert any("Provenance" in line for line in header), path.name
