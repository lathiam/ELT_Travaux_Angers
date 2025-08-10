
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        a_geometrie as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats_geo`
    group by a_geometrie

)

select *
from all_values
where value_field not in (
    'Oui'
)



  
  
      
    ) dbt_internal_test