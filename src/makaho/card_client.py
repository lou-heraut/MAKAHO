# Copyright 2026 Louis Héraut <louis.heraut@inrae.fr>*1
#
# *1 INRAE, UR RiverLy, Villeurbanne, France
#
# This file is part of MAKAHO.
#
# MAKAHO is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version. See the LICENSE file of this repository.

"""Le seul module de MAKAHO qui connaisse card-api.

Tout le contenu scientifique de MAKAHO vient du service (décision 2 de
`dev/decisions.md`) : le catalogue des fiches, les stations, les
chroniques, les tendances. Ce module est la frontière qui rend ce choix
réversible (décision 3) : si un jour les séries doivent venir d'ailleurs,
c'est ici seulement que cela change. Aucun autre module ne construit
d'URL de card-api ni ne lit ses codes HTTP.

Ce que le service impose, et que ce module respecte (détail dans
`dev/decisions.md`, « Ce que card-api impose au client ») :

- la clé de priorité part dans l'en-tête `X-API-Key`, jamais dans l'URL ;
- un paramètre inconnu est refusé (422) : les méthodes n'envoient que des
  noms déclarés, et une faute de frappe se voit au premier appel ;
- le protocole MAKAHO est `sampling=preferred`, envoyé explicitement :
  sans lui, une fiche à fenêtre adaptative ne rend pas la même série ;
- les autres défauts (`mk`, `level`, `start`) sont ceux du service : ils
  ne partent que si l'appelant les donne, pour ne pas en tenir ici une
  seconde copie qui divergerait ;
- une demande trop grosse part en file de calcul (202) : la méthode rend
  alors un `Ticket`, que l'appelant suit avec `job` ;
- aucun plafond n'est écrit ici : ils se lisent dans `/v1`, bloc `limits`.

Les réponses sont rendues telles que le service les donne, enveloppe
comprise : leur provenance (versions, SWHID, date et empreinte des
données) voyage avec elles jusqu'à l'interface.
"""

import logging
import os
import re
import time
from dataclasses import dataclass
from importlib.metadata import PackageNotFoundError, version

import httpx

log = logging.getLogger(__name__)

try:
    _VERSION = version("makaho")
except PackageNotFoundError:            # lancé depuis les sources
    _VERSION = "dev"

USER_AGENT = f"MAKAHO/{_VERSION} (+https://github.com/lou-heraut/MAKAHO)"

# Le délai de lecture couvre un calcul long : une fiche d'étiage sur tout
# le RRSE dépasse la demi-minute (mesures dans `dev/decisions.md`). La
# connexion, elle, échoue vite ou pas du tout.
TIMEOUT = httpx.Timeout(120.0, connect=5.0)

# Les reprises. On ne rejoue qu'une demande dont on sait qu'elle n'a rien
# calculé : connexion impossible, refus de quota ou service saturé (429,
# 503), que card-api oppose avant tout calcul, quand l'attente annoncée
# est courte. Jamais un délai de lecture dépassé : le service n'annule pas
# un calcul quand le client s'en va, et le rejouer doublerait une charge
# que tous les usagers partagent. Pas non plus un 502 du frontal : il
# arrive aussi quand le service tombe en plein calcul, et le rejouer
# relancerait ce calcul (revue du 2026-11-11).
RETRY_STATUSES = frozenset({429, 503})

# Ce qu'un refus veut dire pour MAKAHO, sans code HTTP : le reste de
# l'application lit `CardApiError.kind`, jamais `status`, pour que les
# codes du service restent dans ce module (décision 3).
_KINDS = {
    401: "key",          # clé de priorité refusée : à régler côté serveur
    403: "key",
    404: "no_data",      # aucune station demandée n'a de série
    409: "job",          # job en échec, pas fini, ou expiré
    422: "invalid",      # paramètre refusé : une faute dans MAKAHO
    429: "busy",         # quota ou file pleine : réessayer plus tard
    503: "busy",
    504: "source",       # Hub'Eau ne répond pas
}


