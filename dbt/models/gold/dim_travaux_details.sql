-- Modèle pour la visualisation des travaux actifs et leurs caractéristiques
pte WITH enriched_travaux AS (
    SELECT
        id,
        title as titre,
        type as type_travaux,
        startat as date_debut,
        endat as date_fin,
        DATE_DIFF(endat, startat, DAY) as duree_prevue,
        CASE
            WHEN CURRENT_DATE() BETWEEN DATE(startat) AND DATE(endat) THEN 'En cours'
            WHEN CURRENT_DATE() > DATE(endat) THEN 'Terminé'
            WHEN CURRENT_DATE() < DATE(startat) THEN 'Planifié'
        END as statut,
        address as adresse,
        location as position,
        description,
        CASE
            WHEN LOWER(description) LIKE '%fort%' OR LOWER(description) LIKE '%important%' THEN 'FORT'
            WHEN LOWER(description) LIKE '%moyen%' OR LOWER(description) LIKE '%modéré%' THEN 'MOYEN'
            ELSE 'FAIBLE'
        END as impact_circulation,
        DATETIME_TRUNC(startat, MONTH) as mois_debut,
        DATETIME_TRUNC(startat, YEAR) as annee_debut
    FROM {{ ref('stg_travaux_angers') }}
)

SELECT
    *,
    CASE
        WHEN CURRENT_DATE() > DATE(date_fin) AND statut = 'En cours' THEN TRUE
        ELSE FALSE
    END as is_delayed,
    CASE
        WHEN CURRENT_DATE() > DATE(date_fin) AND statut = 'En cours'
        THEN DATE_DIFF(CURRENT_DATE(), DATE(date_fin), DAY)
        ELSE 0
    END as retard_jours
FROM enriched_travaux
