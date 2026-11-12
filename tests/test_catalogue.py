"""Les menus du panneau d'analyse, sur un extrait du vrai catalogue."""

import json
from pathlib import Path

import pytest

from makaho.catalogue import menus

REAL = Path(__file__).parent / "data" / "catalogue.json"


@pytest.fixture(scope="module")
def page():
    data = json.loads(REAL.read_text(encoding="utf-8"))
    return menus(data["cards"], data["vocabulary"], "QA")


def _card(page, card_id):
    for regime in page["regimes"]:
        for card in regime["cards"]:
            if card["id"] == card_id:
                return regime, card
    return None, None


def test_les_quatre_regimes_dans_l_ordre_de_la_1_0_0(page):
    assert [r["label"] for r in page["regimes"]] == [
        "Hautes Eaux", "Moyennes Eaux", "Basses Eaux", "Débit de Base"]


def test_seules_les_series_sur_le_debit_entrent(page):
    """Une fiche hors débit (ETPA), une fiche à sortie scalaire (BFI-LH,
    refusée par /v1/trend) et un paquet dont chaque variable existe en
    fiche seule (allLF) ne sont pas proposés."""
    for card_id in ("ETPA", "BFI-LH", "allLF", "allLF_summer"):
        assert _card(page, card_id) == (None, None), card_id
    regime, qa = _card(page, "QA")
    assert regime["id"] == "mean-flows"
    assert qa["label"] == "QA" and qa["variables"] is None
    assert qa["preferred_month"] == 9


def test_une_fiche_a_plusieurs_variables_est_un_seul_bouton(page):
    _, qma = _card(page, "QMA_month")
    assert (qma["label"], qma["sub"]) == ("QMA", "mois")
    assert [v["label"] for v in qma["variables"]] == [
        "janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.", "août",
        "sept.", "oct.", "nov.", "déc."]
    assert qma["preferred_month"] is None       # le curseur n'a pas d'objet
    _, qsa = _card(page, "QSA_season")
    assert [v["label"] for v in qsa["variables"]] == [
        "déc. à févr.", "mars à mai", "juin à août", "sept. à nov."]


def test_l_ete_et_l_hiver_se_choisissent_a_part(page):
    regime, summer = _card(page, "QMNA_summer")
    assert regime["id"] == "low-flows"
    assert (summer["label"], summer["season"]) == ("QMNA", "summer")
    assert [s["label"] for s in regime["seasons"]] == ["Année", "Été", "Hiver"]
    high, _ = _card(page, "QJXA")
    assert [s["id"] for s in high["seasons"]] == ["year"]


def test_les_fiches_vont_par_aspect_puis_dans_l_ordre_naturel(page):
    regime, _ = _card(page, "VCN10")
    labels = [c["label"] for c in regime["cards"] if c["season"] == "year"]
    assert labels.index("VCN3") < labels.index("VCN10") < labels.index("VCN30")
    # L'intensité avant la durée, la durée avant la saisonnalité.
    assert labels.index("VCN30") < labels.index("dtLF") < labels.index("tVCN10")


def test_les_reglages_proposes(page):
    assert page["default"] == "QA"
    assert page["levels"] == [0.01, 0.05, 0.1]
    assert page["period"] == {"first": 1900, "min_years": 30}
    assert len(page["months"]) == 12
