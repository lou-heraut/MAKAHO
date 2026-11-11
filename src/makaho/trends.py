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

La page ne calcule rien : les pentes, leurs classes de couleur,
l'histogramme, le résumé et la provenance sont préparés ici, où ils se
testent. Tous les nombres viennent de card-api (principe 1 de
`dev/decisions.md`) ; MAKAHO ne fait que les classer et les compter.

La symbologie est celle de MAKAHO, et de la carte de référence de
card-api (`examples/carte_tendance_QA.R`) :

- la forme dit le verdict : `up` ou `down` pour une tendance
  significative, `none` sinon ;
- la couleur dit la classe de la pente, dans tous les cas : pente
  relative (% par an) si la fiche le déclare, absolue sinon ;
- la palette est celle de la fiche, les classes sont centrées sur zéro,
  bornées symétriquement par le plus grand des quantiles 1 % et 99 %
  des pentes, et les deux classes extrêmes sont ouvertes.
"""

import bisect
import math
import re
import statistics

# Les quantiles qui bornent la barre de couleur : ceux de stase
# (`extremes_prob`), en interpolation linéaire. Vérifié le 2026-11-11 sur
# QA et le RRSE : mêmes bornes que `a_relative_min` et `a_relative_max`
# rendues par card-api (dev/plans/2026-11-11_m2-map.md).
EXTREME_PROB = 0.01

# Ce qui n'est pas de la provenance dans la réponse : les données, et ce
# que `for_page` reprend sous une autre forme. Tout le reste en est, y
# compris un champ que card-api ajouterait demain.
_NOT_PROVENANCE = {"data", "meta", "series", "stations", "stations_meta",
                   "stations_requested", "stations_omitted", "orient",
                   "cards"}

_SUPERSCRIPT = str.maketrans("0123456789-+", "⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺")


def for_page(result):
    """La réponse de `/v1/trend` (ou d'un job de tendance), pour la page.

    Une fiche à une seule variable par appel : c'est ce que demande la
    vue complète (`dev/decisions.md`). Les familles de fiches viendront
    avec les menus (M3).
    """
    if len(result["data"]) != 1:
        raise ValueError(f"une variable attendue, reçu {sorted(result['data'])}")
    (variable, rows), = result["data"].items()
    meta = next(m for m in result["meta"] if m["variable_en"] == variable)
    relative = bool(meta.get("relative"))
    key = "a_relative" if relative else "a"
    palette = meta["palette"].split()

    slopes = [r[key] for r in rows if r.get(key) is not None]
    edges = class_edges(slopes, len(palette))
    histogram = [0] * len(palette)
    stations = []
    for r in rows:
        slope = r.get(key)
        klass = None if slope is None else class_of(slope, edges)
        if klass is not None:
            histogram[klass] += 1
        stations.append({"code": r["code_station"], "trend": _trend(r),
                         "slope": slope, "class": klass, "p": r.get("p"),
                         "n": r.get("n")})

    out = {
        "variable": {
            "id": variable,
            "name": meta.get("name_fr"),
            "unit": _slope_unit(meta, relative),
            "digits": _digits(edges),
            "relative": relative,
            "palette": palette,
            "edges": edges,
            "histogram": histogram,
        },
        "stations": stations,
        "summary": summary(stations, slopes),
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


def summary(stations, slopes):
    """Le résumé court de M2 : combien de hausses, de baisses, de stations
    sans tendance significative, et la pente médiane."""
    count = {"up": 0, "down": 0, "none": 0}
    for s in stations:
        if s["trend"] in count:
            count[s["trend"]] += 1
    return {**count, "total": len(stations),
            "median": statistics.median(slopes) if slopes else None}


def _trend(row):
    """`up`, `down` ou `none` ; None si le test n'a pas pu se faire."""
    h, a = row.get("h"), row.get("a")
    if h is None or a is None:
        return None
    if not h or a == 0:
        return "none"
    return "up" if a > 0 else "down"


def _slope_unit(meta, relative):
    """L'unité de la pente affichée. Une date (jour de l'année) dérive en
    jours par an, quelle que soit l'unité de la variable."""
    if relative:
        return "% / an"
    if meta.get("is_date"):
        return "jours / an"
    return f"{_unit(meta.get('unit_fr'))} / an".strip()


def _digits(edges):
    """Les décimales qui distinguent deux bornes voisines, avec deux
    chiffres significatifs : 2 pour des pentes de l'ordre du pour cent,
    davantage pour une fréquence qui varie de 1e-4 par an."""
    step = edges[1] - edges[0] if len(edges) > 1 else abs(edges[0]) or 1.0
    return max(0, math.ceil(-math.log10(step)) + 1)


def _unit(unit):
    """`m^{3}.s^{-1}` devient `m³.s⁻¹`."""
    if not unit:
        return ""
    return re.sub(r"\^\{([^}]*)\}",
                  lambda m: m.group(1).translate(_SUPERSCRIPT), unit)
