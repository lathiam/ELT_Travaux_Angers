
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select travaux_id
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
where travaux_id is null



  
  
      
    ) dbt_internal_test