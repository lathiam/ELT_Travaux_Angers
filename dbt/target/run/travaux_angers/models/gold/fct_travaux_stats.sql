
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
      
    
    

    
    OPTIONS()
    as (
      WITH travaux_quotidiens AS (
  SELECT
    id,
    type  AS type_travaux,
    start_at AS date_debut,
    end_at   AS date_fin,
    position,
    description,
    title   AS titre,
    address AS adresse,

    CASE
      WHEN LOWER(description) LIKE '%fort%' OR LOWER(description) LIKE '%important%' THEN 'FORT'
      WHEN LOWER(description) LIKE '%moyen%' OR LOWER(description) LIKE '%modéré%'   THEN 'MOYEN'
      ELSE 'FAIBLE'
    END AS impact_circulation,

    DATE_DIFF(end_at, start_at, DAY) AS duree_prevue,

    CASE WHEN CURRENT_DATE() > DATE(end_at) AND DATE(start_at) <= CURRENT_DATE() THEN 'Oui' ELSE 'Non' END AS en_retard,
    CASE WHEN CURRENT_DATE() > DATE(end_at) AND DATE(start_at) <= CURRENT_DATE()
         THEN DATE_DIFF(CURRENT_DATE(), DATE(end_at), DAY)
         ELSE 0 END AS retard_jours,

    date_jour,
    EXTRACT(MONTH FROM date_jour)     AS mois_num,
    EXTRACT(DAYOFWEEK FROM date_jour) AS jour_semaine_num,

    CASE EXTRACT(MONTH FROM date_jour)
      WHEN 1 THEN 'Janvier' WHEN 2 THEN 'Février' WHEN 3 THEN 'Mars' WHEN 4 THEN 'Avril'
      WHEN 5 THEN 'Mai' WHEN 6 THEN 'Juin' WHEN 7 THEN 'Juillet' WHEN 8 THEN 'Août'
      WHEN 9 THEN 'Septembre' WHEN 10 THEN 'Octobre' WHEN 11 THEN 'Novembre' WHEN 12 THEN 'Décembre'
    END AS mois,

    CASE EXTRACT(DAYOFWEEK FROM date_jour)  -- 1=Dimanche ... 7=Samedi
      WHEN 1 THEN 'Dimanche' WHEN 2 THEN 'Lundi' WHEN 3 THEN 'Mardi' WHEN 4 THEN 'Mercredi'
      WHEN 5 THEN 'Jeudi' WHEN 6 THEN 'Vendredi' WHEN 7 THEN 'Samedi'
    END AS jour_semaine,

    CASE WHEN position IS NOT NULL THEN 'Oui' ELSE 'Non' END AS a_geometrie,

    CASE
      WHEN DATE(date_jour) BETWEEN DATE(start_at) AND DATE(end_at) THEN 'Actif ce jour'
      ELSE 'Non actif ce jour'
    END AS est_actif_libelle,

    CASE
      WHEN DATE_DIFF(end_at, start_at, DAY) IS NULL THEN 'Inconnu'
      WHEN DATE_DIFF(end_at, start_at, DAY) = 0 THEN '0 jour'
      WHEN DATE_DIFF(end_at, start_at, DAY) = 1 THEN '1 jour'
      ELSE CONCAT(CAST(DATE_DIFF(end_at, start_at, DAY) AS STRING), ' jours')
    END AS duree_prevue_libelle,

    CASE
      WHEN (CURRENT_DATE() > DATE(end_at) AND DATE(start_at) <= CURRENT_DATE()) = FALSE THEN 'Aucun retard'
      WHEN DATE_DIFF(CURRENT_DATE(), DATE(end_at), DAY) = 1 THEN '1 jour de retard'
      ELSE CONCAT(CAST(DATE_DIFF(CURRENT_DATE(), DATE(end_at), DAY) AS STRING), ' jours de retard')
    END AS retard_jours_libelle

  FROM `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers` s
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(s.start_date, s.end_date)) AS date_jour
  QUALIFY ROW_NUMBER() OVER (PARTITION BY id, date_jour ORDER BY date_jour) = 1
),

stats_agregees AS (
  SELECT
    date_jour,
    type_travaux,
    COUNT(DISTINCT id) AS total_travaux_type,
    COUNTIF(DATE(date_jour) BETWEEN DATE(date_debut) AND DATE(date_fin)) AS travaux_actifs_type,
    COUNTIF(en_retard = 'Oui') AS travaux_retard_type,
    AVG(duree_prevue) AS duree_moyenne_type,
    AVG(retard_jours) AS retard_moyen_type,
    COUNTIF(impact_circulation = 'FORT')  AS impact_fort_count,
    COUNTIF(impact_circulation = 'MOYEN') AS impact_moyen_count,
    COUNTIF(impact_circulation = 'FAIBLE') AS impact_faible_count,
    ST_UNION_AGG(position) AS zone_travaux,
    SAFE_DIVIDE(
      COUNTIF(position IS NOT NULL),
      NULLIF(ST_AREA(ST_CONVEXHULL(ST_UNION_AGG(position))), 0)
    ) AS densite_spatiale
  FROM travaux_quotidiens
  GROUP BY date_jour, type_travaux
)

SELECT
  t.date_jour,
  t.type_travaux,
  t.id AS travaux_id,

  t.mois_num,
  t.mois,
  t.jour_semaine_num,
  t.jour_semaine,

  t.titre,
  t.adresse,

  ST_ASTEXT(t.position) AS position_wkt,
  ST_Y(ST_CENTROID(t.position)) AS latitude,
  ST_X(ST_CENTROID(t.position)) AS longitude,
  t.a_geometrie,

  t.date_debut,
  t.date_fin,

  CASE WHEN DATE(t.date_jour) BETWEEN DATE(t.date_debut) AND DATE(t.date_fin) THEN 1 ELSE 0 END AS est_actif,
  t.est_actif_libelle,

  t.en_retard,
  t.retard_jours,
  t.retard_jours_libelle,

  t.duree_prevue,
  t.duree_prevue_libelle,

  s.total_travaux_type,
  s.travaux_actifs_type,
  s.travaux_retard_type,
  s.duree_moyenne_type,
  s.retard_moyen_type,
  t.impact_circulation AS niveau_impact,
  s.impact_fort_count,
  s.impact_moyen_count,
  s.impact_faible_count,

  SAFE_DIVIDE(s.travaux_actifs_type, s.total_travaux_type) AS taux_occupation,
  FORMAT('%.1f %%', SAFE_MULTIPLY(SAFE_DIVIDE(s.travaux_actifs_type, s.total_travaux_type), 100)) AS taux_occupation_libelle,

  SAFE_DIVIDE(s.travaux_retard_type, s.travaux_actifs_type) AS taux_retard,
  FORMAT('%.1f %%', SAFE_MULTIPLY(SAFE_DIVIDE(s.travaux_retard_type, s.travaux_actifs_type), 100)) AS taux_retard_libelle,

  s.densite_spatiale,
  ST_ASTEXT(s.zone_travaux) AS zone_travaux_wkt,

  CURRENT_TIMESTAMP() AS _updated_at
FROM travaux_quotidiens t
LEFT JOIN stats_agregees s
  ON t.date_jour = s.date_jour
 AND t.type_travaux = s.type_travaux
ORDER BY
  t.date_jour DESC,
  t.type_travaux,
  t.id
    );
  