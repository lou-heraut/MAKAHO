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

from flask import Flask

from .card_client import client_from_env


def create_app(client=None):
    """L'application, branchée sur card-api.

    Sans `client`, elle en construit un depuis l'environnement
    (`card_client.client_from_env`). Les tests passent un client branché
    sur un card-api simulé.
    """
    app = Flask(__name__)
    if client is None:
        client = client_from_env()
    app.extensions["card_client"] = client

    from . import views
    app.register_blueprint(views.bp)
    return app
