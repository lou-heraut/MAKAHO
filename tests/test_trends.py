"""Ce que la page affiche : classes, compteurs, libellés, provenance."""

import json
from pathlib import Path

import pytest

from makaho.trends import (class_edges, class_of, for_page, unit_parts,
                           year_label)

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
    edges = for_page(real)["variables"][0]["edges"]
    assert edges[0] == pytest.approx(-bound, abs=1e-12)
    assert edges[-1] == pytest.approx(bound, abs=1e-12)
    assert len(edges) == 9                      # dix couleurs, neuf bornes


def test_les_compteurs_de_qa_sur_le_rrse(real):
    page = for_page(real)
    assert page["variables"][0]["summary"] == {"up": 2, "down": 57, "total": 228}


def test_trois_chroniques_trop_courtes_comme_dans_la_1_0_0(real):
    """La 1.0.0 entoure de jaune trois stations du RRSE sur QA (relevé
    du 2026-11-11) : le garde-fou des trente valeurs les retrouve."""
    short = [s["code"] for s in for_page(real)["variables"][0]["stations"] if s["short"]]
    assert sorted(short) == ["A919205040", "H212201001", "O347000101"]


def test_la_page_recoit_la_fiche_les_positions_et_la_provenance(real):
    page = for_page(real)
    assert page["variables"][0]["id"] == "QA"
    assert page["variables"][0]["units"]["relative"] == [["%.an", "-1"]]
    assert page["variables"][0]["units"]["bar"] == [["% par an", ""]]
    assert len(page["variables"][0]["palette"]) == 10
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
    units = page["variables"][0]["units"]
    assert units["absolute"] == [["m", "3"], [".s", "-1"], [".an", "-1"]]
    assert units["relative"] is None
    assert units["bar"] == [["m", "3"], [".s", "-1"], [" par an", ""]]
    assert [s["a"] for s in page["variables"][0]["stations"]] == [2.0, -1.0]
    assert [s["a_relative"] for s in page["variables"][0]["stations"]] == [None, None]


def test_le_verdict_dit_le_sens_seulement_s_il_est_significatif():
    rows = [{"code_station": "A", "h": True, "a": 0.5, "a_relative": 1.0},
            {"code_station": "B", "h": True, "a": -0.5, "a_relative": -1.0},
            {"code_station": "C", "h": False, "a": 0.5, "a_relative": 1.0},
            {"code_station": "D", "h": None, "a": None, "a_relative": None}]
    page = for_page(_result(rows))
    assert [s["trend"] for s in page["variables"][0]["stations"]] == ["up", "down", "none",
                                                      None]
    assert page["variables"][0]["stations"][3]["class"] is None
    assert page["variables"][0]["summary"] == {"up": 1, "down": 1, "total": 4}


def test_une_chronique_trop_courte_ne_compte_pas():
    rows = [{"code_station": "A", "h": True, "a": -0.5, "a_relative": -1.0,
             "n": 29},
            {"code_station": "B", "h": True, "a": -0.5, "a_relative": -1.0,
             "n": 30}]
    page = for_page(_result(rows))
    assert [s["short"] for s in page["variables"][0]["stations"]] == [True, False]
    assert page["variables"][0]["summary"] == {"up": 0, "down": 1, "total": 2}


def test_une_seule_fiche_par_appel():
    result = _result([])
    result["data"]["W"] = []
    with pytest.raises(ValueError, match="une fiche attendue"):
        for_page(result)


def test_une_date_derive_en_jours_par_an():
    rows = [{"code_station": "A", "h": True, "a": 0.4, "a_relative": None},
            {"code_station": "B", "h": False, "a": -0.1, "a_relative": None}]
    page = for_page(_result(rows, relative=False, unit="jour de l'année",
                            is_date=True))
    assert page["variables"][0]["units"]["absolute"] == [["jour.an", "-1"]]
    assert page["variables"][0]["units"]["bar"] == [["jours par an", ""]]


