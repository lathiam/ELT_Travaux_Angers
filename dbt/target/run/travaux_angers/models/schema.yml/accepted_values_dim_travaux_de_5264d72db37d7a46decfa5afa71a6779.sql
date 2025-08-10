
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with all_values as (

    select
        impact_circulation as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
    group by impact_circulation

)

select *
from all_values
where value_field not in (
    'FORT','MOYEN','FAIBLE'
)



  
  
      
    ) dbt_internal_test