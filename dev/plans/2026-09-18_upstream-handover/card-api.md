> **Statut : livrée, figée.** Exécutée par card-api 0.5.0 à 0.8.0, les
> 2026-09-18 et 19. La version retenue après instruction en diffère sur
> cinq points, chacun signalé dans
> `../../CARD_project/card-api/dev/plans/2026-09-18_cache.md`. Le texte
> ci-dessous n'a pas changé depuis sa remise. Les chemins `docs/dev/...`
> qu'il cite sont ceux d'avant le 2026-11-10 : correspondance dans
> `CHANGELOG.md`.

> **Consigne de passation, écrite le 2026-09-18 depuis `MAKAHO-next`.**
> À lire depuis une session ouverte dans `card-api`. Huit chantiers,
> dont un seul est gros.
>
> Avant de commencer : lire `CLAUDE.md` de `card-api`, qui porte les
> règles du service et les arbitrages qui expliquent sa forme. En
> particulier : aucun décompte ni plafond écrit en clair dans une
> description d'API, `make lint` avec le ruff du venv, discipline de
> version quand le contrat bouge. **Ce document dit quoi et pourquoi,
> pas comment.**

# Chantiers pour `card-api`

## D'où ça vient

Audit de migration de MAKAHO (R Shiny vers Flask sur `card-api`), dans
`../../MAKAHO_project/MAKAHO-next/docs/dev/AUDIT.md`. Mais **la plupart
de ces chantiers ne sont pas des demandes de MAKAHO** : ils corrigent
des choses qui gênent tous les usagers du service. Là où MAKAHO est la
raison, c'est dit.

Ordre conseillé : A1, A2 et A4 ensemble (ils parlent du même cache),
puis A3, puis A5 et A6 dans cet ordre (mesurer avant de régler), puis
A7. A8 quand `S1` de `stase` est livré.

## A1. Sortir la TTL du code et la passer au mois

`CACHE_TTL = 24 * 3600` est écrit en dur dans `hubeau.py:40`. Le défaut
principal n'est pas la valeur : c'est qu'une décision de politique ne
soit pas réglable, alors que tous les autres plafonds du service sont
dans `.env`.

**La justification de la nouvelle valeur est dans le corpus, pas dans un
usage.** Vérifié sur les 472 fiches : aucune ne produit une série plus
fine que le mois (133 par mois, 57 annuelles, 44 par saison, 17
estivales, 16 hivernales). **Un rafraîchissement plus fréquent que
mensuel ne peut donc changer aucune sortie de série.**

Les deux objections, qui ne tiennent pas :

- les 29 fiches `record` se calculent sur toute la chronique, donc un
  jour de plus les change. Mais un quantile sur vingt mille jours ne se
  déplace pas parce qu'on en ajoute quinze ;
- le mois en cours incomplet : soit `max_na_pct` et `max_na_years`
  l'écartent, soit il passe et il est faux. Une demi-période ne sert pas
  plus que pas de période.

*Fin :* valeur dans `.env`, justification dans `docs/dev/API.md` **sous
forme de règle et non de nombre recopié**, test qui vérifie qu'elle est
lue de la configuration.

## A2. Écrire la règle de la chronique entière

**Une chronique se télécharge entière, jamais par morceaux recollés.**

Hub'Eau révise n'importe quel point de l'historique, pas seulement la
queue récente. Un rafraîchissement partiel ne donnerait donc pas une
donnée « un peu périmée » : il donnerait **une chronique qui n'a jamais
existé chez Hub'Eau**, un corps historique d'une révision recollé à une
queue d'une autre. Et `data_fingerprint`, calculée sur les octets des
colonnes, signerait cet assemblage : une empreinte stable, reproductible,
et qui ne désigne aucun état réel de la source. C'est le contraire de ce
à quoi elle sert.

Ce n'est donc pas une optimisation à instruire plus tard, c'est une
règle à écrire **pour que personne ne la retrouve** : l'idée de ne
rafraîchir que la queue revient dès qu'on regarde une facture de bande
passante. Elle a été proposée dans cette session même, et corrigée par
l'utilisateur.

*Fin :* la règle est dans `API.md` avec son raisonnement complet, et le
code ne permet pas de faire autrement.

## A3. `max_age` : la fraîcheur comme affaire de requête

Une TTL longue sert l'analyse de tendance et dessert celui qui suit
l'étiage en cours. Plutôt qu'un arbitrage impossible côté serveur, un
paramètre de requête qui dit le besoin : `max_age=<jours>`, « je
n'accepte pas plus vieux que N jours ». Le serveur re-télécharge
seulement si sa copie dépasse.

**Préférer cette forme à `refresh=true`** : `max_age` dit le *besoin*,
`refresh` dit l'*action*, donc se met dans une boucle et tape sur
Hub'Eau à travers le service. C'est aussi la sémantique de
`Cache-Control: max-age`, donc rien à inventer. La réponse porte déjà
`data_fetched_at` : le client vérifie ce qu'il a reçu.

Celui qui fait de la tendance ne passera jamais ce paramètre et n'a pas
besoin de savoir qu'il existe.

*Fin :* le paramètre existe, il est documenté par la règle et non par une
valeur, un test couvre le cas où la copie est trop vieille. Le contrat
bouge, donc `api_version`.

