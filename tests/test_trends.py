"""Ce que la page affiche : classes, compteurs, libellés, provenance."""

import json
from pathlib import Path

import pytest

from makaho.trends import (class_edges, class_of, for_page, sampling_label,
                           unit_parts)

REAL = Path(__file__).parent / "data" / "trend_qa_rrse.json"


@pytest.fixture(scope="module")
def real():
    """La vraie réponse du 2026-11-11, réduite (voir son `_note`)."""
    result = json.loads(REAL.read_text(encoding="utf-8"))
    result.pop("_note")
    return result


def _result(rows, relative=True, unit="m^{3}.s^{-1}", is_date=False,
            sampling="01-09, 31-08"):
    """Une réponse minimale, pour les cas que la vraie ne montre pas."""
    return {"data_fingerprint": "v2:x",
            "data": {"V": rows},
            "meta": [{"variable_en": "V", "name_fr": "Variable",
                      "unit_fr": unit, "relative": relative,
                      "is_date": is_date, "sampling_period_fr": sampling,
                      "palette": " ".join(f"#{i}{i}{i}" for i in range(10))}],
            "stations_omitted": []}


# ── Sur la vraie réponse ─────────────────────────────────────────────

def test_les_bornes_sont_celles_de_stase(real):
    """MAKAHO recalcule les bornes ; elles doivent rester celles que stase
    rend pour le même ensemble de stations."""
    row = real["data"]["QA"][0]
    bound = max(abs(row["a_relative_min"]), abs(row["a_relative_max"]))
    edges = for_page(real)["variable"]["edges"]
    assert edges[0] == pytest.approx(-bound, abs=1e-12)
    assert edges[-1] == pytest.approx(bound, abs=1e-12)
    assert len(edges) == 9                      # dix couleurs, neuf bornes


def test_les_compteurs_de_qa_sur_le_rrse(real):
    page = for_page(real)
    assert page["summary"] == {"up": 2, "down": 57, "total": 228}


def test_trois_chroniques_trop_courtes_comme_dans_la_1_0_0(real):
    """La 1.0.0 entoure de jaune trois stations du RRSE sur QA (relevé
    du 2026-11-11) : le garde-fou des trente valeurs les retrouve."""
    short = [s["code"] for s in for_page(real)["stations"] if s["short"]]
    assert sorted(short) == ["A919205040", "H212201001", "O347000101"]


def test_la_page_recoit_la_fiche_les_positions_et_la_provenance(real):
    page = for_page(real)
    assert page["variable"]["id"] == "QA"
    assert page["variable"]["units"]["relative"] == [["%.an", "-1"]]
    assert page["variable"]["units"]["bar"] == [["% par an", ""]]
    assert len(page["variable"]["palette"]) == 10
    assert len(page["positions"]) == 228
    assert {"code", "name", "lon", "lat"} <= set(page["positions"][0])
    assert page["provenance"]["data_fingerprint"] == real["data_fingerprint"]
    assert page["provenance"]["sampling"] == "preferred"
    assert "data" not in page["provenance"]


# ── Les cas limites ──────────────────────────────────────────────────

def test_une_borne_appartient_a_la_classe_du_dessous():
    edges = [-1.0, 0.0, 1.0]
    assert class_of(-5, edges) == 0             # classe extrême ouverte
    assert class_of(-1.0, edges) == 0
    assert class_of(-0.5, edges) == 1
    assert class_of(0.0, edges) == 1
    assert class_of(5, edges) == 3              # classe extrême ouverte


def test_des_bornes_sans_dispersion_restent_lisibles():
    assert class_edges([], 10)[-1] == 1.0
    assert class_edges([0.0, 0.0], 10)[-1] == 1.0
    assert class_edges([-2.0], 10)[-1] == 2.0


def test_une_pente_absolue_garde_l_unite_de_la_fiche():
    rows = [{"code_station": "A", "h": True, "a": 2.0, "a_relative": None},
            {"code_station": "B", "h": False, "a": -1.0, "a_relative": None}]
    page = for_page(_result(rows, relative=False))
    units = page["variable"]["units"]
    assert units["absolute"] == [["m", "3"], [".s", "-1"], [".an", "-1"]]
    assert units["relative"] is None
    assert units["bar"] == [["m", "3"], [".s", "-1"], [" par an", ""]]
    assert [s["a"] for s in page["stations"]] == [2.0, -1.0]
    assert [s["a_relative"] for s in page["stations"]] == [None, None]


def test_le_verdict_dit_le_sens_seulement_s_il_est_significatif():
    rows = [{"code_station": "A", "h": True, "a": 0.5, "a_relative": 1.0},
            {"code_station": "B", "h": True, "a": -0.5, "a_relative": -1.0},
            {"code_station": "C", "h": False, "a": 0.5, "a_relative": 1.0},
            {"code_station": "D", "h": None, "a": None, "a_relative": None}]
    page = for_page(_result(rows))
    assert [s["trend"] for s in page["stations"]] == ["up", "down", "none",
                                                      None]
    assert page["stations"][3]["class"] is None
    assert page["summary"] == {"up": 1, "down": 1, "total": 4}


def test_une_chronique_trop_courte_ne_compte_pas():
    rows = [{"code_station": "A", "h": True, "a": -0.5, "a_relative": -1.0,
             "n": 29},
            {"code_station": "B", "h": True, "a": -0.5, "a_relative": -1.0,
             "n": 30}]
    page = for_page(_result(rows))
    assert [s["short"] for s in page["stations"]] == [True, False]
    assert page["summary"] == {"up": 0, "down": 1, "total": 2}


def test_une_seule_variable_par_appel():
    result = _result([])
    result["data"]["W"] = []
    with pytest.raises(ValueError, match="une variable attendue"):
        for_page(result)


def test_une_date_derive_en_jours_par_an():
    rows = [{"code_station": "A", "h": True, "a": 0.4, "a_relative": None},
            {"code_station": "B", "h": False, "a": -0.1, "a_relative": None}]
    page = for_page(_result(rows, relative=False, unit="jour de l'année",
                            is_date=True))
    assert page["variable"]["units"]["absolute"] == [["jour.an", "-1"]]
    assert page["variable"]["units"]["bar"] == [["jours par an", ""]]


def test_l_annee_hydrologique_en_clair():
    assert sampling_label("01-09, 31-08") == "du 01 sept. au 31 août"
    assert sampling_label("01-01, 31-12") == "du 01 janv. au 31 déc."
    assert sampling_label(None) is None
    assert sampling_label("adaptative") is None
    assert sampling_label("01-13, 31-08") is None


def test_une_unite_en_morceaux_pour_la_page():
    assert unit_parts("m^{3}.s^{-1}") == [["m", "3"], [".s", "-1"]]
    assert unit_parts("m^{3}.s^{-1}.j") == [["m", "3"], [".s", "-1"], [".j", ""]]
    assert unit_parts("jour") == [["jour", ""]]
    assert unit_parts("") == []


def test_les_decimales_suivent_l_ordre_de_grandeur_des_pentes(real):
    assert for_page(real)["variable"]["digits"] == 2
    rows = [{"code_station": c, "h": False, "a": a, "a_relative": None}
            for c, a in (("A", -2e-4), ("B", 1e-4), ("C", 3e-4))]
    digits = for_page(_result(rows, relative=False, unit=""))["variable"]["digits"]
    assert 5 <= digits <= 7                 # 1e-4 lisible, pas « 0,00 »
