
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  



select
    1
from `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`

where not(end_date (end_date IS NULL) OR (end_date >= start_date))


  
  
      
    ) dbt_internal_test