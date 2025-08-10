
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select position_wkt
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats_geo`
where position_wkt is null



  
  
      
    ) dbt_internal_test