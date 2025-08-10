-- Vérifie les colonnes disponibles dans la source
SELECT *
FROM {{ source('travaux_angers', 'travaux_angers') }}
LIMIT 1;

