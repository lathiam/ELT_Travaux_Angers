-- silver/stg_travaux_angers.sql
-- Données nettoyées et standardisées
WITH source AS (
    SELECT * FROM `my-project-travaux-angers`.`travaux_angers_bronze`.`src_travaux_angers`
)

SELECT
    -- Informations de base
    id,
    title as titre,
    description,
    address as adresse,

    -- Dates et durée
    TIMESTAMP(startat) as date_debut,
    TIMESTAMP(endat) as date_fin,

    -- Informations sur le trafic et le type
    traffic as impact_trafic,
    type,

    -- Coordonnées géographiques (extraites du geo_point_2d)
    CAST(JSON_EXTRACT(geo_point_2d, '$.lon') as FLOAT64) as longitude,
    CAST(JSON_EXTRACT(geo_point_2d, '$.lat') as FLOAT64) as latitude,

    -- Informations de contact
    contact,
    email,

    -- Métadonnées
    istramway as est_tramway,
    idparking as id_parking,

    -- Horodatage de mise à jour
    CURRENT_TIMESTAMP() as _updated_at
FROM source