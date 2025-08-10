
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select jour_semaine
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
where jour_semaine is null



  
  
      
    ) dbt_internal_test