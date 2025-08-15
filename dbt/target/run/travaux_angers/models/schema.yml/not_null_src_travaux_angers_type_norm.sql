
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select type_norm
from `my-project-travaux-angers`.`travaux_angers_bronze`.`src_travaux_angers`
where type_norm is null



  
  
      
    ) dbt_internal_test