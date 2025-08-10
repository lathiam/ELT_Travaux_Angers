{{ config(materialized='view') }}

SELECT
    type as type_travaux,
    COUNT(*) as nombre_total,
    COUNT(DISTINCT DATE_TRUNC(startat, MONTH)) as nombre_mois_distincts
FROM {{ source('travaux_angers', 'travaux_angers') }}
GROUP BY type
ORDER BY nombre_total DESC
