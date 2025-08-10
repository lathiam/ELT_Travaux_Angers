
    
    

with child as (
    select travaux_id as from_field
    from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
    where travaux_id is not null
),

parent as (
    select id as to_field
    from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


