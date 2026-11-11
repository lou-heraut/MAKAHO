"""Le client de card-api, contre un service simulé.

Chaque test tient une règle que le service impose au client
(`dev/decisions.md`, « Ce que card-api impose au client ») ou un choix
du client lui-même (docstring de `makaho/card_client.py`).
"""

import httpx
import pytest

from makaho.card_client import CardApiError, Ticket
from conftest import KEY, VERSIONS, trend_payload


# ── La clé ───────────────────────────────────────────────────────────

def test_la_cle_part_en_entete_jamais_dans_l_url(fake):
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    fake.client(KEY).trend(["A1", "B2"], "QA")
    request = fake.requests[0]
    assert request.headers["X-API-Key"] == KEY
    assert KEY not in str(request.url)


def test_sans_cle_aucun_entete(fake):
    fake.on("GET", "/v1", (200, VERSIONS))
    client = fake.client()
    client.service()
    assert "X-API-Key" not in fake.requests[0].headers
    assert client.has_key is False


def test_une_cle_refusee_se_dit(fake):
    fake.on("GET", "/v1/jobs", (401, {"detail": "clé inconnue"}))
    with pytest.raises(CardApiError) as e:
        fake.client(KEY).jobs()
    assert e.value.status == 401


# ── Ce qui part, et ce qui ne part pas ───────────────────────────────

def test_le_protocole_makaho_part_explicitement(fake):
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    fake.client().trend(["A1"], "QA")
    assert fake.requests[0].url.params["sampling"] == "preferred"


def test_les_defauts_du_service_ne_sont_pas_recopies(fake):
    """mk, level et start sont ceux du service tant qu'on ne les donne
    pas : le client n'en tient pas de seconde copie."""
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    fake.client().trend(["A1"], "QA")
    sent = fake.requests[0].url.params
    for name in ("mk", "level", "start", "end", "max_age", "series",
                 "stations_meta", "orient"):
        assert name not in sent


def test_les_reglages_donnes_partent(fake):
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    fake.client().trend(["A1"], ["QA"], start="1970-01-01", level=0.05,
                        mk="INDE", series=True)
    sent = fake.requests[0].url.params
    assert sent["start"] == "1970-01-01"
    assert sent["level"] == "0.05"
    assert sent["mk"] == "INDE"
    assert sent["series"] == "true"


def test_les_listes_partent_separees_par_des_virgules(fake):
    fake.on("GET", "/v1/trend", (200, trend_payload()))
    fake.client().trend(["A1", "B2", "C3"], ["QA", "VCN10"])
    sent = fake.requests[0].url.params
    assert sent["stations"] == "A1,B2,C3"
    assert sent["cards"] == "QA,VCN10"


def test_les_facettes_du_catalogue_sont_transmises(fake):
    fake.on("GET", "/v1/cards", (200, {"cards": []}))
    fake.client().cards(phenomenon="low-flows")
    assert fake.requests[0].url.params["phenomenon"] == "low-flows"


# ── Ce qui revient ───────────────────────────────────────────────────

def test_la_reponse_revient_entiere_avec_sa_provenance(fake):
    payload = trend_payload()
    fake.on("GET", "/v1/trend", (200, payload))
    assert fake.client().trend(["A1", "B2"], "QA") == payload


def test_une_demande_en_file_rend_un_ticket(fake):
    fake.on("GET", "/v1/trend", (202, {
        "job": "j-123", "status": "queued",
        "status_url": "/v1/jobs/j-123",
        "result_url": "/v1/jobs/j-123/result"},
        {"Location": "/v1/jobs/j-123"}))
    assert fake.client().trend(["A1"], "QA") == Ticket("j-123", "queued")


def test_le_suivi_d_un_job(fake):
    fake.on("GET", "/v1/jobs/j-123", (200, {"job": "j-123",
                                           "status": "done"}))
    fake.on("GET", "/v1/jobs/j-123/result", (200, trend_payload()))
    fake.on("DELETE", "/v1/jobs/j-123", (204,))
    client = fake.client()
    assert client.job("j-123")["status"] == "done"
    assert client.job_result("j-123")["data_fingerprint"]
    assert client.cancel_job("j-123") is None


def test_la_chronique(fake):
    fake.on("GET", "/v1/chronicles", (200, {**VERSIONS, "data": []}))
    fake.client().chronicles("A1", start="2000-01-01")
    sent = fake.requests[0].url.params
    assert sent["stations"] == "A1"
    assert sent["start"] == "2000-01-01"


# ── Attendre un job ──────────────────────────────────────────────────

def test_attendre_une_reponse_deja_la_ne_coute_rien(fake):
    payload = trend_payload()
    assert fake.client().wait(payload) is payload
    assert fake.requests == []


def test_attendre_un_job_au_rythme_que_le_service_annonce(fake):
    """card-api dit quand repasser (`Retry-After`) ; sans cette
    indication, l'intervalle par défaut."""
    fake.on("GET", "/v1/jobs/j-1",
            (200, {"status": "queued"}, {"Retry-After": "10"}),
            (200, {"status": "running"}),
            (200, {"status": "done"}))
    fake.on("GET", "/v1/jobs/j-1/result", (200, trend_payload()))
    client = fake.client()
    assert client.wait(Ticket("j-1", "queued"), interval=3)["data"]
    assert fake.sleeps == [10.0, 3]


