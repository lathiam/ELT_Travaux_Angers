
    
    

with all_values as (

    select
        en_retard as value_field,
        count(*) as n_records

    from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
    group by en_retard

)

select *
from all_values
where value_field not in (
    'Oui','Non'
)


