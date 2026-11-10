> **Statut : livrée, figée.** Exécutée par stase 0.6.5 le 2026-09-18 ;
> le CHANGELOG de stase porte le détail. Le texte ci-dessous n'a pas
> changé depuis sa remise. Les chemins `docs/dev/...` qu'il cite sont
> ceux d'avant le 2026-11-10 : correspondance dans `CHANGELOG.md`.

> **Consigne de passation, écrite le 2026-09-18 depuis `MAKAHO-next`.**
> À lire depuis une session ouverte dans `stase`. Un seul chantier.
>
> Avant de commencer : lire `CLAUDE.md` de `stase` et suivre ses
> conventions (numérotation, CHANGELOG, lint). **Ce document dit quoi et
> pourquoi, pas comment : le comment appartient à `stase`.**

# S1. Le nombre de points sur lequel la tendance est calculée

## D'où ça vient

Audit de migration de MAKAHO (R Shiny vers Flask sur `card-api`), dans
`../../MAKAHO_project/MAKAHO-next/docs/dev/AUDIT.md`, section 7. MAKAHO
marque aujourd'hui en jaune les stations dont la chronique compte moins
de 30 années exploitables sur la fenêtre d'analyse. Il calcule ça
**depuis la chronique journalière**, qu'il n'aura plus une fois branché
sur `card-api`.

La règle des 30 ans reste un choix éditorial de MAKAHO et n'a rien à
faire dans `stase`. **L'ingrédient, lui, manque.**

## Ce qui manque

`stase.trend` ne dit pas sur combien de points le test a porté. Sortie
actuelle :

```
level, h, p, a, b, period_start, period_end, mean_period, a_relative,
variable, a_min, a_max, a_relative_min, a_relative_max
```

**Et ce n'est pas déductible de `period_start` et `period_end`.** Le
code le dit lui-même (`trend.py`, autour de la ligne 77) : ces deux
bornes prennent le min et le max de la colonne de DATES *quels que
soient les NA dans les valeurs*, pour reproduire R. Une série de 56 ans
dont 20 années sont vides annonce donc la même période qu'une série
pleine. C'est exactement l'écart qu'il faut combler.

## Pourquoi c'est dans `stase` et pas ailleurs

Parce que c'est là que l'information existe, et parce que de là elle
remonte **toute seule** : vérifié le 2026-09-18, `card/trend.py` ne
sélectionne aucune colonne et `card_api/serialize.py` sérialise ce qui
est présent. Une modification, trois bénéficiaires (`card`, `card-api`,
MAKAHO).

Et l'information a sa valeur propre, indépendamment de MAKAHO : une
pente sur 12 points ne se lit pas comme une pente sur 55, et rien dans
la réponse actuelle ne permet de faire la différence.

## Ce qu'il y a à faire

Dans `_mk_series` (`src/stase/trend.py`), ajouter au `out.update({...})`
le nombre de valeurs **effectivement utilisées** par le test, c'est à
dire les valeurs non NaN. La quantité est déjà calculée juste au dessus,
`valid = ~np.isnan(X)` : c'est `int(valid.sum())`.

Nom de colonne : `n` est la convention statistique et reste court.
`n_used` lève l'ambiguïté dans une table large. **Le choix appartient à
`stase`**, c'est son contrat ; ce document n'a pas d'avis qui compte
là-dessus.

Vérifier au passage le chemin `_change_series` et les sorties
multi-périodes : si la colonne doit y figurer aussi, c'est à `stase` de
trancher la cohérence de sa propre table.

## Ce qui prouve que c'est fait

Un test sur une série **trouée**, où `n` diffère du nombre de lignes
d'entrée et du nombre d'années entre `period_start` et `period_end`.
Sans trou, le test ne prouve rien.

## Où le consigner

- entrée `## Non publié` du `CHANGELOG.md` de `stase` ;
- la sortie de `trend` change, donc la doctrine de numérotation de
  `stase` s'applique (elle est plus exigeante que celle de `card-api`,
  puisqu'on installe `stase`). **Proposer le geste de version
  soi-même** : l'utilisateur ne le demandera pas.

## Ce qu'il ne faut pas faire

- **Ne pas** ajouter de seuil, de drapeau de qualité ou d'avertissement.
  `stase` rend un nombre. L'interprétation appartient à l'appelant.
- **Ne rien** changer d'autre à la table de sortie à cette occasion.
