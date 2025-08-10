
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`

where not(duree_jours >= 0)


  
  
      
    ) dbt_internal_test