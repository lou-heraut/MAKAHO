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

"""MAKAHO : la carte des tendances hydrologiques, sur card-api.

`create_app` fabrique l'application. `flask --app makaho run` la trouve
d'elle-même ; un serveur de production l'appelle par
`makaho:create_app()`.
"""

import logging
import os

from flask import Flask

from .card_client import CardClient

log = logging.getLogger(__name__)


def create_app(client=None):
    """L'application, branchée sur card-api.

    Sans `client`, elle en construit un depuis l'environnement :
    `MAKAHO_CARD_API_URL` (requise) et `MAKAHO_CARD_API_KEY`. Leur
    description et la valeur publique de l'adresse sont dans
    `.env.example`, et seulement là. Les tests passent un client branché
    sur un card-api simulé.
    """
    app = Flask(__name__)
    if client is None:
        client = _client_from_env()
    app.extensions["card_client"] = client

    from . import views
    app.register_blueprint(views.bp)
    return app


def _client_from_env():
    url = os.environ.get("MAKAHO_CARD_API_URL")
    if not url:
        raise RuntimeError(
            "MAKAHO_CARD_API_URL n'est pas définie : copier .env.example "
            "en .env et le compléter")
    key = os.environ.get("MAKAHO_CARD_API_KEY") or None
    if key is None:
        log.warning("pas de clé de priorité card-api : la vue complète du "
                    "RRSE dépasse le plafond public")
    return CardClient(url, key)
