"""L'application Flask, branchée sur un card-api simulé."""

import httpx
import pytest

from makaho import create_app
from makaho.card_client import client_from_env
from conftest import VERSIONS


def test_la_page_s_ouvre(app):
    response = app.test_client().get("/")
    assert response.status_code == 200
    assert "MAKAHO" in response.get_data(as_text=True)


def test_le_service_est_relaye(app, fake):
    fake.on("GET", "/v1", (200, {**VERSIONS, "limits": {"sync": {}}}))
    body = app.test_client().get("/api/service").get_json()
    assert body["card_swhid"] == VERSIONS["card_swhid"]
    assert "limits" in body


def test_un_refus_du_service_devient_un_502_explique(app, fake):
    fake.on("GET", "/v1",
            (503, {"detail": "file pleine"}, {"Retry-After": "300"}))
    response = app.test_client().get("/api/service")
    assert response.status_code == 502
    assert response.headers["Retry-After"] == "300"
    assert response.get_json() == {"error": "busy", "detail": "file pleine"}


def test_un_service_injoignable_devient_un_502(app, fake):
    fake.on("GET", "/v1", httpx.ConnectError("refusée"))
    response = app.test_client().get("/api/service")
    assert response.status_code == 502
    assert response.get_json()["error"] == "unreachable"


def test_l_adresse_du_service_est_requise(monkeypatch):
    monkeypatch.delenv("MAKAHO_CARD_API_URL", raising=False)
    with pytest.raises(RuntimeError, match="MAKAHO_CARD_API_URL"):
        create_app()


def test_l_environnement_regle_le_client():
    client = client_from_env({"MAKAHO_CARD_API_URL": "https://exemple.test",
                              "MAKAHO_CARD_API_KEY": "k"})
    assert client.has_key
    assert str(client._http.base_url) == "https://exemple.test"
    assert not client_from_env({"MAKAHO_CARD_API_URL": "https://exemple.test",
                                "MAKAHO_CARD_API_KEY": ""}).has_key