def test_l_annee_hydrologique_en_clair():
    """Une variable annuelle commence au départ fixe de la fiche
    (protocole MAKAHO), ou à celui que le panneau impose ; une variable
    saisonnière garde sa fenêtre."""
    qa = {"sampling_period_fr": "01-09, 31-08",
          "preferred_sampling_period": "09-01"}
    assert year_label(qa) == "du 01 sept. au 31 août"
    assert year_label(qa, "preferred") == "du 01 sept. au 31 août"
    assert year_label(qa, "01-01") == "du 01 janv. au 31 déc."
    assert year_label(qa, "03-01") == "du 01 mars au 28 févr."
    # Une fenêtre adaptative, décrite en mots : le départ fixe déclaré.
    qmna = {"sampling_period_fr": "Mois du maximum des débits mensuels",
            "preferred_sampling_period": "01-01"}
    assert year_label(qmna) == "du 01 janv. au 31 déc."
    summer = {"sampling_period_fr": "01-05, 30-11",
              "preferred_sampling_period": "01-01"}
    assert year_label(summer, "09-01") == "du 01 mai au 30 nov."
    winter = {"sampling_period_fr": "01-12, 28(29)-02"}
    assert year_label(winter) == "du 01 déc. au 28 févr."
    assert year_label({}) is None
    assert year_label({"sampling_period_fr": "adaptative"}) is None
    assert year_label({"sampling_period_fr": "01-13, 31-08"}) is None


def test_une_fiche_a_plusieurs_variables_les_rend_toutes():
    """QMA rend ses douze mois dans une table, que la colonne `variable`
    partage : la page reçoit une entrée par variable, dans l'ordre de
    `meta`, chacune avec ses classes et ses compteurs."""
    meta = [{"variable_en": v, "name_fr": v, "unit_fr": "", "relative": True,
             "sampling_period_fr": w,
             "palette": " ".join(f"#{i}{i}{i}" for i in range(10))}
            for v, w in (("M_jan", "01-01, 31-01"), ("M_feb", "01-02, 28(29)-02"))]
    rows = [{"code_station": "A", "variable": "M_feb", "h": True, "a": 1.0,
             "a_relative": 2.0, "n": 50},
            {"code_station": "A", "variable": "M_jan", "h": True, "a": -1.0,
             "a_relative": -2.0, "n": 50},
            {"code_station": "B", "variable": "M_jan", "h": False, "a": 0.1,
             "a_relative": 0.2, "n": 50}]
    page = for_page({"data": {"M": rows}, "meta": meta, "sampling": "preferred",
                     "stations_omitted": []})
    assert page["card"] == "M"
    assert [v["id"] for v in page["variables"]] == ["M_jan", "M_feb"]
    jan, feb = page["variables"]
    assert jan["summary"] == {"up": 0, "down": 1, "total": 2}
    assert feb["summary"] == {"up": 1, "down": 0, "total": 1}
    assert jan["sampling"] == "du 01 janv. au 31 janv."
    assert feb["sampling"] == "du 01 févr. au 28 févr."


def test_une_unite_en_morceaux_pour_la_page():
    assert unit_parts("m^{3}.s^{-1}") == [["m", "3"], [".s", "-1"]]
    assert unit_parts("m^{3}.s^{-1}.j") == [["m", "3"], [".s", "-1"], [".j", ""]]
    assert unit_parts("jour") == [["jour", ""]]
    assert unit_parts("") == []


def test_les_decimales_suivent_l_ordre_de_grandeur_des_pentes(real):
    assert for_page(real)["variables"][0]["digits"] == 2
    rows = [{"code_station": c, "h": False, "a": a, "a_relative": None}
            for c, a in (("A", -2e-4), ("B", 1e-4), ("C", 3e-4))]
    digits = for_page(_result(rows, relative=False, unit=""))["variables"][0]["digits"]
    assert 5 <= digits <= 7                 # 1e-4 lisible, pas « 0,00 »
