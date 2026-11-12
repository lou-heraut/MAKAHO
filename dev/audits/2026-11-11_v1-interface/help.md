> **Statut : relevé daté, clos.** Le texte des 16 pages de l'aide guidée
> de MAKAHO 1.0.0, relevé dans la page en ligne le 2026-11-11, tel
> quel : titre, sous-titre et texte se suivent sur une ligne, les
> passages en gras sont perdus. Matière pour M7 (`ROADMAP.md`), qui
> reprend ce contenu là où il sert. Le contexte :
> `dev/audits/2026-11-11_v1-interface.md`.

# L'aide guidée de MAKAHO 1.0.0

## Page 1
MAKAHO MAKAHO (pour MAnn-Kendall Analysis of Hydrological Observations) est un système de visualisation cartographique interactif permettant de calculer les tendances présentes dans les données des stations hydrométriques aux débits peu influencés par les actions humaines. Le test de Mann-Kendall permet d’analyser la significativité des tendances de variables hydrologiques sur les différentes composantes du régime des cours d'eau (étiages, moyennes-eaux, crues), à mettre ensuite en relation avec les impacts du changement climatique sur l’hydrologie de surface.

## Page 2
FOND DE CARTE STRUCTURE L’interface de MAKAHO se concentre autour d’une carte interactive. Le planisphère est recouvert de cercles et de triangles de couleur différentes qui permettent de situer les stations hydrométriques sélectionnées et de donner une idée de l’intensité de la tendance estimée. Un cercle indique que la tendance n’est pas significative alors qu’un triangle indique que la tendance est significative. Un triangle pointant vers le haut (respectivement vers le bas) indique que la tendance est à la hausse (respectivement à la baisse). Une station non-sélectionnée pour l'analyse est représentée par un cercle de couleur neutre.

## Page 3
FOND DE CARTE INTERACTION Le fond de carte est interactif, cela veut dire qu’il est possible de se déplacer sur le planisphère en effectuant un clic gauche glisser. De la même manière, il est aussi possible de zoomer en effectuant un roulement de la molette de souris. Les cercles et triangles sont aussi cliquables. Par défaut, le clic sur une station permet d’afficher le graphique détaillé de l’analyse de tendance de la variable étudiée.

## Page 4
ZOOM Les interactions avec le fond de carte font apparaître le bouton de zoom en haut à gauche qui permet de re‐faire le focus sur l’ensemble des stations sélectionnées. Ainsi, si la sélection de stations est réduite, ce même bouton peut apparaître afin de laisser la possibilité à l’utilisateur de laisser l’application choisir le zoom et le positionnement de carte le plus adapté. Lorsque le positionnement est optimal sur une sélection, un bouton de zoom différent apparaît à la même place. Ce nouveau bouton permet alors de re‐faire le focus non pas sur la sélection de station mais sur la France entière. Le mieux c'est d'essayer !

## Page 5
ANALYSE SÉLECTION Les deux premiers boutons de la section de sélection permettent respectivement de sélectionner toutes les stations ou aucunes. Le troisième bouton de la ligne est le bouton de sélection par clic sur la carte. Une fois ce mode activé, un clic sur une station permet de changer son état de sélection. Lors du lancement de ce mode, une barre d'outil apparaît en haut à gauche et permet de terminer la sélection. Le quatrième bouton correspond au bouton de sélection par polygone sur la carte. Un polygone peut donc être tracé en plaçant des points sur la carte. Comme dans le mode précédent, une barre d'outil apparaît en haut à gauche de l’interface et permet de rendre la sélection par polygone additive ou soustractive.

## Page 6
ANALYSE SÉLECTION Le bouton avertissement est présent sur la seconde ligne. Lorsqu'il est sélectionné, comme par défaut, les stations qui présentent des chroniques de moins de 30 ans sont localisées par des symboles aux contours jaunes et lorsque les chroniques sont complètement manquantes, les symboles utilisés sont des cercles aux contours rouges. Dans le cas où le bouton avertissement est déselectionné, les stations qui présentent des avertissements sont retirées automatiquement de la sélection. Enfin, la sélection peut se faire à l'aide d'une barre de recherche textuelle avec complétion automatique. Des stations peuvent être sélectionnées à l’aide de mots-clés contenus dans leur nom, le nom de leur cours d’eau, le lieu où elles sont situées de même que leur région‐hydrographique et bassin‐hydrographique. Ce mode de sélection est additif et il est possible d’ajouter ou de supprimer plusieurs recherches textuelles.

## Page 7
ANALYSE RÉGIME ET VARIABLE La sélection de la variable hydrologique utilisée pour l'analyse de tendance s'effectue à l'aide des sections Régime et Variable. La section Régime permet de sélectionner la composantes du régime des cours d'eau que l'on souhaite étudié : Crue, Écoulements Lents, Moyennes Eaux ou Étiage. Chaque bouton permet d'afficher un panneau de variables caractéristiques de l'étude du régime choisi. La section Variable permet dans un second temps de sélectionner la variable que l'on souhaite étudier.

## Page 8
ANALYSE ANNÉE HYDROLOGIQUE L’analyse de tendance présente un premier paramètre temporel qui est sélectionné grâce à la section Année Hydrologique. Le mois de début de l’Année Hydrologique est par défaut est fixé sur le mois de janvier. Ce choix se fait à l’aide d’un curseur horizontal simple. Juste en dessous, le bouton Optimale permet de sélectionner automatiquement une année hydrologique. Ce choix est basé sur des considérations hydrologiques propres à chaque station. Pour une variable de Crue ou de Moyennes Eaux le mois de début de l'année hydrologique est sélectionné pour chaque station comme le mois où le débit moyen mensuel est minimal. Pour une variable de Écoulements Lents, le mois de janvier est pris pour mois de début et pour une variable d'Étiage l'année hydrologique commence en mai et finie fin novembre.

