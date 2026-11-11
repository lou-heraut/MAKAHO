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

import re

from flask import Blueprint, current_app, render_template, request

from . import trends
from .card_client import CardApiError, Ticket
from .stations import station_list

bp = Blueprint("makaho", __name__)

# La fiche affichée tant que les menus n'existent pas (M3).
DEFAULT_CARD = "QA"

# Le rythme auquel la page revient voir une demande partie en file.
POLL_SECONDS = 5

# Une fiche à la fois, par son identifiant : la demande part avec la clé
# de MAKAHO, sans quota ni plafond de fiches, en tête de file. Laisser
# passer une liste (`QA,QMNA,...`) ferait de chaque visiteur un déposant
# de jobs prioritaires (revue de M2, 2026-11-11).
_CARD = re.compile(r"[A-Za-z0-9_-]{1,64}")


def card_client():
    return current_app.extensions["card_client"]


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/api/service")
def service():
    """Ce que card-api dit de lui-même : versions et plafonds, tels quels."""
    return card_client().service()


@bp.get("/api/trend")
def trend():
    """La tendance d'une fiche sur le RRSE, prête pour la page.

    `positions=1` joint les positions des stations : la page les demande
    une fois par visite, card-api les relisant chez Hub'Eau à chaque
    appel. Une demande partie en file rend 202 et son numéro de job.
    """
    card = request.args.get("card", DEFAULT_CARD)
    if not _CARD.fullmatch(card):
        return {"error": "invalid",
                "detail": f"une fiche à la fois, par son identifiant : {card!r}"}, 400
    positions = request.args.get("positions") == "1"
    result = card_client().trend(station_list(), card,
                                 stations_meta=positions)
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
