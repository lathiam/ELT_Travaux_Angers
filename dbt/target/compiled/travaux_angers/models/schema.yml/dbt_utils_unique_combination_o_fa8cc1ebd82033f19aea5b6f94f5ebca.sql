





with validation_errors as (

    select
        id, title, address, start_at, end_at, position_wkt
    from `my-project-travaux-angers`.`travaux_angers_bronze`.`src_travaux_angers`
    group by id, title, address, start_at, end_at, position_wkt
    having count(*) > 1

)

select *
from validation_errors