def test_un_job_en_echec_remonte_le_refus_du_service(fake):
    fake.on("GET", "/v1/jobs/j-1", (200, {"status": "failed"}))
    fake.on("GET", "/v1/jobs/j-1/result",
            (409, {"detail": "job en échec : Hub'Eau"}))
    with pytest.raises(CardApiError) as e:
        fake.client().wait("j-1")
    assert e.value.status == 409


def test_attendre_trop_longtemps_rend_la_main(fake):
    """Le dernier relevé tombe à l'échéance, sans attente inutile après."""
    fake.on("GET", "/v1/jobs/j-1",
            (200, {"status": "running"}, {"Retry-After": "10"}))
    with pytest.raises(CardApiError, match="toujours running") as e:
        fake.client().wait("j-1", timeout=20)
    assert e.value.kind == "timeout"
    assert fake.sleeps == [10.0, 10.0]
    assert len(fake.requests) == 3
    assert all(r.method == "GET" for r in fake.requests)


# ── Les refus ────────────────────────────────────────────────────────

def test_un_refus_garde_le_code_et_l_explication(fake):
    detail = [{"type": "extra_forbidden", "loc": ["query", "samplng"]}]
    fake.on("GET", "/v1/trend", (422, {"detail": detail}))
    with pytest.raises(CardApiError) as e:
        fake.client().trend(["A1"], "QA")
    assert e.value.status == 422
    assert e.value.detail == detail


@pytest.mark.parametrize("status,kind", [
    (401, "key"), (404, "no_data"), (409, "job"), (422, "invalid"),
    (429, "busy"), (503, "busy"), (504, "source"), (500, "error")])
def test_un_refus_dit_ce_qu_il_veut_dire_sans_code_http(fake, status, kind):
    """Le reste de MAKAHO lit `kind`, jamais le code du service."""
    fake.on("GET", "/v1", (status, {"detail": "refus"}))
    with pytest.raises(CardApiError) as e:
        fake.client(retries=0).service()
    assert e.value.kind == kind


def test_un_service_injoignable_se_dit(fake):
    fake.on("GET", "/v1", httpx.ConnectError("refusée"))
    with pytest.raises(CardApiError) as e:
        fake.client(retries=0).service()
    assert e.value.kind == "unreachable"


def test_une_page_du_frontal_ne_casse_pas_le_refus(fake):
    def apache(request):
        return httpx.Response(500, text="<html>Internal Server Error</html>")
    fake.on("GET", "/v1", apache)
    with pytest.raises(CardApiError) as e:
        fake.client().service()
    assert e.value.status == 500
    assert "Internal Server Error" in e.value.detail


# ── Les reprises ─────────────────────────────────────────────────────

def test_un_quota_a_attente_courte_est_rejoue(fake):
    fake.on("GET", "/v1/trend",
            (429, {"detail": "quota"}, {"Retry-After": "2"}),
            (200, trend_payload()))
    assert fake.client().trend(["A1"], "QA")["data"]
    assert fake.sleeps == [2.0]
    assert len(fake.requests) == 2


def test_une_attente_longue_n_est_pas_subie(fake):
    """Une file pleine (503) annonce cinq minutes : une page ne les
    attend pas, le refus remonte avec l'attente annoncée."""
    fake.on("GET", "/v1/trend",
            (503, {"detail": "file pleine"}, {"Retry-After": "300"}))
    with pytest.raises(CardApiError) as e:
        fake.client().trend(["A1"], "QA")
    assert e.value.status == 503
    assert e.value.retry_after == 300
    assert fake.sleeps == []
    assert len(fake.requests) == 1


def test_un_502_du_frontal_n_est_pas_rejoue(fake):
    """Un 502 arrive aussi quand le service tombe en plein calcul : le
    rejouer relancerait ce calcul."""
    fake.on("GET", "/v1/trend", (502, None), (200, trend_payload()))
    with pytest.raises(CardApiError) as e:
        fake.client().trend(["A1"], "QA")
    assert e.value.status == 502
    assert len(fake.requests) == 1
    assert fake.sleeps == []


def test_une_connexion_impossible_est_rejouee_puis_remonte(fake):
    fake.on("GET", "/v1", httpx.ConnectError("refusée"))
    with pytest.raises(CardApiError) as e:
        fake.client(retries=2).service()
    assert e.value.status is None
    assert len(fake.requests) == 3
    assert fake.sleeps == [1.0, 2.0]


def test_un_delai_de_lecture_n_est_jamais_rejoue(fake):
    """Le service n'annule pas un calcul quand le client part : rejouer
    doublerait la charge."""
    fake.on("GET", "/v1/trend", httpx.ReadTimeout("trop long"))
    with pytest.raises(CardApiError) as e:
        fake.client().trend(["A1"], "QA")
    assert e.value.status is None
    assert len(fake.requests) == 1
    assert fake.sleeps == []


def test_une_erreur_de_calcul_n_est_pas_rejouee(fake):
    fake.on("GET", "/v1/trend", (504, {"detail": "Hub'Eau ne répond pas"},
                                 {"Retry-After": "300"}))
    with pytest.raises(CardApiError) as e:
        fake.client().trend(["A1"], "QA")
    assert e.value.status == 504
    assert len(fake.requests) == 1
