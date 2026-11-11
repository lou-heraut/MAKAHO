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

"""Sensibilité des tendances au curseur d'échantillonnage de MAKAHO.

Reproduit les chiffres de `dev/audits/2026-09-18_migration.md`, section 5,
qui justifient la suppression du mode échantillon et la conservation du
départ d'année (décision 4 de `dev/decisions.md`). Ces chiffres seront
contestés un jour : ce script existe pour qu'on puisse les refaire au
lieu de les croire.

Deux mesures, sur les stations du RRSE (`makaho.stations`) :

  A. DÉPART D'ANNÉE. card-api calcule les tendances avec
     `sampling=preferred`, puis avec des départs fixes (`sampling=MM-JJ`).
     La mesure compte les stations dont le verdict de stationnarité
     bascule et celles dont la pente change de signe. Ce sont les appels
     que MAKAHO fait, donc exactement ce qu'il affiche.

  B. FENÊTRE PARTIELLE. Où tombent réellement les étiages, et ce que
     devient un « VCN10 » calculé sur février-juillet. card refuse ce
     couple, donc card-api aussi : la mesure lit les chroniques
     journalières par `/v1/chronicles` et reproduit VCN10 en local,
     moyenne mobile de 10 jours centrée puis minimum via stase. C'est
     l'ordre de grandeur qui compte, pas la troisième décimale.

Tout passe par card-api (décision 2), avec le client de MAKAHO, réglé
comme l'application : l'environnement, complété par `.env`. La clé de
priorité est nécessaire, le RRSE entier dépassant le plafond public.

    make measure

Charge sur le service : une tendance sur tout le RRSE par couple fiche et
départ, servie depuis son cache si les chroniques y sont, et les
chroniques par paquets de la taille que publie `/v1`. Quelques minutes.
"""

import collections
import os
import sys
import warnings
from pathlib import Path

import numpy as np
import pandas as pd
import stase
from dotenv import dotenv_values

from makaho.card_client import CardApiError, client_from_env
from makaho.stations import station_list

ROOT = Path(__file__).resolve().parent.parent

START, END = "1968-01-01", "2024-08-31"
CARDS = ["QA", "VCN10", "tQJXA"]
STARTS = ["preferred", "01-01", "05-01"]
WINDOW = ["02-01", "07-31"]
LEVEL, DEPENDENCY = 0.1, "AR1"
MIN_DAYS = 3650                  # dix ans de débits, sinon rien à dire
MONTHS = ["jan", "fev", "mar", "avr", "mai", "jun",
          "jui", "aou", "sep", "oct", "nov", "dec"]


def verdicts(client, stations, card, sampling):
    """{station: (verdict, pente)} pour une fiche et un départ d'année."""
    result = client.wait(client.trend(
        stations, card, sampling=sampling, start=START, end=END,
        level=LEVEL, mk=DEPENDENCY), timeout=1800)
    (rows,) = result["data"].values()          # une fiche, une variable
    out = {}
    for r in rows:
        if r.get("h") is not None and r.get("a") is not None \
                and not np.isnan(r["a"]):
            out[r["code_station"]] = (bool(r["h"]), float(r["a"]))
    return out, result


def measure_start(client, stations):
    """A. Ce que change le départ d'année, fiche par fiche.

    Les comparaisons ne valent que si tous les appels ont lu la même
    donnée : le pool de card-api renouvelle ses copies au fil de l'eau,
    et une révision Hub'Eau entre deux appels passerait pour un effet du
    départ d'année. Les empreintes le vérifient.
    """
    res, provenance, fingerprints = {}, None, set()
    for card in CARDS:
        for sampling in STARTS:
            res[(card, sampling)], result = verdicts(client, stations, card,
                                                     sampling)
            provenance = provenance or result
            fingerprints.add(result.get("data_fingerprint"))

    print("\nA. DÉPART D'ANNÉE\n")
    print(f"  {'fiche':<8} {'comparaison':<24} "
          f"{'verdicts qui basculent':>24} {'pentes de signe change':>24}")
    for card in CARDS:
        base = res[(card, "preferred")]
        for sampling in STARTS[1:]:
            other = res[(card, sampling)]
            common = sorted(set(base) & set(other))
            n = max(len(common), 1)
            flips = sum(1 for k in common if base[k][0] != other[k][0])
            signs = sum(1 for k in common
                        if np.sign(base[k][1]) != np.sign(other[k][1]))
            print(f"  {card:<8} {'preferred vs ' + sampling:<24} "
                  f"{flips:>8} / {len(common):<3} ({100 * flips / n:>5.1f} %) "
                  f"{signs:>8} / {len(common):<3} ({100 * signs / n:>5.1f} %)")
    print("\n  Contrôle : VCN10 contre 01-01 doit donner 0,0 %, son `preferred`\n"
          "  ÉTANT 01-01. Un chiffre non nul signale une mesure fausse.")
    if len(fingerprints) == 1:
        print("  Contrôle : tous les appels ont lu la même donnée (une seule "
              "empreinte).")
    else:
        print(f"  ATTENTION : {len(fingerprints)} empreintes différentes, la "
              "donnée a changé entre deux appels ; relancer la mesure.")
    return provenance


