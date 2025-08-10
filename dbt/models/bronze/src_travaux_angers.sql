-- bronze/src_travaux_angers.sql
-- Source brute des données de travaux
SELECT
    *,
    CURRENT_TIMESTAMP() as _loaded_at
FROM {{ source('travaux_angers', 'travaux_angers') }}

