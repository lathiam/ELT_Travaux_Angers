
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  




with left_table as (

  select
     as id

  from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats_geo`

  where  is not null
    and a_geometrie = 'Oui'

),

right_table as (

  select
    travaux_id as id

  from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

  where travaux_id is not null
    and 1=1

),

exceptions as (

  select
    left_table.id,
    right_table.id as right_id

  from left_table

  left join right_table
         on left_table.id = right_table.id

  where right_table.id is null

)

select * from exceptions


  
  
      
    ) dbt_internal_test