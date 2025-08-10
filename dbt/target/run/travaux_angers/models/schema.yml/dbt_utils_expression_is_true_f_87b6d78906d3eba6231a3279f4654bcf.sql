
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

where not(ratio_actif BETWEEN 0 AND 1)


  
  
      
    ) dbt_internal_test