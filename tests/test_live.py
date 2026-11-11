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
import time
from pathlib import Path

import pytest

from makaho.card_client import CardClient, Ticket
from makaho.stations import station_list
from conftest import trend_payload

pytestmark = pytest.mark.skipif(
    os.environ.get("MAKAHO_LIVE") != "1",
    reason="appelle card-api en ligne : MAKAHO_LIVE=1 (make test-live)")

STATIONS = station_list("rrse")[:2]


def _settings():
    from dotenv import dotenv_values
    env = Path(__file__).resolve().parent.parent / ".env"
    return {**dotenv_values(env), **os.environ}


@pytest.fixture(scope="module")
def settings():
    s = _settings()
    if not s.get("MAKAHO_CARD_API_URL"):
        pytest.skip("MAKAHO_CARD_API_URL absente de l'environnement et de .env")
    return s


@pytest.fixture(scope="module")
def client(settings):
    with CardClient(settings["MAKAHO_CARD_API_URL"],
                    settings.get("MAKAHO_CARD_API_KEY") or None) as c:
        yield c


def _wait_for(client, result, timeout=120):
    """Une demande partie en file : la suivre jusqu'au résultat."""
    if not isinstance(result, Ticket):
        return result
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if client.job(result.job)["status"] == "done":
            return client.job_result(result.job)
        time.sleep(5)
    pytest.fail(f"job {result.job} pas terminé en {timeout} s")


def test_le_service_publie_ses_versions_et_ses_plafonds(client):
    info = client.service()
    assert info["api_version"]
    assert "sync" in info["limits"]
    assert "stations" in info["limits"]["chronicles"]


def test_le_vocabulaire_porte_les_regimes(client):
    assert "phenomenon" in client.vocabulary()["vocabulary"]


def test_la_tendance_a_l_enveloppe_que_simulent_les_tests(client):
    real = _wait_for(client, client.trend(STATIONS, "QA"))
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


def test_la_cle_est_acceptee(client, settings):
    if not client.has_key:
        pytest.skip("pas de clé de priorité dans l'environnement ni .env")
    assert "jobs" in client.jobs()
