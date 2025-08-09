# ELT Travaux Angers

## Description du Projet
Ce projet met en place un système ELT (Extract, Load, Transform) pour suivre en temps réel les travaux dans la ville d'Angers. Il permet de collecter, stocker et visualiser les informations concernant les travaux en cours et passés dans la ville.

## Objectifs
- Suivre en temps réel les travaux dans la ville d'Angers
- Visualiser les travaux sur une carte interactive
- Analyser la durée et l'impact des travaux
- Informer sur les déviations et l'état du trafic

## Structure du Projet
```
├── extract.py           # Script d'extraction des données
├── load.py             # Script de chargement des données
├── requirements.txt     # Dépendances du projet
├── credentials/        
│   └── mon_compte_de_service_travaux_angers.json  # Identifiants de service
├── data/
│   └── data.csv        # Données extraites
└── logs/
    ├── log_extract.txt # Logs d'extraction
    ├── log_load.txt    # Logs de chargement
```

## Fonctionnalités Principales
- **Extraction des données** : Récupération automatique des informations sur les travaux
- **Stockage** : Sauvegarde des données dans un format structuré
- **Visualisation** : Tableau de bord interactif présentant :
  - Localisation des travaux sur une carte
  - Dates de début et de fin des travaux
  - Durée estimée des travaux
  - Information sur les déviations
  - État du trafic
  - Historique des travaux passés

## Données Collectées
- Emplacement des travaux
- Dates (début et fin)
- Durée prévue
- Présence de déviations
- Impact sur le trafic
- État d'avancement
- Rue(s) concernée(s)

## Configuration
Le projet nécessite des identifiants de service stockés dans le dossier `credentials/` pour accéder aux données de la ville d'Angers.

## Utilisation
1. Configurer les identifiants dans le dossier `credentials/`
2. Installer les dépendances : `pip install -r requirements.txt`
3. Lancer l'extraction : `python extract.py`
4. Lancer le chargement : `python load.py`

## Tableau de Bord
Le tableau de bord permet de visualiser en temps réel :
- La carte interactive des travaux
- Les statistiques sur les travaux en cours
- Les prévisions de durée
- Les zones impactées
- Les itinéraires alternatifs

## Logs
Les logs sont stockés dans le dossier `logs/` et permettent de suivre :
- Les extractions de données
- Les chargements
- Les erreurs éventuelles