class CardApiError(Exception):
    """Une demande que card-api a refusée, ou qui ne l'a pas atteint.

    `kind` dit ce que cela veut dire pour MAKAHO : `unreachable` si le
    service n'a pas répondu, `timeout` si un job a trop tardé (`wait`),
    sinon une valeur de `_KINDS`, ou `error`.
    C'est lui que lit le reste de l'application. `detail` est
    l'explication du service telle quelle : une chaîne, ou une liste pour
    un refus de validation. `retry_after` est l'attente annoncée en
    secondes, quand il y en a une. `status`, le code HTTP, ne sert qu'ici
    et aux tests.
    """

    def __init__(self, status, detail, retry_after=None, *, kind=None):
        self.status = status
        self.detail = detail
        self.retry_after = retry_after
        self.kind = kind or ("unreachable" if status is None
                             else _KINDS.get(status, "error"))
        quoi = f"card-api {status}" if status else "card-api injoignable"
        super().__init__(f"{quoi} : {detail}")


@dataclass(frozen=True)
class Ticket:
    """Une demande partie en file de calcul (réponse 202).

    Le résultat ne vient pas avec : suivre `CardClient.job(ticket.job)`
    jusqu'à `done`, puis lire `CardClient.job_result`.
    """

    job: str
    status: str


