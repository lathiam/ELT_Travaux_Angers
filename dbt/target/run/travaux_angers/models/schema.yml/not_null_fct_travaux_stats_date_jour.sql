
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select date_jour
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
where date_jour is null



  
  
      
    ) dbt_internal_test