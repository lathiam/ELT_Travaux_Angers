{{ config(
  materialized='table',
  partition_by = {"field": "start_date", "data_type": "date"},
  cluster_by   = ["type_norm", "start_date"],
  on_schema_change = "sync_all_columns"
) }}

-- STAGING 1:1 (pas de dédup)

WITH src AS (
  SELECT
    CAST(id           AS STRING)  AS id_raw,
    CAST(type         AS STRING)  AS type_raw,
    CAST(title        AS STRING)  AS title_raw,
    CAST(description  AS STRING)  AS description_raw,
    CAST(address      AS STRING)  AS address_raw,

    startat                          AS start_raw_any,
    endat                            AS end_raw_any,

    CAST(location     AS STRING)  AS location_raw,

    -- Colonnes optionnelles absentes → NULL
    CAST(NULL AS STRING) AS traffic_raw,
    CAST(NULL AS BOOL)   AS deviated_raw,
    CAST(NULL AS INT64)  AS slow_raw,
    CAST(NULL AS INT64)  AS normal_raw,

    CURRENT_TIMESTAMP()             AS _loaded_at
  FROM {{ source('travaux_angers', 'travaux_angers') }}
),

typed AS (
  SELECT
    TRIM(id_raw)           AS id,
    TRIM(type_raw)         AS type,
    UPPER(TRIM(type_raw))  AS type_norm,
    TRIM(title_raw)        AS title,
    TRIM(description_raw)  AS description,
    TRIM(address_raw)      AS address,

    COALESCE(
      SAFE_CAST(start_raw_any AS TIMESTAMP),
      (CASE WHEN SAFE_CAST(start_raw_any AS DATETIME) IS NOT NULL
            THEN TIMESTAMP(SAFE_CAST(start_raw_any AS DATETIME), 'Europe/Paris') END),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(start_raw_any AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(start_raw_any AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(start_raw_any AS STRING))
    ) AS start_at,

    COALESCE(
      SAFE_CAST(end_raw_any AS TIMESTAMP),
      (CASE WHEN SAFE_CAST(end_raw_any AS DATETIME) IS NOT NULL
            THEN TIMESTAMP(SAFE_CAST(end_raw_any AS DATETIME), 'Europe/Paris') END),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(end_raw_any AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(end_raw_any AS STRING)),
      PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(end_raw_any AS STRING))
    ) AS end_at,

    DATE(
      COALESCE(
        SAFE_CAST(start_raw_any AS TIMESTAMP),
        (CASE WHEN SAFE_CAST(start_raw_any AS DATETIME) IS NOT NULL
              THEN TIMESTAMP(SAFE_CAST(start_raw_any AS DATETIME), 'Europe/Paris') END),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(start_raw_any AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(start_raw_any AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(start_raw_any AS STRING))
      )
    ) AS start_date,

    DATE(
      COALESCE(
        SAFE_CAST(end_raw_any AS TIMESTAMP),
        (CASE WHEN SAFE_CAST(end_raw_any AS DATETIME) IS NOT NULL
              THEN TIMESTAMP(SAFE_CAST(end_raw_any AS DATETIME), 'Europe/Paris') END),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*SZ', CAST(end_raw_any AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%E*S',  CAST(end_raw_any AS STRING)),
        PARSE_TIMESTAMP('%Y-%m-%dT%H:%M:%E*S',  CAST(end_raw_any AS STRING))
      )
    ) AS end_date,

    TRIM(location_raw)  AS location_str,
    traffic_raw         AS traffic,
    deviated_raw        AS deviated,
    slow_raw            AS slow,
    normal_raw          AS normal,

    _loaded_at
  FROM src
),

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
)

-- Sortie finale (aucun filtre/dédoublonnage)
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

  traffic,
  deviated,
  slow,
  normal,

  position,
  ST_ASTEXT(position) AS position_wkt,
  CASE WHEN position IS NOT NULL THEN 'Oui' ELSE 'Non' END AS a_geometrie,

  location_str,
  _loaded_at,
  CURRENT_TIMESTAMP() AS _staged_at
FROM geo
