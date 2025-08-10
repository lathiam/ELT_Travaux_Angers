
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select niveau_impact
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
where niveau_impact is null



  
  
      
    ) dbt_internal_test