def chronicles(client, stations):
    """Les chroniques journalières, par paquets au plafond publié par /v1."""
    chunk = client.service()["limits"]["chronicles"]["stations"]
    for i in range(0, len(stations), chunk):
        try:
            out = client.chronicles(stations[i:i + chunk], start=START,
                                    end=END, orient="columns")
        except CardApiError as e:
            print(f"  paquet {i // chunk + 1} écarté : {e}", file=sys.stderr)
            continue
        df = pd.DataFrame(out["data"]).rename(columns={"code_station": "code"})
        df["date"] = pd.to_datetime(df["date"])
        for code, g in df.groupby("code", sort=False):
            if g["Q"].notna().sum() < MIN_DAYS:
                continue
            # Hub'Eau omet les jours manquants : sur les seules lignes, une
            # moyenne de dix valeurs pourrait enjamber une lacune. Sur le
            # calendrier complet, la lacune devient NaN et la fenêtre qui
            # la touche est écartée (min_periods=10).
            g = (g.set_index("date")[["Q"]].asfreq("D")
                 .reset_index().assign(code=code))
            yield code, g


def one_trend(series, column):
    t = stase.trend(series[["code", "date", column]],
                    level=LEVEL, dependency=DEPENDENCY)
    return bool(t.iloc[0]["h"])


def measure_window(client, stations):
    """B. Ce que fabrique une fenêtre partielle février-juillet."""
    outside = {1, 8, 9, 10, 11, 12}
    month_of_min = collections.Counter()
    ratios, flips, n_ok = [], 0, 0

    for code, df in chronicles(client, stations):
        df["Q10"] = df["Q"].rolling(10, center=True, min_periods=10).mean()
        for _, year in df.groupby(df.date.dt.year):
            if year["Q10"].notna().sum() > 300:
                month_of_min[year.loc[year["Q10"].idxmin(), "date"].month] += 1

        f = {"VCN10": (np.nanmin, "Q10")}
        try:
            full = stase.extract(df, f, time_step="year",
                                 sampling_period="01-01")
            part = stase.extract(df, f, time_step="year",
                                 sampling_period=WINDOW)
        except Exception as e:
            print(f"  {code} : extraction impossible ({type(e).__name__})",
                  file=sys.stderr)
            continue
        if full["VCN10"].notna().sum() < 30 or part["VCN10"].notna().sum() < 30:
            continue
        n_ok += 1
        ratios.append(part["VCN10"].mean() / full["VCN10"].mean())
        try:
            if one_trend(full, "VCN10") != one_trend(part, "VCN10"):
                flips += 1
        except Exception as e:
            print(f"  {code} : test impossible ({type(e).__name__})",
                  file=sys.stderr)

    total = sum(month_of_min.values())
    peak = max(month_of_min.values())
    print(f"\nB. FENÊTRE PARTIELLE {WINDOW[0]} à {WINDOW[1]}\n")
    print("  Où tombe réellement le minimum sur 10 jours, sur tout le RRSE :")
    for m in range(1, 13):
        n = month_of_min.get(m, 0)
        mark = "   hors fenetre" if m in outside else ""
        print(f"    {MONTHS[m - 1]}  {100 * n / total:>5.1f} %  "
              f"{'#' * int(55 * n / peak)}{mark}")
    excluded = sum(month_of_min.get(m, 0) for m in outside)
    print(f"\n    => {100 * excluded / total:.1f} % des étiages annuels tombent "
          f"HORS de la fenêtre")

    r = np.array(ratios)
    print(f"\n  VCN10 année pleine contre fenêtre partielle, {n_ok} stations :")
    print(f"    la valeur dite « VCN10 » est en moyenne {r.mean():.2f} fois plus haute")
    print(f"    (médiane {np.median(r):.2f} ; de {r.min():.2f} à {r.max():.2f})")
    print(f"    verdict de stationnarité qui bascule : {flips} / {n_ok} "
          f"({100 * flips / max(n_ok, 1):.1f} %)")


def main():
    warnings.simplefilter("ignore")
    env = {**dotenv_values(ROOT / ".env"), **os.environ}
    stations = station_list("rrse")
    with client_from_env(env) as client:
        print(f"{len(stations)} stations du RRSE, période {START} à {END}, "
              f"niveau {LEVEL}, dépendance {DEPENDENCY}")
        provenance = measure_start(client, stations)
        measure_window(client, stations)

    print("\nProvenance (mesure A, card-api) :")
    for key in ("api_version", "card_version", "card_commit",
                "stase_version", "stase_commit", "data_fetched_at",
                "data_fingerprint"):
        print(f"  {key:<17} {provenance.get(key)}")
    print(f"  stase local       {stase.__version__} (mesure B)")


if __name__ == "__main__":
    main()
