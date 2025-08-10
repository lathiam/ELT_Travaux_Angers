
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select date_debut
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
where date_debut is null



  
  
      
    ) dbt_internal_test