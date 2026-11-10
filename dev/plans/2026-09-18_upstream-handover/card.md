> **Statut : livrée, figée.** Exécutée par card le 2026-09-18 (C1 dans
> son `dev/r-origin.md`, C2 par un test) ; le CHANGELOG de card porte le
> détail. Le texte ci-dessous n'a pas changé depuis sa remise. Les
> chemins `docs/dev/...` qu'il cite sont ceux d'avant le 2026-11-10 :
> correspondance dans `CHANGELOG.md`.

> **Consigne de passation, écrite le 2026-09-18 depuis `MAKAHO-next`.**
> À lire depuis une session ouverte dans `card`. Deux chantiers, aucun
> changement de comportement.
>
> Avant de commencer : lire `CLAUDE.md` de `card` et suivre ses
> conventions. **Ce document dit quoi et pourquoi, pas comment.**

# Chantiers pour `card`

## C1. Consigner l'arbitrage de la fenêtre partielle

### Le constat

Le MAKAHO actuel offre un curseur d'échantillonnage à deux modes. Le
second, dit « échantillon », passe à CARD-R un
`sampling_period_overwrite=c("02-01","07-31")`, ce que la doc de
CARD-R décrit ainsi : « ne traiter que les dates entre le 1er février et
le 31 juillet de chaque année » (`CARD_process.R:152`).

`card` refuse cette forme. Vérifié en exécution le 2026-09-18 :

```
stase.extract(..., sampling_period=["02-01","07-31"])  -> OK
card.extract(...,  sampling_period=["02-01","07-31"])  -> ValueError
```

Le moteur sait le faire, `card` refuse. Et ce n'est **ni un oubli ni un
trou de documentation** : `_override_sampling` porte la règle en toutes
lettres, une fenêtre partielle fait partie de la définition de la
variable et n'est jamais écrasée.

### Pourquoi il faut l'écrire ailleurs qu'en docstring

Parce que vue de l'extérieur, cette règle ressemble à une capacité
perdue au portage depuis CARD-R, et quelqu'un rouvrira la porte pour
rendre service. C'est arrivé dans cette session même : l'audit de MAKAHO
a d'abord classé ce refus comme un manque de `card-api`, avant vérification.

### Ce que les chiffres disent

Mesuré sur les 228 chroniques RRSE réelles, 1968-2024. Détail et méthode
dans `../../MAKAHO_project/MAKAHO-next/docs/dev/AUDIT.md` section 5,
reproductible par `MAKAHO-next/scripts/mesure_sampling.py`.

Fenêtre février-juillet imposée à toutes les fiches :

- **87,6 % des étiages annuels du RRSE tombent hors de cette fenêtre**
  (36,2 % en septembre, 28,7 % en août, 15,0 % en octobre) ;
- la valeur encore appelée **VCN10** devient en moyenne **1,61 fois plus
  haute** (médiane 1,51 ; de 0,66 à 3,64) sur 226 stations ;
- **23 % des stations changent de verdict de stationnarité** ;
- le nom, la description et la palette continuent de dire « étiage ».

À comparer au simple déplacement du **départ d'année**, que `card`
autorise :

```
  QA      preferred vs 01-01    15,4 % de verdicts basculent    3,5 % de signes
  tQJXA   preferred vs 01-01    15,4 %                         32,0 % de signes
  VCN10   preferred vs 01-01     0,0 %                          0,0 %   (controle :
                                                     le preferred de VCN10 EST 01-01)
```

Le départ d'année change le résultat, parfois beaucoup (tQJXA est une
date, donc une variable circulaire : son signe dépend du point de
coupe). Mais **on parle toujours de la même variable**. Une fenêtre
partielle, elle, change la variable.

**La ligne que `card` trace entre la chaîne et la liste est donc là où
la science la met.** C'est ce qu'il faut consigner.

### Ce qu'il y a à faire

Écrire la décision là où on lit les décisions de `card`
(`docs/dev/`, à la discrétion de `card` : `CHANTIERS.md` n'est pas le
bon endroit puisque ce n'est pas une piste ouverte). Y mettre la règle,
les chiffres, et le renvoi vers l'audit et le script de mesure.

Conséquence côté MAKAHO, à mentionner comme illustration : le mode
échantillon est supprimé de l'interface. Si un besoin remonte pour une
sous-période qui a un sens hydrologique, elle devient **une fiche**,
avec son nom, sa description et son SWHID.

*Fin :* la décision est écrite, avec sa raison mesurée, et le prochain
qui verra le refus saura que c'en est une.

## C2. Vérifier que le nombre de points traverse

Dépend de `S1` dans `stase` (cf. `POUR_STASE.md`).

Vérifié le 2026-09-18 : `card/trend.py` ne sélectionne aucune colonne,
donc la nouvelle colonne devrait traverser sans rien changer. **Le
vérifier plutôt que le supposer**, et poser un test qui le tient, sans
quoi une future mise en forme de la table la fera disparaître en silence.

*Fin :* un test de `card` constate la présence de la colonne en sortie
de `card.trend`, et l'entrée `## Non publié` du CHANGELOG le dit.

## Ce qu'il ne faut pas faire

- **Ne pas** ouvrir `sampling_period` au couple. C'est tout l'objet de
  C1.
- **Ne pas** ajouter de fiche pour couvrir le mode échantillon de
  MAKAHO. Aucun besoin précis n'a été formulé ; une fiche se crée pour
  une question hydrologique, pas pour préserver un curseur.
