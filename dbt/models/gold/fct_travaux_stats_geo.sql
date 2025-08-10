SELECT
  *
FROM {{ ref('fct_travaux_stats') }}
WHERE a_geometrie = 'Oui'