## A4. Le pool qui se garde chaud tout seul

Rafraîchir périodiquement **ce qui est déjà dans le cache**. L'ensemble
de travail se définit alors de lui-même : ce que les gens consultent
reste chaud, et le service n'a besoin d'aucune liste de client. Il
continue de ne pas savoir ce qu'est le RRSE, ce qui est voulu.

Deux garde-fous :

- **une éviction**, sinon le pool ne fait que grossir : une station qu'on
  n'a pas demandée depuis N mois en sort ;
- le rafraîchissement retélécharge **la chronique entière** (A2).

Rappel du chiffre qui motive : aller chercher coûte environ 1,2 s par
station, calculer environ 0,04 s. Trente fois.

*Fin :* le pool tourne, l'éviction est testée, `make stats` montre sa
taille.

## A5. Le cache d'extraction, le second étage

**Le chantier qui compte le plus.** Déjà prévu dans `API.md` sous
« cache à deux étages » : les résultats d'extraction par (station,
fiche, version de fiche, fenêtre d'échantillonnage). L'invalidation est
offerte par la discipline de versions des fiches.

Ce qu'il change, et qu'aucune TTL ne peut changer : une TTL longue
supprime le **téléchargement**, ce second étage supprime
l'**agrégation**. Sur un réseau de 228 stations, c'est environ 9 s par
demande, payées aujourd'hui par chaque appelant, à chaque changement de
variable, derrière le sémaphore de calcul donc partagées entre tous.

C'est la différence entre un service qu'on essaie et un service dont on
dépend. MAKAHO en dépend, mais il n'est pas le seul intéressé.

*Fin :* un second appel identique ne recalcule rien, et un changement de
version de fiche invalide. Les deux tenus par un test.

## A6. Mesurer, puis relever le plafond synchrone

Une fois A5 en place : combien coûte réellement un `/v1/trend` de 228
stations tout en cache ? La réponse commande `SYNC_STATIONS_CACHED`, qui
vaut 60 aujourd'hui.

**Mesurer avant de régler.** C'est déjà la doctrine du service pour les
quotas par IP (« les valeurs se règlent sur l'observation plutôt que sur
l'intuition »), elle vaut ici aussi.

Ici MAKAHO est bien la raison : il demande 228 stations dans sa vue par
défaut, et un job à chaque changement de variable serait une régression
d'ergonomie franche par rapport à l'application R actuelle.

*Fin :* la mesure est consignée, la valeur est dans `.env`, `/v1` la
publie comme les autres. Jamais recopiée dans une description.

## A7. Exposer la chronique journalière

Le service la détient déjà en cache, avec son empreinte et sa date de
collecte, mais ne la rend pas : aucune fiche à entrée `Q` ne restitue la
chronique brute (les fiches `season: record` produisent des scalaires).

MAKAHO en a besoin pour tracer la station qu'on vient de cliquer : une
station à la fois, à la demande, 0,2 s à chaud. Sans cela il doit
interroger Hub'Eau lui-même, et **la même page affiche alors deux
provenances pour un même débit**.

*Fin :* la chronique se récupère par une URL, avec `data_fetched_at` et
`data_fingerprint` comme le reste. Le contrat bouge, donc `api_version`.

## A8. Remonter le nombre de points

Dépend de `S1` dans `stase` (cf. `POUR_STASE.md`).

Vérifié le 2026-09-18 : `card/trend.py` ne sélectionne aucune colonne et
`card_api/serialize.py` sérialise ce qui est présent. Le champ devrait
donc traverser sans rien changer. **Le vérifier**, et poser un test.

Ce que ça apporte au service, indépendamment de MAKAHO : une pente sur
12 points ne se lit pas comme une pente sur 55, et rien dans la réponse
actuelle ne permettait de faire la différence (`period_start` et
`period_end` prennent les bornes de dates **sans regarder les NA**).

*Fin :* le champ est dans la réponse et dans l'OpenAPI. Le contrat bouge,
donc `api_version` se publie le jour de la livraison.

## Deux points annexes relevés en passant

- **La production est en retard sur `main`** : elle tourne `card` 0.4.0,
  commit du 2026-08-05, alors que `main` est en 0.13.0 (2026-08-17).
  Le `make update` n'a pas tourné depuis six semaines. Sans gravité,
  mais ce qu'on mesure contre la production n'est pas ce que disent les
  dépôts.
- `docs/dev/CHANTIERS.md` ne contenait qu'une piste ouverte le
  2026-09-18 (rendre le catalogue lisible). Ces huit chantiers viennent
  s'y ajouter.

## Ce qu'il ne faut pas faire

- **Ne pas** donner à `card-api` la moindre notion de RRSE, de réseau de
  référence, ou de liste de stations d'un client. A4 existe précisément
  pour éviter ça.
- **Ne pas** ajouter d'indicateur de qualité de chronique. La règle des
  30 ans est un choix éditorial de MAKAHO. Le service rend des faits
  (A8), l'interprétation appartient à l'appelant.
- **Ne pas** écrire les nouvelles valeurs de plafond ou de TTL en clair
  dans une description d'API. La règle existe déjà dans `CLAUDE.md`, et
  elle a été payée deux fois.
