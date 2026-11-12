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

"""Ce que la page affiche, à partir d'une tendance rendue par card_client.

La page ne calcule rien : les verdicts, les classes de couleur, les
compteurs, les libellés et la provenance sont préparés ici, où ils se
testent. Tous les nombres viennent de card-api (principe 1 de
`dev/decisions.md`) ; MAKAHO ne fait que les classer et les compter.

La symbologie est celle de MAKAHO 1.0.0
(`dev/audits/2026-11-11_v1-interface.md`) :

- la forme dit le verdict : `up` ou `down` pour une tendance
  significative, `none` sinon ;
- une chronique de moins de `MIN_YEARS` valeurs est signalée (`short`),
  et ne compte ni en hausse ni en baisse ;
- la couleur dit la classe de la pente, dans tous les cas : pente
  relative (% par an) si la fiche le déclare, absolue sinon ;
- la palette est celle de la fiche, les classes sont centrées sur zéro,
  bornées symétriquement par le plus grand des quantiles 1 % et 99 %
  des pentes, et les deux classes extrêmes sont ouvertes.
"""

import bisect
import datetime
import math
import re
import statistics

# Les quantiles qui bornent la barre de couleur : ceux de stase
# (`extremes_prob`), en interpolation linéaire. Vérifié le 2026-11-11 sur
# QA et le RRSE : mêmes bornes que `a_relative_min` et `a_relative_max`
# rendues par card-api (dev/plans/2026-11-11_m2-map.md).
EXTREME_PROB = 0.01

# Le garde-fou de MAKAHO 1.0.0 : en deçà de trente valeurs, la tendance
# n'est pas lue. Sur QA et le RRSE, il désigne les trois stations que la
# 1.0.0 entoure de jaune (relevé du 2026-11-11).
MIN_YEARS = 30

# Ce qui n'est pas de la provenance dans la réponse : les données, et ce
# que `for_page` reprend sous une autre forme. Tout le reste en est, y
# compris un champ que card-api ajouterait demain.
_NOT_PROVENANCE = {"data", "meta", "series", "stations", "stations_meta",
                   "stations_requested", "stations_omitted", "orient",
                   "cards"}

MONTHS = ("janv.", "févr.", "mars", "avr.", "mai", "juin", "juil.",
           "août", "sept.", "oct.", "nov.", "déc.")


def for_page(result):
    """La réponse de `/v1/trend` (ou d'un job de tendance), pour la page.

    Une fiche par appel : c'est ce que demande la vue complète
    (`dev/decisions.md`). Une fiche à plusieurs variables (QMA, un mois
    par variable) les rend ensemble, dans une table que la colonne
    `variable` partage : la page reçoit une entrée par variable, dans
    l'ordre de `meta`, et passe de l'une à l'autre sans redemander.
    """
    if len(result["data"]) != 1:
        raise ValueError(f"une fiche attendue, reçu {sorted(result['data'])}")
    (card, rows), = result["data"].items()
    by_variable = {}
    for r in rows:
        by_variable.setdefault(r.get("variable", card), []).append(r)
    imposed = result.get("sampling")
    variables = [_variable(m, by_variable[m["variable_en"]], imposed)
                 for m in result["meta"] if m["variable_en"] in by_variable]

    out = {
        "card": card,
        "variables": variables,
        "omitted": result.get("stations_omitted", []),
        "provenance": {k: v for k, v in result.items()
                       if k not in _NOT_PROVENANCE},
    }
    if "stations_meta" in result:
        out["positions"] = [
            {"code": s["code_station"], "name": s.get("libelle_station"),
             "lon": s.get("longitude_station"),
             "lat": s.get("latitude_station")}
            for s in result["stations_meta"]]
    return out


def _variable(meta, rows, imposed):
    """Une variable : ses stations classées, sa barre de couleur, ses
    compteurs et ses libellés."""
    relative = bool(meta.get("relative"))
    key = "a_relative" if relative else "a"
    palette = meta["palette"].split()

    slopes = [r[key] for r in rows if r.get(key) is not None]
    edges = class_edges(slopes, len(palette))
    stations = []
    for r in rows:
        slope = r.get(key)
        stations.append({
            "code": r["code_station"],
            "trend": _trend(r),
            "short": r.get("n") is not None and r["n"] < MIN_YEARS,
            "class": None if slope is None else class_of(slope, edges),
            "a": r.get("a"),
            "a_relative": r.get("a_relative") if relative else None,
        })
    return {
        "id": meta["variable_en"],
        "name": meta.get("name_fr"),
        "relative": relative,
        "units": _units(meta, relative),
        "sampling": year_label(meta, imposed),
        "digits": _digits(edges),
        "palette": palette,
        "edges": edges,
        "stations": stations,
        "summary": summary(stations),
    }


def class_edges(slopes, n_classes):
    """Les `n_classes - 1` bornes des classes, symétriques autour de zéro.

    La borne est le plus grand, en valeur absolue, des quantiles 1 % et
    99 % des pentes : quelques stations extrêmes ne tirent pas l'échelle.
    Sans dispersion à mesurer (moins de deux pentes, ou toutes nulles),
    l'échelle vaut 1, pour rester lisible plutôt que dégénérée.
    """
    if len(slopes) >= 2:
        q = statistics.quantiles(slopes, n=round(1 / EXTREME_PROB),
                                 method="inclusive")
        bound = max(abs(q[0]), abs(q[-1]))
    else:
        bound = abs(slopes[0]) if slopes else 0.0
    bound = bound or 1.0
    step = 2 * bound / (n_classes - 2)
    return [-bound + i * step for i in range(n_classes - 1)]


