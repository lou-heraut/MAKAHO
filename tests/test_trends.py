"""Ce que la page affiche : classes, histogramme, résumé, provenance."""

import json
from pathlib import Path

import pytest

from makaho.trends import class_edges, class_of, for_page

REAL = Path(__file__).parent / "data" / "trend_qa_rrse.json"


@pytest.fixture(scope="module")
def real():
    """La vraie réponse du 2026-11-11, réduite (voir son `_note`)."""
    result = json.loads(REAL.read_text(encoding="utf-8"))
    result.pop("_note")
    return result


def _result(rows, relative=True, unit="m^{3}.s^{-1}", is_date=False):
    """Une réponse minimale, pour les cas que la vraie ne montre pas."""
    return {"data_fingerprint": "v2:x",
            "data": {"V": rows},
            "meta": [{"variable_en": "V", "name_fr": "Variable",
                      "unit_fr": unit, "relative": relative,
                      "is_date": is_date,
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


def test_le_resume_de_qa_sur_le_rrse(real):
    page = for_page(real)
    assert page["summary"]["up"] == 2
    assert page["summary"]["down"] == 57
    assert page["summary"]["none"] == 169
    assert page["summary"]["total"] == 228
    assert page["summary"]["median"] == pytest.approx(-0.346, abs=1e-3)
    assert sum(page["variable"]["histogram"]) == 228


def test_la_page_recoit_la_fiche_les_positions_et_la_provenance(real):
    page = for_page(real)
    assert page["variable"]["id"] == "QA"
    assert page["variable"]["unit"] == "% / an"
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
    assert page["variable"]["unit"] == "m³.s⁻¹ / an"
    assert [s["slope"] for s in page["stations"]] == [2.0, -1.0]


def test_le_verdict_dit_le_sens_seulement_s_il_est_significatif():
    rows = [{"code_station": "A", "h": True, "a": 0.5, "a_relative": 1.0},
            {"code_station": "B", "h": True, "a": -0.5, "a_relative": -1.0},
            {"code_station": "C", "h": False, "a": 0.5, "a_relative": 1.0},
            {"code_station": "D", "h": None, "a": None, "a_relative": None}]
    page = for_page(_result(rows))
    assert [s["trend"] for s in page["stations"]] == ["up", "down", "none",
                                                      None]
    assert page["stations"][3]["class"] is None
    assert page["summary"]["total"] == 4
    assert sum(page["variable"]["histogram"]) == 3


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
    assert page["variable"]["unit"] == "jours / an"


def test_les_decimales_suivent_l_ordre_de_grandeur_des_pentes(real):
    assert for_page(real)["variable"]["digits"] == 2
    rows = [{"code_station": c, "h": False, "a": a, "a_relative": None}
            for c, a in (("A", -2e-4), ("B", 1e-4), ("C", 3e-4))]
    digits = for_page(_result(rows, relative=False, unit=""))["variable"]["digits"]
    assert 5 <= digits <= 7                 # 1e-4 lisible, pas « 0,00 »