## Page 9
ANALYSE ANNÉE HYDROLOGIQUE Lorsque le bouton Optimale n'est pas sélectionné, il est possible d'appuyer sur le bouton Intervalle. Ce mode permet de sélectionner une année hydrologique tronquée pour réaliser une analyse saisonnalisée. Ce choix se fait à l'aide d'un double curseur horizontal et peut être inversé à l'aide du bouton inverser qui apparaît à la suite en mode intervalle. PÉRIODE Le second aspect temporel est le choix de la période d’analyse de tendance. Cette sélection se fait avec un double curseur horizontal qui permet de choisir une date de début et de fin de la période d’analyse. L’année de fin est incluse et par défaut la période temporelle s’étend de l’année 1968 à 2020.

## Page 10
ANALYSE SIGNIFICATIVITÉ La dernière section correspond au seuil de significativité du test statistique de Mann‐Kendall, c’est‐à‐dire la probabilité avec laquelle on accepte de se tromper sur l’affirmation de l’existence d’une tendance. Le choix de ce seuil est fait à l’aide de boutons qui permettent de sélectionner la valeur de 1%, 5% ou 10%. Par défaut, la valeur de 10% est sélectionnée ce qui s’avère être la valeur la moins contraignante. Il est important de noter que la valeur numérique de la tendance est calculée grâce à l'estimateur de Sen mais cette dernière ne renseigne en rien sur la significativité de cette tendance. Il est tout à fait possible de calculer une forte tendance avec Sen mais de ne trouver aucune significativité avec Mann-Kendall. ACTUALISATION Une fois les paramètres de l'analyse modifiés comme souhaité, il est nécessaire d'appuyer sur le bouton d'actualisation apparu à droite du bouton d'analyse pour afficher les nouveaux résultats.

## Page 11
AFFICHAGE ÉCHELLE DE COULEUR Lorsque l'utilisateur appui sur la roue dentée en bas à droite du panneau d'analyse, la fenêtre de paramètre d'affichage graphique s'affiche. Il est possible d’afficher ou non sur l’interface l'échelle de couleur des tendances. Cette échelle est évolutive en fonction de la sélection de stations et associe une couleur marron à une tendance avec un impact `négatif` et turquoise à une tendance avec un impact `positif`. Elle est symétrique, centrée sur zéro et discrète en dix classes. La classe extrême positive (respectivement négative) comprend les valeurs du quantile 99% (respectivement 1%) à l'infini (respectivement moins l'infini).

## Page 12
AFFICHAGE RESUMÉ Le panneau de résumé de l'analyse statistique présent en haut du côté droit de l'interface peut être affiché ou non selon la volonté de l'utilisateur. Le nom de la variable étudiée et sa définition sont récapitulés dans cet encart suivi de l'année hydrologique utilisée, de la période d'analyse et la significativé du test de tendance réalisé. FOND DE CARTE Trois thèmes de couleur sont disponibles pour personnaliser le fond de carte : un thème Clair, un thème en couleur appelé Terrain qui représente les reliefs et un thème Sombre. Le thème par défaut est le thème Clair.

## Page 13
MODE PHOTO Ce mode permet d'enlever l'interface inutile à la capture d'écran du fond de carte. Seuls les panneaux de l'échelle de couleur et du résumé de l'analyse resteront visibles. L'utilisateur peut donc redimensionner la fenêtre de son navigateur afin d'effectuer une capture d'écran. Un simple clic sur la carte permet de faire réapparaître l'interface.

## Page 14
FICHES STATIONS Il est possible de télécharger des fiches stations récapitulative de l'analyse de tendance en cliquant sur le bouton en haut à droite. Dans la barre d'outil qui est apparue, le premier bouton est le bouton de téléchargement par clic sur la carte. Une fois ce mode activé, un clic sur une station permet de télécharger la fiche station associée. Lors du lancement de ce mode, une nouvelle barre d'outil apparaît en haut à droite et permet de terminer la sélection. L'ensemble des fiches stations de la sélection précédemment réalisée dans l'analyse peut aussi être téléchargé en cliquant sur le bouton Sélection. Il est aussi possible de télécharger l'entièreté des fiches stations en cliquant sur le bouton Toutes. Enfin, il est à noter que la génération des fiches stations est antérieure à l'analyse réalisée par MAKAHO. Les résultats présents dans ces fiches sont donc certainement différents des résultats obtenus dans votre analyse interactive mais se veulent le plus fiable possible scientifiquement.

## Page 15
DONNÉES Il est aussi possible de télécharger les données de votre analyse en cliquant sur cet autre bouton en haut à droite. L'ensemble des données est contenu dans un dossier zippé. Vous trouverez un fichier README qui explique le contenu de ce dossier et qui détail les paramètres de l'analyse réalisée. Un jeu de données d'analyse de tendance pour des variables de références est aussi disponible ici

## Page 16
INFORMATION Le logo INRAE en bas à droite de l'interface est un bouton cliquable qui permet d'afficher des informations. Il est mentionné les noms du développeur et du référent INRAE sous forme de liens vers leurs adresses emails. Ensuite, le lien vers la page GitHub hébergeant le code source est donné. La ligne suivante renseigne sur l'hébergeur SK8 et la dernière ligne donne un lien vers le site qui a donné l'inspiration de l'interface.
