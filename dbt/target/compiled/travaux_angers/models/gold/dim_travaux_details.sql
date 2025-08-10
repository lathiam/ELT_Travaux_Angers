-- Modèle pour la visualisation des travaux actifs et leurs caractéristiques
WITH travaux_enrichis AS (
    SELECT
        *,
        TIMESTAMP_DIFF(date_fin, date_debut, DAY) as duree_jours,
        CASE
            WHEN CURRENT_TIMESTAMP() BETWEEN date_debut AND date_fin THEN 'En cours'
            WHEN CURRENT_TIMESTAMP() < date_debut THEN 'À venir'
            ELSE 'Terminé'
        END as statut
    FROM `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
)

SELECT
    id,
    titre,
    date_debut,
    date_fin,
    duree_jours,
    longitude,
    latitude,
    type as type_travaux,
    description,
    adresse,
    statut,
    est_tramway,
    id_parking,
    contact,
    email,
    _updated_at,
    -- Création d'une géométrie pour la visualisation cartographique
    ST_GEOGPOINT(longitude, latitude) as position
FROM travaux_enrichis