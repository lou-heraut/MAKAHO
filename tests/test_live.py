"""Le client contre le vrai card-api : le contrat tient-il ?

Les tests hors ligne reposent sur un service simulé. Ceux-ci vérifient
que la simulation dit vrai : que les routes, les noms de paramètres et
l'enveloppe des réponses sont ceux du service en ligne. card-api attend
qu'un client ait tourné sur son contrat pour passer en 1.0.0.

Ils ne tournent que sur demande (`make test-live`, qui pose
`MAKAHO_LIVE=1`) : ils appellent le service, et avec la clé de priorité
quand `.env` en porte une. Peu d'appels, sur deux stations du RRSE.
"""

import os
from pathlib import Path

import pytest

from makaho.card_client import client_from_env
from makaho.stations import station_list
from conftest import trend_payload

pytestmark = pytest.mark.skipif(
    os.environ.get("MAKAHO_LIVE") != "1",
    reason="appelle card-api en ligne : MAKAHO_LIVE=1 (make test-live)")

STATIONS = station_list("rrse")[:2]


@pytest.fixture(scope="module")
def client():
    """Le client réglé comme l'application : l'environnement, complété
    par `.env` (que `flask run` lit, mais pas pytest)."""
    from dotenv import dotenv_values
    env = {**dotenv_values(Path(__file__).resolve().parent.parent / ".env"),
           **os.environ}
    if not env.get("MAKAHO_CARD_API_URL"):
        pytest.skip("MAKAHO_CARD_API_URL absente de l'environnement et de .env")
    with client_from_env(env) as c:
        yield c


def test_le_service_publie_ses_versions_et_ses_plafonds(client):
    info = client.service()
    assert info["api_version"]
    assert "sync" in info["limits"]
    assert "stations" in info["limits"]["chronicles"]


def test_le_catalogue_se_filtre_par_les_cles_du_vocabulaire(client):
    """Les valeurs de facette sont les clés du vocabulaire (`low-flows`),
    pas ses libellés : le simulé accepte tout, seul le vrai le dit."""
    phenomena = client.vocabulary()["vocabulary"]["phenomenon"]
    key = next(iter(phenomena))
    assert client.cards(phenomenon=key)["count"] > 0


def test_la_tendance_a_l_enveloppe_que_simulent_les_tests(client):
    real = client.wait(client.trend(STATIONS, "QA"), timeout=120)
    fake = trend_payload(STATIONS)
    assert set(fake) <= set(real)
    assert real["sampling"] == "preferred"
    assert set(fake["data"]["QA"][0]) <= set(real["data"]["QA"][0])
    for key in ("card_swhid", "stase_swhid", "data_fingerprint",
                "data_fetched_at"):
        assert real[key], key


def test_la_chronique_porte_la_meme_provenance(client):
    real = client.chronicles(STATIONS[0], start="2020-01-01")
    assert real["stations"] == [STATIONS[0]]
    assert real["data_fingerprint"]
    assert real["data"]


def test_la_cle_est_acceptee(client):
    if not client.has_key:
        pytest.skip("pas de clé de priorité dans l'environnement ni .env")
    assert "jobs" in client.jobs()
