"""Un card-api simulé, pour tester MAKAHO hors ligne.

Les réponses imitent l'enveloppe du service telle que la construit son
`pipeline.compute` (versions, droits, stations, provenance, données).
Les tests live (`test_live.py`) vérifient que l'imitation tient face au
vrai service.
"""

import httpx
import pytest

from makaho import create_app
from makaho.card_client import CardClient

BASE = "https://card-api.test"
KEY = "jeton-de-test"


class FakeCardApi:
    """Des réponses par (méthode, chemin), et le journal des requêtes.

    Une route reçoit une suite de réponses, servies dans l'ordre ; la
    dernière se répète. Une réponse est un triplet (code, corps JSON,
    en-têtes), une exception httpx à lever, ou une fonction qui reçoit la
    requête et rend la réponse.
    """

    def __init__(self):
        self.routes = {}
        self.requests = []
        self.sleeps = []

    def on(self, method, path, *responses):
        self.routes[(method, path)] = list(responses)

    def __call__(self, request):
        self.requests.append(request)
        queue = self.routes.get((request.method, request.url.path))
        if not queue:
            return httpx.Response(404, json={"detail": "route non simulée"})
        reply = queue.pop(0) if len(queue) > 1 else queue[0]
        if isinstance(reply, Exception):
            raise reply
        if callable(reply):
            return reply(request)
        status, body, headers = (tuple(reply) + (None, None))[:3]
        if body is None:
            return httpx.Response(status, headers=headers)
        return httpx.Response(status, json=body, headers=headers)

    def client(self, api_key=None, **kwargs):
        return CardClient(BASE, api_key,
                          transport=httpx.MockTransport(self),
                          sleep=self.sleeps.append, **kwargs)


VERSIONS = {
    "api_version": "0.9.1",
    "card_version": "1.0.0", "card_commit": "c" * 40,
    "card_swhid": "swh:1:rev:" + "c" * 40,
    "stase_version": "0.6.5", "stase_commit": "s" * 40,
    "stase_swhid": "swh:1:rev:" + "s" * 40,
}


def trend_payload(stations=("A1", "B2"), card="QA"):
    """Une réponse de `/v1/trend`, dans la forme `records`."""
    return {
        **VERSIONS,
        "rights": {"data": {"license": "Licence Ouverte / Etalab 2.0"}},
        "stations": list(stations),
        "stations_requested": list(stations),
        "stations_omitted": [],
        "cards": [card],
        "period": {"start": "1968-01-01", "end": None},
        "sampling": "preferred",
        "source": "Hub'Eau hydrométrie",
        "data_fetched_at": "2026-11-01T03:00:00Z",
        "data_fingerprint": "v2:0123456789abcdef",
        "orient": "records",
        "meta": [{"variable_en": card, "name_fr": "Débit moyen annuel",
                  "unit_fr": "m^{3}.s^{-1}", "relative": True,
                  "palette": " ".join(["#000000"] * 10)}],
        "data": {card: [{"code_station": s, "h": True, "p": 0.01,
                         "a": -0.5, "a_relative": -1.2, "n": 50}
                        for s in stations]},
        "mk": "AR1",
        "level": 0.1,
    }


@pytest.fixture
def fake():
    return FakeCardApi()


@pytest.fixture
def app(fake):
    return create_app(client=fake.client(KEY))
