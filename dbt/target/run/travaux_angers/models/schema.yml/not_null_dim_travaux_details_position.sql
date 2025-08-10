
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select position
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
where position is null



  
  
      
    ) dbt_internal_test