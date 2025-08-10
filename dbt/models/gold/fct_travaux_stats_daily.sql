WITH travaux_details AS (
    SELECT
        -- Clés et dimensions
        id,
        type as type_travaux,
        DATE(date_debut) as jour,  -- Date journalière

        -- Métriques temporelles
        DATE_DIFF(date_fin, date_debut, DAY) as duree_jours,
        CASE
            WHEN CURRENT_TIMESTAMP() BETWEEN date_debut AND date_fin THEN 1
            ELSE 0
        END as est_en_cours,

        -- Géolocalisation
        longitude,
        latitude,

        -- Autres informations
        titre,
        description,
        adresse
    FROM {{ ref('stg_travaux_angers') }}
),

statistiques_journalieres AS (
    SELECT
        jour,
        type_travaux,
        -- Métriques d'agrégation
        COUNT(DISTINCT id) as nombre_travaux,
        SUM(est_en_cours) as travaux_en_cours,
        AVG(duree_jours) as duree_moyenne_jours,
        MIN(duree_jours) as duree_min_jours,
        MAX(duree_jours) as duree_max_jours,
        -- Coordonnées moyennes
        AVG(longitude) as longitude_moyenne,
        AVG(latitude) as latitude_moyenne,
        -- Liste des IDs pour jointure
        STRING_AGG(CAST(id as STRING), ',') as ids_travaux
    FROM travaux_details
    GROUP BY
        jour,
        type_travaux
)

SELECT
    -- Dimensions temporelles et type
    jour,
    type_travaux,
    ids_travaux,

    -- Métriques calculées
    nombre_travaux,
    travaux_en_cours,
    ROUND(duree_moyenne_jours, 1) as duree_moyenne_jours,
    duree_min_jours,
    duree_max_jours,

    -- Ratios et pourcentages
    SAFE_DIVIDE(travaux_en_cours, nombre_travaux) as ratio_actif,

    -- Position moyenne du groupe
    ST_GEOGPOINT(longitude_moyenne, latitude_moyenne) as position_representative,

    -- Horodatage
    CURRENT_TIMESTAMP() as _updated_at
FROM statistiques_journalieres
ORDER BY
    jour DESC,
    nombre_travaux DESC
