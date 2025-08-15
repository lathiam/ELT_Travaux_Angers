
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
      
    partition by date_jour
    cluster by type_travaux, niveau_impact

    
    OPTIONS()
    as (
      

WITH stg AS (
  SELECT
    id,
    type               AS type_travaux,
    title              AS titre,
    address            AS adresse,
    description,

    -- temporel
    start_at, end_at,           -- TIMESTAMP
    start_date, end_date,       -- DATE

    -- trafic si dispo
    traffic, deviated, slow, normal,

    -- géo
    position,

    _loaded_at, _staged_at
  FROM `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
),

-- Expansion jour par jour (dates valides uniquement)
travaux_quotidiens AS (
  SELECT
    s.id,
    s.type_travaux,
    s.titre,
    s.adresse,
    s.description,
    s.position,

    s.start_at  AS date_debut,
    s.end_at    AS date_fin,
    s.start_date,
    s.end_date,

    -- impact circulation (trafic + keywords)
    CASE
      WHEN TRUE = s.deviated THEN 'FORT'
      WHEN LOWER(COALESCE(s.traffic,'')) IN ('slow','ralenti','lent') THEN 'MOYEN'
      WHEN LOWER(COALESCE(s.description,'')) LIKE '%fort%'
        OR LOWER(COALESCE(s.description,'')) LIKE '%important%' THEN 'FORT'
      WHEN LOWER(COALESCE(s.description,'')) LIKE '%moyen%'
        OR LOWER(COALESCE(s.description,'')) LIKE '%modéré%'
        OR LOWER(COALESCE(s.description,'')) LIKE '%modere%'   THEN 'MOYEN'
      ELSE 'FAIBLE'
    END AS impact_circulation,

    -- durée prévue (jours) si bornes présentes
    CASE
      WHEN s.start_at IS NOT NULL AND s.end_at IS NOT NULL
        THEN TIMESTAMP_DIFF(s.end_at, s.start_at, DAY)
      ELSE NULL
    END AS duree_prevue,

    -- retard basé sur "maintenant"
    CASE
      WHEN s.end_at IS NOT NULL AND CURRENT_TIMESTAMP() > s.end_at
           AND (s.start_at IS NULL OR CURRENT_TIMESTAMP() >= s.start_at)
      THEN 'Oui' ELSE 'Non'
    END AS en_retard,
    CASE
      WHEN s.end_at IS NOT NULL AND CURRENT_TIMESTAMP() > s.end_at
           AND (s.start_at IS NULL OR CURRENT_TIMESTAMP() >= s.start_at)
      THEN GREATEST(TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.end_at, DAY), 0)
      ELSE 0
    END AS retard_jours,

    -- calendrier déroulé
    d AS date_jour,

    EXTRACT(MONTH FROM d)     AS mois_num,
    EXTRACT(DAYOFWEEK FROM d) AS jour_semaine_num,

    CASE EXTRACT(MONTH FROM d)
      WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars' WHEN 4 THEN 'Avril'
      WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin' WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août'
      WHEN 9 THEN 'Septembre' WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
    END AS mois,
    CASE EXTRACT(DAYOFWEEK FROM d)  -- 1=Dim ... 7=Sam
      WHEN 1 THEN 'Dimanche' WHEN 2 THEN 'Lundi' WHEN 3 THEN 'Mardi' WHEN 4 THEN 'Mercredi'
      WHEN 5 THEN 'Jeudi' WHEN 6 THEN 'Vendredi' WHEN 7 THEN 'Samedi'
    END AS jour_semaine,

    CASE WHEN s.position IS NOT NULL THEN 'Oui' ELSE 'Non' END AS a_geometrie

  FROM stg s,
  UNNEST(GENERATE_DATE_ARRAY(s.start_date, s.end_date)) AS d
  WHERE s.start_date IS NOT NULL
    AND s.end_date   IS NOT NULL
    AND s.start_date <= s.end_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY s.id, d ORDER BY d) = 1
),

-- Agrégats par jour x type
stats_agregees AS (
  SELECT
    t.date_jour,
    t.type_travaux,
    COUNT(DISTINCT t.id) AS total_travaux_type,
    COUNTIF(t.date_jour BETWEEN t.start_date AND t.end_date) AS travaux_actifs_type,
    COUNTIF(t.en_retard = 'Oui') AS travaux_retard_type,
    AVG(t.duree_prevue) AS duree_moyenne_type,
    AVG(t.retard_jours) AS retard_moyen_type,

    COUNTIF(t.impact_circulation = 'FORT')   AS impact_fort_count,
    COUNTIF(t.impact_circulation = 'MOYEN')  AS impact_moyen_count,
    COUNTIF(t.impact_circulation = 'FAIBLE') AS impact_faible_count,

    ST_UNION_AGG(t.position) AS zone_travaux,

    SAFE_DIVIDE(
      COUNTIF(t.position IS NOT NULL),
      NULLIF(ST_AREA(ST_CONVEXHULL(ST_UNION_AGG(t.position))), 0)
    ) AS densite_spatiale
  FROM travaux_quotidiens t
  GROUP BY t.date_jour, t.type_travaux
)

SELECT
  t.date_jour,
  t.type_travaux,
  t.id AS travaux_id,

  -- calendrier
  t.mois_num,
  t.mois,
  t.jour_semaine_num,
  t.jour_semaine,

  -- libellés
  t.titre,
  t.adresse,

  -- géo (centroïde quand possible)
  ST_ASTEXT(t.position) AS position_wkt,
  CASE WHEN t.position IS NOT NULL THEN ST_Y(ST_CENTROID(t.position)) END AS latitude,
  CASE WHEN t.position IS NOT NULL THEN ST_X(ST_CENTROID(t.position)) END AS longitude,
  t.a_geometrie,

  -- temporel
  t.date_debut,
  t.date_fin,

  -- activité pour ce jour
  CASE WHEN t.date_jour BETWEEN t.start_date AND t.end_date THEN 1 ELSE 0 END AS est_actif,
  CASE
    WHEN t.date_jour BETWEEN t.start_date AND t.end_date THEN 'Actif ce jour'
    ELSE 'Non actif ce jour'
  END AS est_actif_libelle,

  -- retards
  t.en_retard,
  t.retard_jours,
  CASE
    WHEN (t.en_retard = 'Oui') = FALSE THEN 'Aucun retard'
    WHEN t.retard_jours = 1 THEN '1 jour de retard'
    ELSE CONCAT(CAST(t.retard_jours AS STRING), ' jours de retard')
  END AS retard_jours_libelle,

  -- durées
  t.duree_prevue,
  CASE
    WHEN t.duree_prevue IS NULL THEN 'Inconnu'
    WHEN t.duree_prevue = 0 THEN '0 jour'
    WHEN t.duree_prevue = 1 THEN '1 jour'
    ELSE CONCAT(CAST(t.duree_prevue AS STRING), ' jours')
  END AS duree_prevue_libelle,

  -- agrégats du jour / type
  s.total_travaux_type,
  s.travaux_actifs_type,
  s.travaux_retard_type,
  s.duree_moyenne_type,
  s.retard_moyen_type,

  -- niveaux d'impact
  t.impact_circulation AS niveau_impact,
  s.impact_fort_count,
  s.impact_moyen_count,
  s.impact_faible_count,

  -- taux (safe divide pour éviter /0)
  SAFE_DIVIDE(s.travaux_actifs_type, s.total_travaux_type) AS taux_occupation,
  FORMAT('%.1f %%', 100 * SAFE_DIVIDE(s.travaux_actifs_type, NULLIF(s.total_travaux_type,0))) AS taux_occupation_libelle,

  SAFE_DIVIDE(s.travaux_retard_type, s.travaux_actifs_type) AS taux_retard,
  FORMAT('%.1f %%', 100 * SAFE_DIVIDE(s.travaux_retard_type, NULLIF(s.travaux_actifs_type,0))) AS taux_retard_libelle,

  -- géo agrégée
  ST_ASTEXT(s.zone_travaux) AS zone_travaux_wkt,
  s.densite_spatiale,

  CURRENT_TIMESTAMP() AS _updated_at
FROM travaux_quotidiens t
LEFT JOIN stats_agregees s
  ON t.date_jour = s.date_jour
 AND t.type_travaux = s.type_travaux
    );
  