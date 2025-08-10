
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats_monthly`
      
    
    

    
    OPTIONS()
    as (
      WITH travaux_details AS (
    SELECT
        -- Clés et dimensions
        id,
        type as type_travaux,
        DATE_TRUNC(startat, MONTH) as mois,  -- Date mensuelle
        startat as date_debut,

        -- Métriques temporelles
        DATE_DIFF(endat, startat, DAY) as duree_jours,
        CASE
            WHEN CURRENT_TIMESTAMP() BETWEEN startat AND endat THEN 1
            ELSE 0
        END as est_en_cours,

        -- Géolocalisation
        ST_X(location) as longitude,  -- Extraction de la longitude depuis location
        ST_Y(location) as latitude,   -- Extraction de la latitude depuis location

        -- Autres informations
        title as titre,
        description,
        address as adresse
    FROM `my-project-travaux-angers`.`travaux_angers`.`travaux_angers`
),

statistiques_mensuelles AS (
    SELECT
        mois,
        type_travaux,
        -- Métriques d'agrégation
        COUNT(DISTINCT id) as nombre_travaux,
        SUM(est_en_cours) as travaux_en_cours,
        AVG(duree_jours) as duree_moyenne_jours,
        MIN(duree_jours) as duree_min_jours,
        MAX(duree_jours) as duree_max_jours,
        -- Statistiques additionnelles mensuelles
        COUNT(DISTINCT DATE(date_debut)) as nombre_jours_avec_nouveaux_travaux,
        -- Coordonnées moyennes
        AVG(longitude) as longitude_moyenne,
        AVG(latitude) as latitude_moyenne,
        -- Liste des IDs pour jointure
        STRING_AGG(CAST(id as STRING), ',') as ids_travaux
    FROM travaux_details
    GROUP BY
        mois,
        type_travaux
)

SELECT
    -- Dimensions temporelles et type
    mois,
    type_travaux,
    ids_travaux,

    -- Métriques calculées
    nombre_travaux,
    travaux_en_cours,
    ROUND(duree_moyenne_jours, 1) as duree_moyenne_jours,
    duree_min_jours,
    duree_max_jours,
    nombre_jours_avec_nouveaux_travaux,

    -- Ratios et pourcentages
    SAFE_DIVIDE(travaux_en_cours, nombre_travaux) as ratio_actif,

    -- Position moyenne du groupe
    ST_GEOGPOINT(longitude_moyenne, latitude_moyenne) as position_representative,

    -- Horodatage
    CURRENT_TIMESTAMP() as _updated_at
FROM statistiques_mensuelles
ORDER BY
    mois DESC,
    nombre_travaux DESC
    );
  