class CardClient:
    """Le client de card-api. Une instance par processus suffit : le
    client HTTP qu'elle porte garde ses connexions ouvertes et se partage
    entre fils d'exécution.

    `transport` et `sleep` servent aux tests : un card-api simulé, et une
    attente qu'on enregistre au lieu de la subir.
    """

    def __init__(self, base_url, api_key=None, *, timeout=TIMEOUT,
                 retries=2, max_wait=10.0, transport=None,
                 sleep=time.sleep):
        headers = {"User-Agent": USER_AGENT, "Accept": "application/json"}
        if api_key:
            headers["X-API-Key"] = api_key
        self.has_key = bool(api_key)
        self._retries = retries
        self._max_wait = max_wait
        self._sleep = sleep
        self._http = httpx.Client(base_url=base_url.rstrip("/"),
                                  headers=headers, timeout=timeout,
                                  transport=transport)

    def close(self):
        self._http.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        self.close()

    # ── Le service ───────────────────────────────────────────────────

    def service(self):
        """`/v1` : ce qu'est le service, ses versions et ses plafonds
        (bloc `limits`), à lire plutôt qu'à écrire en dur."""
        return self._get("/v1")

    def health(self):
        """`/v1/health` : la file de calcul, le disque, le pool de cache."""
        return self._get("/v1/health")

    # ── Le catalogue ─────────────────────────────────────────────────

    def cards(self, **facets):
        """`/v1/cards`, filtré par facettes (`phenomenon="low-flows"`).
        Les noms et valeurs valides sont les clés de `vocabulary`, pas
        leurs libellés (« basses eaux » est refusé) ; un nom ou une valeur
        inconnus sont refusés par le service, pas ignorés."""
        return self._get("/v1/cards", facets)

    def card(self, card_id, *, lang=None):
        """`/v1/cards/{id}` : le détail d'une fiche, `id` étant le nom de
        son fichier."""
        return self._get(f"/v1/cards/{card_id}", {"lang": lang})

    def vocabulary(self):
        """`/v1/vocabulary` : les valeurs valides de chaque facette."""
        return self._get("/v1/vocabulary")

    # ── Les stations ─────────────────────────────────────────────────

    def stations(self, *, libelle=None, code=None, departement=None,
                 size=None):
        """`/v1/stations` : recherche dans le référentiel Hub'Eau. Le
        service demande au moins un des trois critères."""
        return self._get("/v1/stations", {
            "libelle": libelle, "code": code, "departement": departement,
            "size": size})

    # ── Les données ──────────────────────────────────────────────────

    def trend(self, stations, cards, *, sampling="preferred", start=None,
              end=None, mk=None, level=None, series=False, max_age=None,
              stations_meta=False, orient=None):
        """`/v1/trend` : extraction puis test de Mann-Kendall et pente de
        Sen. `stations` et `cards` sont des listes (ou un seul code).

        Rend la réponse du service, ou un `Ticket` si la demande est
        partie en file. La même demande peut partir en file une fois et
        répondre en direct la suivante : c'est voulu par le service.
        `series=True` joint les séries agrégées au diagnostic.
        """
        return self._get("/v1/trend", {
            "stations": _joined(stations), "cards": _joined(cards),
            "sampling": sampling, "start": start, "end": end, "mk": mk,
            "level": level, "series": series, "max_age": max_age,
            "stations_meta": stations_meta, "orient": orient,
        }, ticket=True)

    def chronicles(self, stations, *, start=None, end=None, max_age=None,
                   orient=None):
        """`/v1/chronicles` : le débit journalier tel que le service l'a
        lu, avec la même provenance que les tendances calculées dessus.
        Plafond de stations bas, publié par `/v1` (`limits.chronicles`)."""
        return self._get("/v1/chronicles", {
            "stations": _joined(stations), "start": start, "end": end,
            "max_age": max_age, "orient": orient})

    # ── La file de calcul ────────────────────────────────────────────

    def job(self, job_id):
        """Statut et progression d'un job : `queued`, `running`, `done`
        ou `failed`."""
        return self._get(_job_path(job_id))

    def job_result(self, job_id):
        """Le résultat gelé d'un job terminé, avec sa provenance. Avant
        `done`, le service répond 409."""
        return self._get(_job_path(job_id, "/result"))

    def cancel_job(self, job_id):
        """Abandonner un job : un calcul dont plus personne n'attend le
        résultat n'a pas à occuper la file."""
        self._check(self._send("DELETE", _job_path(job_id)))

    def wait(self, result, *, timeout=600.0, interval=10.0):
        """Le résultat d'une demande, en suivant sa file s'il le faut.

        `result` est ce qu'a rendu `trend` : la réponse elle-même, rendue
        telle quelle, ou un `Ticket` (ou un numéro de job), suivi jusqu'à
        la fin. Bloquant : pour un script ou le préchauffage, jamais pour
        une requête de la page, qui tiendrait un fil d'exécution le temps
        d'une file.

        Entre deux relevés, l'attente que le service annonce
        (`Retry-After`), sinon `interval`. Un job en échec remonte le refus
        du service (409). Au-delà de `timeout` secondes d'attente,
        `CardApiError` de genre `timeout` ; le job, lui, continue :
        l'abandonner (`cancel_job`) revient à l'appelant. Le délai additionne
        les attentes, il ne lit pas l'horloge.
        """
        if isinstance(result, dict):
            return result
        job_id = getattr(result, "job", result)
        waited = 0.0
        while True:
            response = self._send("GET", _job_path(job_id))
            self._check(response)
            status = response.json()["status"]
            if status in ("done", "failed"):
                return self.job_result(job_id)
            if waited >= timeout:
                raise CardApiError(None, f"job {job_id} toujours {status} "
                                         f"après {waited:g} s",
                                   kind="timeout")
            pause = _retry_after(response) or interval
            self._sleep(pause)
            waited += pause

    def jobs(self):
        """Les jobs déposés avec la clé. Sans clé, le service répond 401 :
        c'est aussi la façon de vérifier que la clé est acceptée."""
        return self._get("/v1/jobs")

    # ── La mécanique ─────────────────────────────────────────────────

    def _get(self, path, params=None, *, ticket=False):
        response = self._send("GET", path, params)
        if ticket and response.status_code == 202:
            body = response.json()
            return Ticket(job=body["job"], status=body["status"])
        self._check(response)
        return response.json()

    def _send(self, method, path, params=None):
        # Un paramètre absent, ou faux pour un drapeau, ne part pas : le
        # service applique alors sa propre valeur par défaut.
        params = {k: v for k, v in (params or {}).items()
                  if v is not None and v is not False}
        attempt = 0
        while True:
            try:
                response = self._http.request(method, path, params=params)
            except (httpx.ConnectError, httpx.ConnectTimeout) as e:
                if attempt < self._retries:
                    attempt += 1
                    self._wait(2.0 ** (attempt - 1), path, type(e).__name__)
                    continue
                raise CardApiError(None, type(e).__name__) from e
            except httpx.TransportError as e:
                # Délai de lecture dépassé, connexion coupée : le service a
                # peut-être calculé, on ne rejoue pas.
                raise CardApiError(None, type(e).__name__) from e

            if response.status_code in RETRY_STATUSES \
                    and attempt < self._retries:
                wait = _retry_after(response)
                if wait is None:
                    wait = 2.0 ** attempt
                if wait <= self._max_wait:
                    attempt += 1
                    self._wait(wait, path, response.status_code)
                    continue
            return response

    def _wait(self, seconds, path, why):
        log.warning("card-api %s sur %s : nouvel essai dans %g s",
                    why, path, seconds)
        self._sleep(seconds)

    def _check(self, response):
        if response.is_success:
            return
        try:
            detail = response.json()["detail"]
        except (ValueError, TypeError, KeyError):
            # Pas l'enveloppe d'erreur du service : une page du frontal,
            # typiquement un 502 d'Apache.
            detail = response.text[:500]
        if response.status_code == 401:
            log.error("card-api refuse la clé de priorité : %s", detail)
        raise CardApiError(response.status_code, detail,
                           _retry_after(response))


