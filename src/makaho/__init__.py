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
