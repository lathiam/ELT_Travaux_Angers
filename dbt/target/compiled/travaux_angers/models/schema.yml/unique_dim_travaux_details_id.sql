
    
    

with dbt_test__target as (

  select id as unique_field
  from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
  where id is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