def client_from_env(environ=None):
    """Un client réglé par l'environnement : `MAKAHO_CARD_API_URL`
    (requise) et `MAKAHO_CARD_API_KEY`. Leur description et l'adresse
    publique du service sont dans `.env.example`, et seulement là.

    `environ` remplace `os.environ`, par exemple pour y joindre ce que
    lit `dotenv_values(".env")` hors de `flask run`.
    """
    env = os.environ if environ is None else environ
    url = env.get("MAKAHO_CARD_API_URL")
    if not url:
        raise RuntimeError(
            "MAKAHO_CARD_API_URL n'est pas définie : copier .env.example "
            "en .env et le compléter")
    key = env.get("MAKAHO_CARD_API_KEY") or None
    if key is None:
        log.warning("pas de clé de priorité card-api : la vue complète du "
                    "RRSE dépasse le plafond public")
    return CardClient(url, key)

# Un numéro de job vient de la page avant d'entrer dans une adresse : il
# ne peut contenir ni `/`, ni `?`, ni `..`, qui viseraient une autre
# route du service avec la clé de MAKAHO. card-api en fabrique de seize
# caractères hexadécimaux ; on accepte plus large, pas plus dangereux.
_JOB_ID = re.compile(r"[A-Za-z0-9_-]{1,64}")


def _job_path(job_id, suffix=""):
    if not isinstance(job_id, str) or not _JOB_ID.fullmatch(job_id):
        raise CardApiError(None, f"numéro de job invalide : {job_id!r}",
                           kind="invalid")
    return f"/v1/jobs/{job_id}{suffix}"


def _joined(values):
    """Une liste de codes devient la liste séparée par des virgules que
    le service attend ; un code seul passe tel quel."""
    if isinstance(values, str):
        return values
    return ",".join(values)


def _retry_after(response):
    """L'attente annoncée par `Retry-After`, en secondes, si elle est
    donnée sous cette forme (card-api ne donne que celle-là)."""
    value = response.headers.get("Retry-After", "")
    return float(value) if value.isdigit() else None
