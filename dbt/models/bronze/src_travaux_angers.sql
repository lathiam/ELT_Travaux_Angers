{{ config(
    materialized='table',
    partition_by = {"field": "start_date", "data_type": "date"},
    cluster_by   = ["type_norm", "start_date"],
    on_schema_change = "sync_all_columns"
) }}

-- 1) Source brute
WITH src AS (
  SELECT
    CAST(id           AS STRING)  AS id_raw,
    CAST(type         AS STRING)  AS type_raw,
    CAST(title        AS STRING)  AS title_raw,
    CAST(description  AS STRING)  AS description_raw,
    CAST(address      AS STRING)  AS address_raw,

    startat                          AS startat_raw,
    endat                            AS endat_raw,

    CAST(location     AS STRING)  AS location_raw,

    -- Colonnes optionnelles absentes → NULL (pour compat. aval)
    CAST(NULL AS STRING) AS traffic_raw,
    CAST(NULL AS BOOL)   AS deviated_raw,
    CAST(NULL AS INT64)  AS slow_raw,
    CAST(NULL AS INT64)  AS normal_raw,

    CURRENT_TIMESTAMP()             AS _loaded_at
  FROM {{ source('travaux_angers', 'travaux_angers') }}
),

-- 2) Nettoyage texte
txt AS (
  SELECT
    TRIM(id_raw)          AS id_clean,
    TRIM(type_raw)        AS type_clean,
    TRIM(title_raw)       AS title_clean,
    TRIM(description_raw) AS description_clean,
    TRIM(address_raw)     AS address_clean,
    startat_raw,
    endat_raw,
    TRIM(location_raw)    AS location_clean,
    _loaded_at
  FROM src
),

-- 3) Typage fort (dates) – sans JSON_TYPE, TZ figée
typed AS (
  SELECT
    id_clean                                   AS id,
    type_clean                                 AS type,
    UPPER(type_clean)                          AS type_norm,
    title_clean                                AS title,
    description_clean                          AS description,
    address_clean                              AS address,

    COALESCE(
      SAFE_CAST(startat_raw AS TIMESTAMP),
      (CASE WHEN SAFE_CAST(startat_raw AS DATETIME) IS NOT NULL
            THEN TIMESTAMP(SAFE_CAST(startat_raw AS DATETIME), 'Europe/Paris') END),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(startat_raw AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(startat_raw AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(startat_raw AS STRING))
    ) AS start_at,

    COALESCE(
      SAFE_CAST(endat_raw AS TIMESTAMP),
      (CASE WHEN SAFE_CAST(endat_raw AS DATETIME) IS NOT NULL
            THEN TIMESTAMP(SAFE_CAST(endat_raw AS DATETIME), 'Europe/Paris') END),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(endat_raw AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(endat_raw AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(endat_raw AS STRING))
    ) AS end_at,

    DATE(
      COALESCE(
        SAFE_CAST(startat_raw AS TIMESTAMP),
        (CASE WHEN SAFE_CAST(startat_raw AS DATETIME) IS NOT NULL
              THEN TIMESTAMP(SAFE_CAST(startat_raw AS DATETIME), 'Europe/Paris') END),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(startat_raw AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(startat_raw AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(startat_raw AS STRING))
      )
    ) AS start_date,

    DATE(
      COALESCE(
        SAFE_CAST(endat_raw AS TIMESTAMP),
        (CASE WHEN SAFE_CAST(endat_raw AS DATETIME) IS NOT NULL
              THEN TIMESTAMP(SAFE_CAST(endat_raw AS DATETIME), 'Europe/Paris') END),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(endat_raw AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(endat_raw AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(endat_raw AS STRING))
      )
    ) AS end_date,

    location_clean                             AS location_str,
    _loaded_at
  FROM txt
),

-- 4) Géométrie
geo AS (
  SELECT
    t.*,
    CASE
      WHEN REGEXP_CONTAINS(location_str, r'"type"\s*:\s*"FeatureCollection"') THEN
        ST_GEOGFROMGEOJSON(JSON_EXTRACT(location_str, '$.features[0].geometry'))
      WHEN REGEXP_CONTAINS(location_str, r'"type"\s*:\s*"Feature"') THEN
        ST_GEOGFROMGEOJSON(JSON_EXTRACT(location_str, '$.geometry'))
      WHEN REGEXP_CONTAINS(location_str,
           r'"type"\s*:\s*"(Point|LineString|Polygon|MultiPoint|MultiLineString|MultiPolygon|GeometryCollection)"') THEN
        ST_GEOGFROMGEOJSON(location_str)
      WHEN REGEXP_CONTAINS(location_str, r'^\s*(POINT|LINESTRING|POLYGON|MULTI|GEOMETRYCOLLECTION)\b') THEN
        ST_GEOGFROMTEXT(location_str)
      WHEN REGEXP_CONTAINS(location_str, r'^\s*-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?\s*$') THEN
        ST_GEOGPOINT(
          CAST(SPLIT(location_str, ',')[OFFSET(0)] AS FLOAT64), -- lon
          CAST(SPLIT(location_str, ',')[OFFSET(1)] AS FLOAT64)  -- lat
        )
      ELSE NULL
    END AS position
  FROM typed t
),

-- 5) Dédoublonnage
dedup AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY
        id, type, title, description, address,
        start_at, end_at,
        COALESCE(ST_ASTEXT(position), 'NULL_GEOM')
      ORDER BY id
    ) AS _rn
  FROM geo
)

-- 6) Sortie finale
SELECT
  id,
  type,
  type_norm,
  title,
  description,
  address,

  start_at,
  end_at,
  start_date,
  end_date,

  position,
  ST_ASTEXT(position) AS position_wkt,
  CASE WHEN position IS NOT NULL THEN 'Oui' ELSE 'Non' END AS a_geometrie,

  location_str,
  _loaded_at,
  CURRENT_TIMESTAMP() AS _staged_at
FROM dedup
WHERE _rn = 1
