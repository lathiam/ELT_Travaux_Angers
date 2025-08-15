
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select start_date
from `my-project-travaux-angers`.`travaux_angers_bronze`.`src_travaux_angers`
where start_date is null



  
  
      
    ) dbt_internal_test