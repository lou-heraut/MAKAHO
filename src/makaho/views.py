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

"""Les routes de MAKAHO : la page, et l'API que la page appelle.

La page ne parle jamais à card-api directement : la clé de priorité ne
doit pas quitter le serveur, et tout ce qui vient du service passe par
`card_client` (décision 3).
"""

import datetime
import re

from flask import Blueprint, current_app, render_template, request

from . import catalogue, trends
from .card_client import CardApiError, Ticket
from .stations import station_list

bp = Blueprint("makaho", __name__)

# La fiche qui s'affiche à l'ouverture, celle de la 1.0.0.
DEFAULT_CARD = "QA"

# Le rythme auquel la page revient voir une demande partie en file.
POLL_SECONDS = 5

# Une fiche à la fois, par son identifiant : la demande part avec la clé
# de MAKAHO, sans quota ni plafond de fiches, en tête de file. Laisser
# passer une liste (`QA,QMNA,...`) ferait de chaque visiteur un déposant
# de jobs prioritaires (revue de M2, 2026-11-11).
_CARD = re.compile(r"[A-Za-z0-9_-]{1,64}")

# Le départ de l'année que le curseur impose : le premier d'un mois.
_SAMPLING = re.compile(r"preferred|(0[1-9]|1[0-2])-01")


class _Invalid(ValueError):
    """Un réglage que le panneau ne propose pas."""


def card_client():
    return current_app.extensions["card_client"]


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/api/service")
def service():
    """Ce que card-api dit de lui-même : versions et plafonds, tels quels."""
    return card_client().service()


@bp.get("/api/cards")
def cards():
    """Les menus du panneau d'analyse, tirés du catalogue de card-api."""
    client = card_client()
    return catalogue.menus(client.cards(), client.vocabulary(), DEFAULT_CARD)


@bp.get("/api/trend")
def trend():
    """La tendance d'une fiche sur le RRSE, prête pour la page.

    Les réglages du panneau (`start`, `end` en années, `sampling`,
    `level`) sont vérifiés avant de partir avec la clé ; un réglage
    absent reste au défaut du service. `positions=1` joint les positions
    des stations : la page les demande une fois par visite, card-api les
    relisant chez Hub'Eau à chaque appel. Une demande partie en file rend
    202 et son numéro de job.
    """
    card = request.args.get("card", DEFAULT_CARD)
    if not _CARD.fullmatch(card):
        return {"error": "invalid",
                "detail": f"une fiche à la fois, par son identifiant : {card!r}"}, 400
    try:
        settings = _settings(request.args)
    except _Invalid as e:
        return {"error": "invalid", "detail": str(e)}, 400
    positions = request.args.get("positions") == "1"
    result = card_client().trend(station_list(), card,
                                 stations_meta=positions, **settings)
    if isinstance(result, Ticket):
        return _pending(result.job, result.status)
    return _page(result)


@bp.get("/api/jobs/<job_id>")
def job(job_id):
    """Une demande partie en file : 202 tant qu'elle tourne, la page
    ensuite."""
    state = card_client().job(job_id)
    if state["status"] in ("queued", "running"):
        return _pending(job_id, state["status"], state.get("progress"))
    return _page(card_client().job_result(job_id))


def _settings(args):
    """Les réglages venus de la page, pour `CardClient.trend`.

    Rien d'autre que ce que le panneau propose, puisque la demande part
    avec la clé de MAKAHO : des années dans les bornes du curseur, au
    moins `trends.MIN_YEARS` ans quand le début et la fin sont donnés, un
    départ d'année au premier d'un mois, un risque de la liste. Une année
    devient une date : le 1er janvier pour le début, le 31 décembre pour
    la fin.
    """
    out = {}
    years = {}
    last = datetime.date.today().year
    for name in ("start", "end"):
        value = args.get(name)
        if value is None:
            continue
        if not re.fullmatch(r"\d{4}", value) \
                or not catalogue.FIRST_YEAR <= int(value) <= last:
            raise _Invalid(f"{name} : une année de {catalogue.FIRST_YEAR} "
                           f"à {last}, reçu {value!r}")
        years[name] = int(value)
    if len(years) == 2 and years["end"] - years["start"] + 1 < trends.MIN_YEARS:
        raise _Invalid(f"une période d'au moins {trends.MIN_YEARS} ans, "
                       f"reçu {years['start']} à {years['end']}")
    if "start" in years:
        out["start"] = f"{years['start']}-01-01"
    if "end" in years:
        out["end"] = f"{years['end']}-12-31"

    sampling = args.get("sampling")
    if sampling is not None:
        if not _SAMPLING.fullmatch(sampling):
            raise _Invalid(f"sampling : preferred ou le premier d'un mois "
                           f"(MM-01), reçu {sampling!r}")
        out["sampling"] = sampling

    level = args.get("level")
    if level is not None:
        try:
            value = float(level)
        except ValueError:
            value = None
        if value not in catalogue.LEVELS:
            raise _Invalid(f"level : l'un de {list(catalogue.LEVELS)}, "
                           f"reçu {level!r}")
        out["level"] = value
    return out


def _pending(job_id, status, progress=None):
    body = {"job": job_id, "status": status, "progress": progress}
    return body, 202, {"Retry-After": str(POLL_SECONDS)}


def _page(result):
    try:
        return trends.for_page(result)
    except ValueError as e:
        # Une fiche à plusieurs variables : la page ne sait pas encore
        # choisir (M3).
        return {"error": "invalid", "detail": str(e)}, 400


@bp.errorhandler(CardApiError)
def card_api_error(e):
    """Un refus ou une panne de card-api, relayé à la page en 502 (400
    pour une demande mal formée).

    Le 502 dit que la faute est en amont de MAKAHO. Le corps dit ce que
    cela veut dire (`CardApiError.kind` : `no_data`, `busy`,
    `unreachable`...), pas le code HTTP du service, qui reste dans
    `card_client` (décision 3), et garde son explication.
    """
    body = {"error": e.kind, "detail": e.detail}
    headers = {}
    if e.retry_after is not None:
        headers["Retry-After"] = str(int(e.retry_after))
    # Une demande mal formée vient de la page (fiche inconnue, numéro de
    # job invalide) : 400, la faute n'est pas en amont.
    return body, 400 if e.kind == "invalid" else 502, headers
