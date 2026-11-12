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

"""Les menus du panneau d'analyse, tirés du catalogue de card-api.

MAKAHO n'écrit aucune liste de fiches : il propose celles que card-api
sait tester sur le débit, c'est-à-dire à entrée Q seule et à sortie en
série (`/v1/trend` refuse une fiche à sortie scalaire). Le rangement
vient des facettes du catalogue, nommées par `/v1/vocabulary` :

- le régime est la facette `phenomenon`, dans l'ordre de la 1.0.0 ;
- dans un régime, les fiches se suivent par aspect (intensité, durée,
  fréquence, saisonnalité), puis dans l'ordre du catalogue ;
- la facette `season` sépare l'année entière (annuelle, par mois, par
  saison) de l'été et de l'hiver ;
- une fiche à plusieurs variables (QMA, un mois par variable) est un
  seul bouton, dont la page choisit ensuite la variable. Un paquet dont
  chaque variable existe aussi en fiche seule (allLF) est laissé : ses
  fiches suffisent.

Le regroupement par paramètre de la 1.0.0 (QpA pour Q25A, Q50A et Q75A)
n'est pas repris : aucune facette ne le porte, et le deviner sur la
forme des noms est exclu (`dev/plans/2026-11-12_m3-analysis.md`).
"""

import os
import re

from .trends import MIN_YEARS, MONTHS, window_bounds

# L'ordre des régimes de la 1.0.0 (relevé du 2026-11-11), par identifiant
# de la facette `phenomenon`.
REGIMES = ("high-flows", "mean-flows", "low-flows", "baseflow")

# L'ordre des aspects dans un régime.
ASPECTS = ("magnitude", "duration", "frequency", "timing")

# La facette `season`, ramenée aux trois choix du panneau.
_SEASON = {"annual": "year", "by-month": "year", "by-season": "year",
           "summer": "summer", "winter": "winter"}
SEASONS = {"year": "Année", "summer": "Été", "winter": "Hiver"}

# Les risques proposés, ceux de la 1.0.0. `views` refuse tout autre.
LEVELS = (0.01, 0.05, 0.1)

# La première année du curseur de période, celle de la 1.0.0.
FIRST_YEAR = 1900


def menus(cards, vocabulary, default_card):
    """Les menus de la page, à partir des réponses de `/v1/cards` et de
    `/v1/vocabulary`."""
    ids = _facet_ids(vocabulary["vocabulary"])
    entries = [c for c in cards["cards"]
               if (c.get("input_vars") or "").strip() == "Q"
               and c.get("output_en") == "series"]

    by_card = {}
    for c in entries:
        by_card.setdefault(c["card"], []).append(c)
    alone = {cid for cid, rows in by_card.items()
             if len(rows) == 1 and rows[0]["variable_en"] == cid}

    regimes = {r: [] for r in REGIMES}
    for cid, rows in by_card.items():
        if len(rows) > 1 and all(r["variable_en"] in alone for r in rows):
            continue
        first = rows[0]
        regime = ids["phenomenon"].get(first.get("phenomenon_en"))
        if regime not in regimes:
            continue
        aspect = ids["aspect"].get(first.get("aspect_en"))
        rank = ASPECTS.index(aspect) if aspect in ASPECTS else len(ASPECTS)
        card = _card(cid, rows, ids)
        regimes[regime].append(((rank, _natural(card["label"])), card))

    out = []
    for regime, items in regimes.items():
        if not items:
            continue
        found = [c for _, c in sorted(items, key=lambda t: t[0])]
        seasons = [s for s in SEASONS if any(c["season"] == s for c in found)]
        out.append({
            "id": regime,
            "label": _title(vocabulary["vocabulary"]["phenomenon"][regime]["fr"]),
            "seasons": [{"id": s, "label": SEASONS[s]} for s in seasons],
            "cards": found,
        })
    return {
        "regimes": out,
        "default": default_card,
        "levels": list(LEVELS),
        "period": {"first": FIRST_YEAR, "min_years": MIN_YEARS},
        "months": list(MONTHS),
    }


def _natural(label):
    """L'ordre naturel : VCN3, VCN10, VCN30, et non VCN10, VCN3, VCN30."""
    return [int(p) if p.isdigit() else p for p in re.split(r"(\d+)", label)]


def _card(cid, rows, ids):
    """Un bouton de fiche : son libellé, sa saison, le mois où commence
    l'année qu'elle déclare (le curseur de l'année hydrologique part de
    là ; None s'il n'a pas d'objet), et ses variables si elle en a
    plusieurs."""
    first = rows[0]
    season_id = ids["season"].get(first.get("season_en"))
    preferred = first.get("preferred_sampling_period")
    card = {
        "id": cid,
        "season": _SEASON.get(season_id, "year"),
        "preferred_month": int(preferred[:2]) if preferred else None,
    }
    if len(rows) == 1:
        label = first["variable_en"]
        suffix = f"_{season_id}"
        if season_id in ("summer", "winter") and label.endswith(suffix):
            label = label[:-len(suffix)]
        card.update(label=label, sub=None, name=first.get("name_fr"),
                    variables=None)
    else:
        prefix = os.path.commonprefix([r["variable_en"] for r in rows])
        card.update(
            label=prefix.rstrip("_") or cid,
            sub=(first.get("season_fr") or "").removeprefix("par ") or None,
            name=None,
            variables=[{"id": r["variable_en"],
                        "label": _window_label(r.get("sampling_period_fr"))
                        or r["variable_en"],
                        "name": r.get("name_fr")} for r in rows])
    return card


def _window_label(text):
    """`01-01, 31-01` donne `janv.`, `01-12, 28(29)-02` donne
    `déc. à févr.` : le nom court d'une variable mensuelle ou
    saisonnière."""
    window = window_bounds(text)
    if not window:
        return None
    (_, m1), (_, m2) = window
    if m1 == m2:
        return MONTHS[m1 - 1]
    return f"{MONTHS[m1 - 1]} à {MONTHS[m2 - 1]}"


def _facet_ids(vocabulary):
    """Pour chaque facette, l'identifiant d'après le libellé anglais que
    porte une fiche (`phenomenon_en` : « low flows » donne
    `low-flows`)."""
    return {facet: {names["en"]: fid for fid, names in values.items()}
            for facet, values in vocabulary.items()}


def _title(text):
    """« débit de base » devient « Débit de Base », comme dans la 1.0.0."""
    return " ".join(w if len(w) <= 2 else w[0].upper() + w[1:]
                    for w in text.split())
