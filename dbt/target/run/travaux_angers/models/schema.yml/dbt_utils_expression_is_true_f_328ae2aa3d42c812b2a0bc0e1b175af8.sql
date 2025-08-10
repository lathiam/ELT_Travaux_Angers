
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

where not(nombre_travaux > 0)


  
  
      
    ) dbt_internal_test