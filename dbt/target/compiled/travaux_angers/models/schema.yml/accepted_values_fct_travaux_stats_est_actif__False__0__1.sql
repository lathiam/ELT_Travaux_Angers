
    
    

with all_values as (

    select
        est_actif as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
    group by est_actif

)

select *
from all_values
where value_field not in (
    0,1
)


