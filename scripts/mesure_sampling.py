"""Sensibilité des tendances au curseur d'échantillonnage de MAKAHO.

Reproduit les chiffres de `dev/audits/2026-09-18_migration.md` section 5,
qui justifient la suppression du mode échantillon et la conservation du
départ d'année.
Ces chiffres seront contestés un jour : ce script existe pour qu'on
puisse les refaire au lieu de les croire.

Deux mesures, sur les 228 stations du RRSE :

  A. DÉPART D'ANNÉE. Compare `preferred` à des départs fixes, et compte
     les stations dont le verdict de stationnarité bascule et celles
     dont la pente change de signe. Passe par `card`, donc c'est
     exactement ce que MAKAHO produit.

  B. FENÊTRE PARTIELLE. Où tombent réellement les étiages, et ce que
     devient un « VCN10 » calculé sur février-juillet. `card` refuse le
     couple (c'est la décision documentée dans `_override_sampling`),
     la mesure reproduit donc VCN10 hors de `card` : moyenne mobile
     10 jours centrée puis minimum via `stase`. C'est l'ordre de
     grandeur qui compte, pas la troisième décimale.

Entrée : le cache de chroniques de card-api, qui contient déjà les 228
stations en CSV gzippés (`id,date,Q`). Aucun appel réseau, donc aucune
charge sur Hub'Eau ni sur le service.

    python scripts/mesure_sampling.py [--cache CHEMIN] [--stations CHEMIN]

Environnement : celui de `card` (`card`, `stase`, `pandas`, `numpy`),
par exemple `../../CARD_project/card/.python_env/bin/python`.
Durée : quelques minutes.
"""

import argparse
import collections
import os
import warnings

import numpy as np
import pandas as pd

import card
import stase

# Résolus depuis l'emplacement du script, pour que la commande marche
# quel que soit le répertoire courant.
_RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_CARD_API = os.path.normpath(
    os.path.join(_RACINE, "..", "..", "CARD_project", "card-api"))
CACHE_DEFAUT = os.path.join(_CARD_API, "data", "chroniques")
STATIONS_DEFAUT = os.path.join(_CARD_API, "examples", "stations_rrse.txt")

DEBUT, FIN = "1968-01-01", "2024-08-31"
CARTES = ["QA", "VCN10", "tQJXA"]
DEPARTS = ["preferred", "01-01", "05-01"]
FENETRE = ["02-01", "07-31"]
NIVEAU, DEPENDANCE = 0.1, "AR1"
MOIS = ["jan", "fev", "mar", "avr", "mai", "jun",
        "jui", "aou", "sep", "oct", "nov", "dec"]


def chroniques(cache, stations):
    """Les chroniques RRSE présentes dans le cache, une par station."""
    codes = [c.strip() for c in open(stations) if c.strip()]
    for code in codes:
        chemin = os.path.join(cache, f"{code}.csv.gz")
        if not os.path.exists(chemin):
            continue
        df = (pd.read_csv(chemin, parse_dates=["date"])
              .rename(columns={"id": "code"}))
        df = df[(df.date >= DEBUT) & (df.date <= FIN)]
        if len(df) >= 3650:          # au moins dix ans, sinon rien à dire
            yield code, df.copy()


def une_tendance(serie, colonne):
    t = stase.trend(serie[["code", "date", colonne]],
                    level=NIVEAU, dependency=DEPENDANCE)
    ligne = t.iloc[0]
    return bool(ligne["h"]), float(ligne["p"]), float(ligne["a"])


