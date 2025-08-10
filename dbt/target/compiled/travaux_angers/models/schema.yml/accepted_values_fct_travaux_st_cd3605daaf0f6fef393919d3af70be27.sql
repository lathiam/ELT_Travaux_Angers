
    
    

with all_values as (

    select
        niveau_impact as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
    group by niveau_impact

)

select *
from all_values
where value_field not in (
    'FORT','MOYEN','FAIBLE'
)


