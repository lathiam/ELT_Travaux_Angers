{{ config(
  materialized='table',
  partition_by = {"field": "date_jour", "data_type": "date"},
  cluster_by   = ["type_travaux", "niveau_impact"],
  on_schema_change = "sync_all_columns"
) }}

{# -----------------------------------------------------------
   GEO facts (jour x chantier) — uniquement si géométrie présente
   - dépend de gold.fct_travaux_stats
   - ajoute centroïde, lat/lon de secours, type géométrie, geohash, buffers
   ----------------------------------------------------------- #}

with base as (
  select *
  from {{ ref('fct_travaux_stats') }}
  where a_geometrie = 'Oui'
    and position_wkt is not null
),

enriched as (
  select
    b.*,

    -- si la table source a déjà lat/lon, on les reprend ; sinon on les calcule
    coalesce(
      b.latitude,
      case when b.position_wkt is not null
           then st_y(st_centroid(st_geogfromtext(b.position_wkt))) end
    ) as latitude_geo,

    coalesce(
      b.longitude,
      case when b.position_wkt is not null
           then st_x(st_centroid(st_geogfromtext(b.position_wkt))) end
    ) as longitude_geo,

    -- géométrie reconstruite pour opérations (si position_wkt présent)
    st_geogfromtext(b.position_wkt) as position_geo,

    -- type de géométrie (POINT / LINESTRING / POLYGON / …)
    case
      when b.position_wkt is not null then st_geometrytype(st_geogfromtext(b.position_wkt))
      else null
    end as position_type,

    -- centroïde "géographie"
    case
      when b.position_wkt is not null then st_centroid(st_geogfromtext(b.position_wkt))
      else null
    end as centroid_geo,

    -- geohash (7 ~ quartier/ville) pour agrégations spatiales simples
    case
      when b.position_wkt is not null then st_geohash(st_centroid(st_geogfromtext(b.position_wkt)), 7)
      else null
    end as geohash_7,

    -- buffers utiles (attention: en mètres sur GEOGRAPHY)
    case
      when b.position_wkt is not null then st_astext(st_buffer(st_centroid(st_geogfromtext(b.position_wkt)), 50))
      else null
    end as buffer50m_wkt,

    case
      when b.position_wkt is not null then st_astext(st_buffer(st_centroid(st_geogfromtext(b.position_wkt)), 200))
      else null
    end as buffer200m_wkt

  from base b
)

select
  -- clés & dimensions temporelles
  date_jour,
  type_travaux,
  travaux_id,

  mois_num, mois,
  jour_semaine_num, jour_semaine,

  -- libellés
  titre, adresse,

  -- géo
  position_wkt,
  position_type,
  centroid_geo,
  latitude_geo as latitude,
  longitude_geo as longitude,
  geohash_7,
  buffer50m_wkt,
  buffer200m_wkt,
  a_geometrie,

  -- temporel & activité
  date_debut, date_fin,
  est_actif, est_actif_libelle,

  -- retards & durées
  en_retard, retard_jours, retard_jours_libelle,
  duree_prevue, duree_prevue_libelle,

  -- agrégats jour/type
  total_travaux_type,
  travaux_actifs_type,
  travaux_retard_type,
  duree_moyenne_type,
  retard_moyen_type,

  -- impact
  niveau_impact,
  impact_fort_count,
  impact_moyen_count,
  impact_faible_count,

  -- taux
  taux_occupation,
  taux_occupation_libelle,
  taux_retard,
  taux_retard_libelle,

  -- zone agrégée & densité
  zone_travaux_wkt,
  densite_spatiale,

  current_timestamp() as _updated_at
from enriched
