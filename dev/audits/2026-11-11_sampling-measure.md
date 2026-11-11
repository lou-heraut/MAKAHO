> **Statut : mesure datée, close.** Relance, le 2026-11-11, de la mesure
> qui justifie la décision 4 (`dev/decisions.md`), par
> `scripts/mesure_sampling.py` (`make measure`), désormais entièrement
> par card-api. Ne change plus ; la prochaine relance fera son propre
> fichier.

# La mesure du curseur d'échantillonnage, relancée par card-api

## Ce qui a changé depuis la mesure de l'audit

La section 5 de `dev/audits/2026-09-18_migration.md` a été mesurée le
2026-09-18 sur le cache local de card-api, avec card 0.13.0 et stase
0.6.1 en local. Ici :

- **Mesure A** (départ d'année) : les tendances sont celles que rend
  `/v1/trend` avec `sampling=preferred`, `01-01` ou `05-01`, c'est-à-dire
  exactement ce que MAKAHO affichera.
- **Mesure B** (fenêtre partielle) : les chroniques viennent de
  `/v1/chronicles`. VCN10 sur février-juillet est refait en local avec
  stase, card refusant ce calcul. La moyenne sur 10 jours est prise sur
  le calendrier complet, et non plus sur les seules lignes que publie
  Hub'Eau, qui omet les jours manquants (relevé par la revue de M1).

## Ce que ça donne

Les conclusions de l'audit tiennent.

- **Mesure B : identique**, à un dixième près sur deux mois (septembre
  36,1 % au lieu de 36,2 %, octobre 15,1 % au lieu de 15,0 %) : 87,6 %
  des étiages hors de la fenêtre, une valeur 1,61 fois plus haute, 23,0 %
  de verdicts qui basculent, sur 226 stations.
- **Mesure A : à une ou deux stations près.** QA contre 01-01, 34
  verdicts basculent au lieu de 35 (signe : 6 au lieu de 8) ; QA contre
  05-01, signe 4 au lieu de 5 ; VCN10 contre 05-01, 5 au lieu de 6 ;
  tQJXA contre 05-01, 26 au lieu de 28. Le contrôle VCN10 contre 01-01
  reste à zéro, et tQJXA retourne toujours le signe de la pente d'un
  tiers du réseau. Les écarts tiennent à la donnée, lue deux mois plus
  tard chez Hub'Eau, et à card 0.13.2.
- Une passe faite juste avant, avec la moyenne prise sur les lignes,
  donne les mêmes chiffres à ces deux dixièmes près.

## La sortie

```
228 stations du RRSE, période 1968-01-01 à 2024-08-31, niveau 0.1, dépendance AR1
A. DÉPART D'ANNÉE
  fiche    comparaison                verdicts qui basculent   pentes de signe change
  QA       preferred vs 01-01             34 / 228 ( 14.9 %)        6 / 228 (  2.6 %)
  QA       preferred vs 05-01             22 / 228 (  9.6 %)        4 / 228 (  1.8 %)
  VCN10    preferred vs 01-01              0 / 228 (  0.0 %)        0 / 228 (  0.0 %)
  VCN10    preferred vs 05-01              5 / 228 (  2.2 %)        4 / 228 (  1.8 %)
  tQJXA    preferred vs 01-01             35 / 228 ( 15.4 %)       73 / 228 ( 32.0 %)
  tQJXA    preferred vs 05-01             26 / 228 ( 11.4 %)       56 / 228 ( 24.6 %)
  Contrôle : VCN10 contre 01-01 doit donner 0,0 %, son `preferred`
  ÉTANT 01-01. Un chiffre non nul signale une mesure fausse.
  Contrôle : tous les appels ont lu la même donnée (une seule empreinte).
B. FENÊTRE PARTIELLE 02-01 à 07-31
  Où tombe réellement le minimum sur 10 jours, sur tout le RRSE :
    jan    1.6 %  ##   hors fenetre
    fev    1.2 %  #
    mar    0.6 %  
    avr    0.2 %  
    mai    0.3 %  
    jun    1.6 %  ##
    jui    8.5 %  ############
    aou   28.7 %  ###########################################   hors fenetre
    sep   36.1 %  #######################################################   hors fenetre
    oct   15.1 %  ######################   hors fenetre
    nov    3.7 %  #####   hors fenetre
    dec    2.3 %  ###   hors fenetre
    => 87.6 % des étiages annuels tombent HORS de la fenêtre
  VCN10 année pleine contre fenêtre partielle, 226 stations :
    la valeur dite « VCN10 » est en moyenne 1.61 fois plus haute
    (médiane 1.51 ; de 0.66 à 3.64)
    verdict de stationnarité qui bascule : 52 / 226 (23.0 %)
Provenance (mesure A, card-api) :
  api_version       0.9.1
  card_version      0.13.2
  card_commit       0979573231e139b9879b142b7a0b7eb731f6103f
  stase_version     0.6.7
  stase_commit      7307ff8e9e5c8f430bebb606b631db9feb773f21
  data_fetched_at   2026-11-05T23:06:09+00:00
  data_fingerprint  v2:de3c45ffb14f81edd8ba2c187f5f43caa5b48e9647580b720de71c3be96668c1
  stase local       0.6.7 (mesure B)
```
