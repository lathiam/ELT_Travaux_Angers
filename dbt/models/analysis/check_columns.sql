{{ config(materialized='view') }}

SELECT *
FROM {{ source('travaux_angers', 'travaux_angers') }}
LIMIT 1
