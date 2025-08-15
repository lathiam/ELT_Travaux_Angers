



select
    1
from `my-project-travaux-angers`.`travaux_angers_bronze`.`src_travaux_angers`

where not(end_date (end_date IS NULL) OR (end_date >= start_date))

