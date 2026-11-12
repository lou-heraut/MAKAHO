"""L'application Flask, branchée sur un card-api simulé."""

import httpx
import pytest

from makaho import create_app
from makaho.card_client import client_from_env
from conftest import VERSIONS, trend_payload


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


# ── La tendance pour la page ─────────────────────────────────────────

def test_la_tendance_part_sur_le_rrse_au_protocole_makaho(app, fake):
    from makaho.stations import station_list
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    body = app.test_client().get("/api/trend").get_json()
    sent = fake.requests[0].url.params
    assert sent["cards"] == "QA"
    assert sent["stations"] == ",".join(station_list())
    assert sent["sampling"] == "preferred"
    assert "stations_meta" not in sent
    assert body["variable"]["id"] == "QA"
    assert body["summary"]["down"] == 2


def test_les_positions_se_demandent_une_fois(app, fake):
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    app.test_client().get("/api/trend?card=QA&positions=1")
    assert fake.requests[0].url.params["stations_meta"] == "true"


def test_une_demande_en_file_rend_son_numero(app, fake):
    fake.on("GET", "/v1/trend", (202, {"job": "abc123", "status": "queued"}))
    response = app.test_client().get("/api/trend")
    assert response.status_code == 202
    assert response.get_json()["job"] == "abc123"
    assert response.headers["Retry-After"]


def test_un_job_se_suit_jusqu_a_la_page(app, fake):
    fake.on("GET", "/v1/jobs/abc123",
            (200, {"status": "running", "progress": {"done": 1}}),
            (200, {"status": "done"}))
    fake.on("GET", "/v1/jobs/abc123/result", (200, trend_payload()))
    client = app.test_client()
    assert client.get("/api/jobs/abc123").status_code == 202
    body = client.get("/api/jobs/abc123").get_json()
    assert body["summary"]["total"] == 2


def test_un_numero_de_job_douteux_ne_part_pas(app, fake):
    response = app.test_client().get("/api/jobs/a%3Fb")
    assert response.status_code == 400
    assert response.get_json()["error"] == "invalid"
    assert fake.requests == []


def test_une_seule_fiche_part_avec_la_cle(app, fake):
    """Une liste de fiches ferait déposer un job prioritaire par visiteur :
    refusée avant de partir."""
    for card in ("QA,VCN10", "QA VCN10", "../v1", ""):
        response = app.test_client().get("/api/trend", query_string={"card": card})
        assert response.status_code == 400, card
    assert fake.requests == []


def test_une_fiche_inconnue_du_service_n_est_pas_une_faute_de_makaho(app, fake):
    """card-api répond 404 à une fiche inconnue, comme à une liste sans
    débits (il ne vérifie l'identifiant qu'après avoir lu les chroniques) :
    la page reçoit un 502, pas un 400."""
    fake.on("GET", "/v1/trend", (404, {"detail": "fiche inconnue"}))
    response = app.test_client().get("/api/trend?card=XYZ")
    assert response.status_code == 502


def test_un_job_expire_se_dit_comme_tel(app, fake):
    fake.on("GET", "/v1/jobs/abc123", (404, {"detail": "job inconnu ou expiré"}))
    response = app.test_client().get("/api/jobs/abc123")
    assert response.status_code == 502
    assert response.get_json()["error"] == "job"


def test_la_page_sert_leaflet_et_son_script_depuis_makaho(app):
    """Rien n'est chargé d'un CDN : Leaflet et le script sont servis par
    MAKAHO (static/vendor/README.md)."""
    client = app.test_client()
    html = client.get("/").get_data(as_text=True)
    for path in ("/static/vendor/leaflet-1.9.4/leaflet.js",
                 "/static/vendor/leaflet-1.9.4/leaflet.css",
                 "/static/js/makaho.js", "/static/css/makaho.css"):
        assert path in html
        assert client.get(path).status_code == 200
    assert "cdn" not in html.lower() and "unpkg" not in html.lower()


def test_les_polices_et_les_icones_viennent_de_makaho(app):
    """Les trois polices (décision 11) sont servies par MAKAHO, avec leur
    licence, et les icônes sont dans la page : rien à aller chercher
    ailleurs pour la dessiner."""
    import re

    client = app.test_client()
    css = client.get("/static/css/makaho.css").get_data(as_text=True)
    fonts = re.findall(r'url\("\.\./(vendor/[^"]+\.woff2)"\)', css)
    assert len(fonts) == 3
    for font in fonts:
        assert client.get(f"/static/{font}").status_code == 200
        folder = font.rsplit("/", 1)[0]
        assert client.get(f"/static/{folder}/LICENSE").status_code == 200
    html = client.get("/").get_data(as_text=True)
    assert 'class="logo"' in html             # le logo INRAE
    assert 'class="icon"' in html             # le bouton de recentrage
