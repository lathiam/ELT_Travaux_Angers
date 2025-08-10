
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`

where not(date_fin date_fin >= date_debut)


  
  
      
    ) dbt_internal_test