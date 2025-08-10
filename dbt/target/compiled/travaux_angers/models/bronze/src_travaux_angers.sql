

-- 1) Source brute (sélection explicite + horodatage de chargement)
WITH src AS (
  SELECT
    CAST(id         AS STRING)  AS id_raw,
    CAST(type       AS STRING)  AS type_raw,
    CAST(title      AS STRING)  AS title_raw,
    CAST(description AS STRING) AS description_raw,
    CAST(address    AS STRING)  AS address_raw,
    -- startat / endat peuvent être TIMESTAMP/DATETIME/STRING côté source
    -- SAFE_CAST évite de planter si le format varie.
    SAFE_CAST(startat AS DATETIME)  AS startat_raw,
    SAFE_CAST(endat   AS DATETIME)  AS endat_raw,
    CAST(location   AS STRING)      AS location_raw,
    CURRENT_TIMESTAMP()             AS _loaded_at
  FROM `my-project-travaux-angers`.`travaux_angers`.`travaux_angers`
),

-- 2) Nettoyage texte minimal (trim, normalisation basique)
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

-- 3) Typage fort + dérivées date
typed AS (
  SELECT
    id_clean                                   AS id,
    type_clean                                 AS type,
    UPPER(type_clean)                          AS type_norm,             -- normalisation simple
    title_clean                                AS title,
    description_clean                          AS description,
    address_clean                              AS address,

    -- DATETIME -> DATE
    startat_raw                                AS start_at,
    endat_raw                                  AS end_at,
    CAST(startat_raw AS DATE)                  AS start_date,
    CAST(endat_raw   AS DATE)                  AS end_date,

    location_clean                             AS location_str,
    _loaded_at
  FROM txt
),

-- 4) Normalisation géo robuste (GeoJSON Feature/FeatureCollection/Geometry, WKT, "lon,lat")
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

-- 5) Dédoublonnage (pas de DISTINCT sur GEOGRAPHY) :
-- on considère un doublon si tous ces champs matchent, géométrie incluse via WKT
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

-- 6) Sortie finale silver (Lisible + stable + prête pour gold)
SELECT
  id,
  type,
  type_norm,
  title,
  description,
  address,

  -- Dates typées
  start_at,
  end_at,
  start_date,
  end_date,

  -- GEO
  position,                          -- GEOGRAPHY (pour downstream)
  ST_ASTEXT(position) AS position_wkt,
  CASE WHEN position IS NOT NULL THEN 'Oui' ELSE 'Non' END AS a_geometrie,

  -- Qualité / Meta
  location_str,
  _loaded_at,
  CURRENT_TIMESTAMP() AS _staged_at
FROM dedup
WHERE _rn = 1