
    
    

with all_values as (

    select
        impact_trafic as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
    group by impact_trafic

)

select *
from all_values
where value_field not in (
    'FORT','MOYEN','FAIBLE'
)


