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

from flask import Blueprint, current_app, render_template

from .card_client import CardApiError

bp = Blueprint("makaho", __name__)


def card_client():
    return current_app.extensions["card_client"]


@bp.get("/")
def index():
    return render_template("index.html")


@bp.get("/api/service")
def service():
    """Ce que card-api dit de lui-même : versions et plafonds, tels quels."""
    return card_client().service()


@bp.errorhandler(CardApiError)
def card_api_error(e):
    """Un refus ou une panne de card-api, relayé à la page en 502.

    Le 502 dit que la faute est en amont de MAKAHO. Le corps dit ce que
    cela veut dire (`CardApiError.kind` : `no_data`, `busy`,
    `unreachable`...), pas le code HTTP du service, qui reste dans
    `card_client` (décision 3), et garde son explication.
    """
    body = {"error": e.kind, "detail": e.detail}
    headers = {}
    if e.retry_after is not None:
        headers["Retry-After"] = str(int(e.retry_after))
    return body, 502, headers