def class_of(slope, edges):
    """L'indice de classe d'une pente : 0 sous la première borne, et une
    borne appartient à la classe du dessous, comme `cut()` en R."""
    return bisect.bisect_left(edges, slope)


def summary(stations):
    """Les compteurs de la 1.0.0 : les stations, les hausses et les
    baisses significatives. Une chronique trop courte n'en est pas une."""
    count = {"up": 0, "down": 0}
    for s in stations:
        if s["trend"] in count and not s["short"]:
            count[s["trend"]] += 1
    return {**count, "total": len(stations)}


def year_label(meta, imposed=None):
    """L'année de calcul d'une variable, en clair : « du 01 sept. au 31
    août ». None si la fiche ne permet pas de le dire.

    Une variable saisonnière garde sa fenêtre, fixée par la fiche
    (`sampling_period_fr`, jour-mois : « du 01 mai au 30 nov. »). Une
    variable annuelle commence au départ que le panneau impose (`imposed`,
    mois-jour, le `sampling` rendu par card-api), sinon au départ fixe que
    déclare la fiche (`preferred_sampling_period`, mois-jour) : c'est le
    protocole MAKAHO, `sampling=preferred`. Sa fenêtre adaptative, que
    `sampling_period_fr` décrit alors en mots, ne sert pas.
    """
    window = window_bounds(meta.get("sampling_period_fr"))
    if window and _day_before(window[0]) != window[1]:
        return _label(*window)
    start = (_month_day(imposed)
             or _month_day(meta.get("preferred_sampling_period"))
             or (window[0] if window else None))
    return _label(start, _day_before(start)) if start else None


def window_bounds(text):
    """`01-09, 31-08` ou `01-12, 28(29)-02` (jour-mois) : les deux bornes
    en (jour, mois), ou None."""
    found = re.findall(r"(\d{2})(?:\(\d{2}\))?-(\d{2})", text or "")
    if len(found) != 2:
        return None
    bounds = [(int(d), int(m)) for d, m in found]
    return tuple(bounds) if all(_valid(b) for b in bounds) else None


def _month_day(text):
    """`09-01` (mois-jour, comme `sampling`) en (jour, mois), ou None."""
    m = re.fullmatch(r"(\d{2})-(\d{2})", text or "")
    if not m:
        return None
    bound = (int(m.group(2)), int(m.group(1)))
    return bound if _valid(bound) else None


def _valid(bound):
    day, month = bound
    try:
        datetime.date(2001, month, day)
    except ValueError:
        return day == 29 and month == 2
    return True


def _day_before(bound):
    """La veille, sur une année non bissextile : la fin d'une année qui
    commence à `bound`."""
    day, month = bound
    d = datetime.date(2001, month, min(day, 28 if month == 2 else day))
    d -= datetime.timedelta(days=1)
    return (d.day, d.month)


def _label(start, end):
    (d1, m1), (d2, m2) = start, end
    return f"du {d1:02d} {MONTHS[m1 - 1]} au {d2:02d} {MONTHS[m2 - 1]}"


def unit_parts(unit):
    """Une unité en morceaux (texte, exposant) que la page écrit avec
    `<sup>` : `m^{3}.s^{-1}` donne `[["m", "3"], [".s", "-1"]]`."""
    parts, pos = [], 0
    for m in re.finditer(r"\^\{([^}]*)\}", unit or ""):
        parts.append([unit[pos:m.start()], m.group(1)])
        pos = m.end()
    if pos < len(unit or ""):
        parts.append([unit[pos:], ""])
    return parts


def _units(meta, relative):
    """Les unités des pentes : absolue et relative pour l'infobulle, et
    celle de la barre de couleur, en toutes lettres comme dans la 1.0.0.
    Une date (jour de l'année) dérive en jours par an."""
    if meta.get("is_date"):
        absolute = "jour.an^{-1}"
        bar = [["jours par an", ""]]
    else:
        unit = meta.get("unit_fr") or ""
        absolute = f"{unit}.an^{{-1}}" if unit else "an^{-1}"
        bar = unit_parts(unit) + [[" par an", ""]]
    if relative:
        bar = [["% par an", ""]]
    return {"absolute": unit_parts(absolute),
            "relative": unit_parts("%.an^{-1}") if relative else None,
            "bar": bar}


def _trend(row):
    """`up`, `down` ou `none` ; None si le test n'a pas pu se faire."""
    h, a = row.get("h"), row.get("a")
    if h is None or a is None:
        return None
    if not h or a == 0:
        return "none"
    return "up" if a > 0 else "down"


def _digits(edges):
    """Les décimales qui distinguent deux bornes voisines, avec deux
    chiffres significatifs : 2 pour des pentes de l'ordre du pour cent,
    davantage pour une fréquence qui varie de 1e-4 par an."""
    step = edges[1] - edges[0] if len(edges) > 1 else abs(edges[0]) or 1.0
    return max(0, math.ceil(-math.log10(step)) + 1)
