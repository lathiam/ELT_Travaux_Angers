
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id
from `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
where id is null



  
  
      
    ) dbt_internal_test