def mesure_depart(chrons):
    """A. Ce que change le départ d'année, carte par carte."""
    res = collections.defaultdict(dict)
    for code, df in chrons:
        for depart in DEPARTS:
            try:
                r = card.extract(df, cards=CARTES, sampling_period=depart)
            except Exception:
                continue
            for c in CARTES:
                serie = r["data"].get(c)
                if serie is None:
                    continue
                col = next(x for x in serie.columns
                           if x not in ("code", "date"))
                try:
                    res[(c, depart)][code] = une_tendance(serie, col)
                except Exception:
                    pass

    print("\nA. DÉPART D'ANNÉE\n")
    print(f"  {'carte':<8} {'comparaison':<24} "
          f"{'verdicts qui basculent':>24} {'pentes de signe change':>24}")
    for c in CARTES:
        base = res[(c, "preferred")]
        for depart in DEPARTS[1:]:
            autre = res[(c, depart)]
            communs = sorted(set(base) & set(autre))
            n = max(len(communs), 1)
            bascules = sum(1 for k in communs if base[k][0] != autre[k][0])
            signes = sum(1 for k in communs
                         if np.sign(base[k][2]) != np.sign(autre[k][2]))
            print(f"  {c:<8} {'preferred vs ' + depart:<24} "
                  f"{bascules:>8} / {len(communs):<3} ({100 * bascules / n:>5.1f} %) "
                  f"{signes:>8} / {len(communs):<3} ({100 * signes / n:>5.1f} %)")
    print("\n  Contrôle : VCN10 vs 01-01 doit donner 0,0 %, son `preferred`\n"
          "  ÉTANT 01-01. Un chiffre non nul signale une mesure fausse.")


def mesure_fenetre(chrons):
    """B. Ce que fabrique une fenêtre partielle février-juillet."""
    hors = {1, 8, 9, 10, 11, 12}
    mois_min = collections.Counter()
    rapports, bascules, n_ok = [], 0, 0

    for code, df in chrons:
        df["Q10"] = df["Q"].rolling(10, center=True, min_periods=10).mean()

        for _, an in df.groupby(df.date.dt.year):
            if an["Q10"].notna().sum() > 300:
                mois_min[an.loc[an["Q10"].idxmin(), "date"].month] += 1

        f = {"VCN10": (np.nanmin, "Q10")}
        try:
            plein = stase.extract(df, f, time_step="year",
                                  sampling_period="01-01")
            partiel = stase.extract(df, f, time_step="year",
                                    sampling_period=FENETRE)
        except Exception:
            continue
        if plein["VCN10"].notna().sum() < 30 or partiel["VCN10"].notna().sum() < 30:
            continue

        n_ok += 1
        rapports.append(partiel["VCN10"].mean() / plein["VCN10"].mean())
        try:
            if une_tendance(plein, "VCN10")[0] != une_tendance(partiel, "VCN10")[0]:
                bascules += 1
        except Exception:
            pass

    total = sum(mois_min.values())
    crete = max(mois_min.values())
    print(f"\nB. FENÊTRE PARTIELLE {FENETRE[0]} à {FENETRE[1]}\n")
    print("  Où tombe réellement le minimum 10 jours, sur tout le RRSE :")
    for m in range(1, 13):
        n = mois_min.get(m, 0)
        marque = "   hors fenetre" if m in hors else ""
        print(f"    {MOIS[m - 1]}  {100 * n / total:>5.1f} %  "
              f"{'#' * int(55 * n / crete)}{marque}")
    exclus = sum(mois_min.get(m, 0) for m in hors)
    print(f"\n    => {100 * exclus / total:.1f} % des étiages annuels tombent "
          f"HORS de la fenêtre")

    r = np.array(rapports)
    print(f"\n  VCN10 année pleine vs fenêtre partielle, {n_ok} stations :")
    print(f"    la valeur dite « VCN10 » est en moyenne {r.mean():.2f} x plus haute")
    print(f"    (médiane {np.median(r):.2f} ; de {r.min():.2f} à {r.max():.2f})")
    print(f"    verdict de stationnarité qui bascule : {bascules} / {n_ok} "
          f"({100 * bascules / max(n_ok, 1):.1f} %)")


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--cache", default=CACHE_DEFAUT,
                   help="répertoire des chroniques gzippées de card-api")
    p.add_argument("--stations", default=STATIONS_DEFAUT,
                   help="fichier des codes RRSE, un par ligne")
    a = p.parse_args()

    warnings.simplefilter("ignore")
    chrons = list(chroniques(a.cache, a.stations))
    print(f"{len(chrons)} stations RRSE lues dans {a.cache}")
    print(f"période {DEBUT} à {FIN}, niveau {NIVEAU}, dépendance {DEPENDANCE}")
    print(f"card {getattr(card, '__version__', '?')}")

    mesure_depart(chrons)
    mesure_fenetre(chrons)


if __name__ == "__main__":
    main()
