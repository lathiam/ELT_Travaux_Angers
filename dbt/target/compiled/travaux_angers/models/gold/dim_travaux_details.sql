WITH enriched_travaux AS (
  SELECT
    id,
    title AS titre,
    type  AS type_travaux,
    start_at AS date_debut,
    end_at   AS date_fin,
    DATE_DIFF(end_at, start_at, DAY) AS duree_prevue,
    CASE
      WHEN CURRENT_DATE() BETWEEN DATE(start_at) AND DATE(end_at) THEN 'En cours'
      WHEN CURRENT_DATE() > DATE(end_at) THEN 'Terminé'
      WHEN CURRENT_DATE() < DATE(start_at) THEN 'Planifié'
    END AS statut,
    address AS adresse,
    position,                -- GEOGRAPHY
    description,
    CASE
      WHEN LOWER(description) LIKE '%fort%' OR LOWER(description) LIKE '%important%' THEN 'FORT'
      WHEN LOWER(description) LIKE '%moyen%' OR LOWER(description) LIKE '%modéré%'   THEN 'MOYEN'
      ELSE 'FAIBLE'
    END AS impact_circulation
  FROM `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
)

SELECT
  *,
  CASE
    WHEN CURRENT_DATE() > DATE(date_fin) AND statut = 'En cours' THEN 'Oui'
    ELSE 'Non'
  END AS en_retard,
  CASE
    WHEN CURRENT_DATE() > DATE(date_fin) AND statut = 'En cours'
    THEN DATE_DIFF(CURRENT_DATE(), DATE(date_fin), DAY)
    ELSE 0
  END AS retard_jours
FROM enriched_travaux