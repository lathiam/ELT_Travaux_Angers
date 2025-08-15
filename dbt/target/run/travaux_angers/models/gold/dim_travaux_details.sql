
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
      
    partition by mois_debut
    cluster by statut, type_travaux, annee_debut

    
    OPTIONS()
    as (
      



with stg as (
  select
    id,
    -- champs texte
    title            as titre,
    type             as type_travaux,
    address          as adresse,
    description,

    -- temporel (du staging, déjà TIMESTAMP / DATE robustes)
    start_at,
    end_at,
    start_date,
    end_date,

    -- trafic éventuel
    traffic,
    deviated,
    slow,
    normal,

    -- géo
    position,
    position_wkt,

    _loaded_at,
    _staged_at
  from `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
),

-- Dérivés temporels + statut
enriched as (
  select
    id,
    titre,
    type_travaux,
    adresse,
    description,

    -- TIMESTAMP (source de vérité)
    start_at as date_debut,
    end_at   as date_fin,

    -- Durée prévue (si un des deux null => null)
    case
      when start_at is not null and end_at is not null
        then timestamp_diff(end_at, start_at, day)
      else null
    end as duree_prevue,

    -- Statut actuel basé sur les TIMESTAMP
    case
      when start_at is not null and end_at is not null
           and current_timestamp() between start_at and end_at
        then 'En cours'
      when end_at is not null and current_timestamp() > end_at
        then 'Terminé'
      when start_at is not null and current_timestamp() < start_at
        then 'Planifié'
      else 'Inconnu'
    end as statut,

    -- Impact circulation : combinaison mots-clés + colonnes trafic
    case
      when true = deviated then 'FORT'
      when lower(coalesce(traffic,'')) in ('slow','ralenti','lent') then 'MOYEN'
      when lower(coalesce(description,'')) like '%fort%'
        or lower(coalesce(description,'')) like '%important%' then 'FORT'
      when lower(coalesce(description,'')) like '%moyen%'
        or lower(coalesce(description,'')) like '%modéré%'
        or lower(coalesce(description,'')) like '%modere%'   then 'MOYEN'
      else 'FAIBLE'
    end as impact_circulation,

    -- Indicateurs de suivi
    case
      when end_at is not null
       and current_timestamp() > end_at
       and (start_at is null or current_timestamp() >= start_at)
      then 'Oui' else 'Non'
    end as en_retard,

    case
      when end_at is not null
       and current_timestamp() > end_at
       and (start_at is null or current_timestamp() >= start_at)
      then greatest(timestamp_diff(current_timestamp(), end_at, day), 0)
      else 0
    end as retard_jours,

    -- Jours relatifs (peuvent être négatifs si à venir)
    case when start_at is not null then timestamp_diff(date_trunc(current_timestamp(), day), start_at, day) end as jours_depuis_debut,
    case when end_at   is not null then timestamp_diff(end_at, date_trunc(current_timestamp(), day), day)   end as jours_avant_fin,
    case when start_at is not null then timestamp_diff(start_at, date_trunc(current_timestamp(), day), day) end as jours_avant_debut,

    -- Découpage calendrier (pour partition/clustering/analyses)
    date_trunc(start_date, month) as mois_debut,
    extract(year from start_date) as annee_debut,
    extract(quarter from start_date) as trimestre_debut,

    -- géo
    position,
    position_wkt,

    -- trafic brut conservé
    traffic,
    deviated,
    slow,
    normal,

    -- meta
    _loaded_at,
    _staged_at,
    current_timestamp() as _updated_at
  from stg
)

select
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

  -- géo
  position,
  position_wkt,

  -- suivi & délais
  en_retard,
  retard_jours,
  jours_depuis_debut,
  jours_avant_debut,
  jours_avant_fin,

  -- calendrier
  mois_debut,
  annee_debut,
  trimestre_debut,

  -- trafic brut
  traffic,
  deviated,
  slow,
  normal,

  -- meta
  _loaded_at,
  _staged_at,
  _updated_at
from enriched
    );
  