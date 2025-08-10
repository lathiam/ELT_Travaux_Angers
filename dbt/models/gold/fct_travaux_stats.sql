WITH travaux_quotidiens AS (
    SELECT
        t.id,
        t.type AS type_travaux,
        t.startat AS date_debut,
        t.endat AS date_fin,
        t.location AS position,
        CASE
            WHEN LOWER(t.description) LIKE '%fort%' OR LOWER(t.description) LIKE '%important%' THEN 'FORT'
            WHEN LOWER(t.description) LIKE '%moyen%' OR LOWER(t.description) LIKE '%modéré%' THEN 'MOYEN'
            ELSE 'FAIBLE'
        END AS impact_circulation,
        DATE_DIFF(t.endat, t.startat, DAY) AS duree_prevue,
        CASE
            WHEN CURRENT_DATE() > DATE(t.endat) AND DATE(t.startat) <= CURRENT_DATE() THEN TRUE
            ELSE FALSE
        END AS is_delayed,
        CASE
            WHEN CURRENT_DATE() > DATE(t.endat) AND DATE(t.startat) <= CURRENT_DATE()
            THEN DATE_DIFF(CURRENT_DATE(), DATE(t.endat), DAY)
            ELSE 0
        END AS retard_jours,
        date_jour
    FROM {{ ref('stg_travaux_angers') }} t
    CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(DATE(t.startat), DATE(t.endat))) AS date_jour
)

SELECT
    date_jour,
    type_travaux,
    id AS travaux_id,
    CASE
        WHEN DATE(date_jour) BETWEEN DATE(date_debut) AND DATE(date_fin) THEN 1
        ELSE 0
    END AS est_actif,
    is_delayed AS est_en_retard,
    duree_prevue,
    retard_jours,
    impact_circulation,
    position,
    CURRENT_TIMESTAMP() AS _updated_at
FROM travaux_quotidiens
ORDER BY
    date_jour DESC,
    travaux_id;
