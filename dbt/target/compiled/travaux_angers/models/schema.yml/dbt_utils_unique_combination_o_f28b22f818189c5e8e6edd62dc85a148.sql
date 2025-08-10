





with validation_errors as (

    select
        travaux_id, date_jour
    from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
    group by travaux_id, date_jour
    having count(*) > 1

)

select *
from validation_errors


