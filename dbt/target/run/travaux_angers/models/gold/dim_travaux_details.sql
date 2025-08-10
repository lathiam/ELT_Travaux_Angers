
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
      
    
    

    
    OPTIONS()
    as (
      

WITH enriched_travaux AS (
  SELECT
    id,
    title  AS titre,
    type   AS type_travaux,
    address AS adresse,
    description,

    start_at AS date_debut,
    end_at   AS date_fin,
    DATE_DIFF(end_at, start_at, DAY) AS duree_prevue,

    CASE
      WHEN CURRENT_DATE() BETWEEN DATE(start_at) AND DATE(end_at) THEN 'En cours'
      WHEN CURRENT_DATE() > DATE(end_at) THEN 'Terminé'
      WHEN CURRENT_DATE() < DATE(start_at) THEN 'Planifié'
    END AS statut,

    CASE
      WHEN LOWER(COALESCE(description, '')) LIKE '%fort%'
        OR LOWER(COALESCE(description, '')) LIKE '%important%' THEN 'FORT'
      WHEN LOWER(COALESCE(description, '')) LIKE '%moyen%'
        OR LOWER(COALESCE(description, '')) LIKE '%modéré%'   THEN 'MOYEN'
      ELSE 'FAIBLE'
    END AS impact_circulation,

    position,
    DATETIME_TRUNC(start_at, MONTH) AS mois_debut,
    DATETIME_TRUNC(start_at, YEAR)  AS annee_debut
  FROM `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
  WHERE start_at IS NOT NULL
)

SELECT
  id,
  titre,
  type_travaux,
  adresse,
  description,
  date_debut,
  date_fin,
  duree_prevue,
  statut,
  impact_circulation,
  position,
  CASE
    WHEN CURRENT_DATE() > DATE(date_fin)
     AND DATE(date_debut) <= CURRENT_DATE() THEN 'Oui'
    ELSE 'Non'
  END AS en_retard,
  CASE
    WHEN CURRENT_DATE() > DATE(date_fin)
     AND DATE(date_debut) <= CURRENT_DATE()
    THEN DATE_DIFF(CURRENT_DATE(), DATE(date_fin), DAY)
    ELSE 0
  END AS retard_jours,
  mois_debut,
  annee_debut,
  CURRENT_TIMESTAMP() AS _updated_at
FROM enriched_travaux
    );
  