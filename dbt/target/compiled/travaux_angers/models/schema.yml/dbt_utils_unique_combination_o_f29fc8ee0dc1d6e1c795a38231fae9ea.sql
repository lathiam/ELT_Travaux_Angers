





with validation_errors as (

    select
        id, start_at, end_at, title, address, position_wkt
    from `my-project-travaux-angers`.`travaux_angers_silver`.`stg_travaux_angers`
    group by id, start_at, end_at, title, address, position_wkt
    having count(*) > 1

)

select *
from validation_errors


