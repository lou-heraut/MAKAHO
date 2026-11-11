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

"""Propage le numéro de version depuis `pyproject.toml`.

Le numéro vit dans `pyproject.toml`. `CITATION.cff` et `codemeta.json` le
recopient, parce que les outils de citation les lisent ; ce script les
accorde, et `tests/test_citation.py` refuse qu'ils divergent. Même
mécanisme que dans card, stase et card-api : trente lignes recopiées
dans quatre dépôts coûtent moins qu'un outil commun qui les couplerait.

Usage, depuis la racine du dépôt :

    python scripts/set_version.py --etat    # les faits, avant de couper
    python scripts/set_version.py 2.0.0     # fixe la version partout
    python scripts/set_version.py           # propage celle du pyproject

Une version publiée (`2.0.0`) date aussi les métadonnées du jour ; une
version de développement (`2.0.0.dev0`) ne date rien, puisqu'elle n'est
pas publiée. Quand couper une version : « Numérotation », en tête de
`CHANGELOG.md`.
"""

import datetime as dt
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RELEASE = re.compile(r"\d+\.\d+\.\d+")
DEV = re.compile(r"\d+\.\d+\.\d+\.dev\d+")


def _git(*args):
    """La sortie d'une commande git, ou None si elle échoue."""
    try:
        out = subprocess.run(("git", "-C", str(ROOT)) + args,
                             capture_output=True, text=True, check=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    return out.stdout.strip()


def read_version():
    m = re.search(r'^version\s*=\s*"([^"]+)"',
                  (ROOT / "pyproject.toml").read_text(encoding="utf-8"), re.M)
    if not m:
        sys.exit("version introuvable dans pyproject.toml")
    return m.group(1)


def state():
    """Les faits qui portent la décision de couper une version."""
    print(f"version du paquet    : {read_version()}")
    tag = _git("describe", "--tags", "--abbrev=0")
    if tag:
        print(f"dernier tag          : {tag}")
        print(f"commits depuis       : "
              f"{_git('rev-list', '--count', f'{tag}..HEAD')}")
    else:
        print("dernier tag          : aucun sur cette branche")
    text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
    section = re.search(r"^## Non publié\n(.*?)(?=^## |\Z)", text,
                        re.M | re.S)
    entries = re.findall(r"^- \*\*", section.group(1), re.M) if section else []
    print(f"entrées non publiées : {len(entries)}")
    print("\nCouper ou non : « Numérotation », en tête de CHANGELOG.md.")


def _sub(path, pattern, replacement):
    """Remplace la première ligne qui correspond, et dit si le fichier a
    changé. Une ligne absente est une erreur : le fichier a été réécrit
    à la main, mieux vaut le savoir que l'ignorer."""
    p = ROOT / path
    text = p.read_text(encoding="utf-8")
    new, n = re.subn(pattern, replacement, text, count=1, flags=re.M)
    if not n:
        sys.exit(f"ligne introuvable dans {path} : {pattern}")
    if new != text:
        p.write_text(new, encoding="utf-8")
        return True
    return False


def set_version(version):
    released = bool(RELEASE.fullmatch(version))
    if not (released or DEV.fullmatch(version)):
        sys.exit(f"version '{version}' mal formée : attendu 2.0.0 ou "
                 "2.0.0.dev0")
    today = dt.date.today().isoformat()
    changed = []

    if _sub("pyproject.toml", r'^version\s*=\s*"[^"]+"',
            f'version = "{version}"'):
        changed.append("pyproject.toml")

    if _sub("CITATION.cff", r'^version:\s*"[^"]+"', f'version: "{version}"'):
        changed.append("CITATION.cff")
    if released:
        cff = (ROOT / "CITATION.cff").read_text(encoding="utf-8")
        if re.search(r"^date-released:", cff, re.M):
            _sub("CITATION.cff", r'^date-released:\s*"[^"]+"',
                 f'date-released: "{today}"')
        else:
            _sub("CITATION.cff", r'^(version:\s*"[^"]+")',
                 f'\\1\ndate-released: "{today}"')

    path = ROOT / "codemeta.json"
    meta = json.loads(path.read_text(encoding="utf-8"))
    before = dict(meta)
    meta["version"] = version
    if released:
        meta["datePublished"] = today
    if meta != before:
        path.write_text(json.dumps(meta, indent=2, ensure_ascii=False) + "\n",
                        encoding="utf-8")
        changed.append("codemeta.json")

    print(f"version {version} : "
          + (", ".join(changed) + " mis à jour" if changed else "déjà partout"))
    if released:
        print("Reste : la section du CHANGELOG, `pip install -e .` pour que "
              "l'installation annonce le numéro, puis\n"
              f"    git commit -am \"MAKAHO {version}\" && "
              f"git tag -a v{version} -m \"MAKAHO {version}\"")


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("--etat", "--état"):
        state()
    else:
        set_version(sys.argv[1] if len(sys.argv) > 1 else read_version())


if __name__ == "__main__":
    main()
