"""Le numéro de version, écrit dans `pyproject.toml` et recopié pour la
citation, doit être le même partout.

Un `CITATION.cff` qui traîne un numéro périmé fait citer un état qui
n'est pas celui qu'on a publié. `scripts/set_version.py` accorde les
copies ; ce test casse si l'une a été oubliée.
"""

import json
import re
from importlib.metadata import version
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def _version(name, pattern):
    m = re.search(pattern, (ROOT / name).read_text(encoding="utf-8"), re.M)
    assert m, f"version introuvable dans {name}"
    return m.group(1)


def _package():
    return _version("pyproject.toml", r'^version\s*=\s*"([^"]+)"')


def test_la_citation_annonce_la_version_du_paquet():
    package = _package()
    cff = _version("CITATION.cff", r'^version:\s*"([^"]+)"')
    meta = json.loads((ROOT / "codemeta.json").read_text(encoding="utf-8"))
    assert cff == package, f"CITATION.cff dit {cff}, le paquet {package}"
    assert meta["version"] == package, (
        f"codemeta.json dit {meta['version']}, le paquet {package}")


def test_l_installation_annonce_la_version_du_paquet():
    """Le client se présente à card-api avec le numéro de l'INSTALLATION
    (`card_client.USER_AGENT`). Une installation éditable faite avant un
    changement de version garde l'ancien : relancer `make install`."""
    assert version("makaho") == _package(), (
        "l'environnement est en retard sur pyproject.toml : make install")
