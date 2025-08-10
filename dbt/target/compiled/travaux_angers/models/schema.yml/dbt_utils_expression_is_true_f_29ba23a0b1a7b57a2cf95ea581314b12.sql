



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

where not(taux_occupation taux_occupation IS NULL OR (taux_occupation BETWEEN 0 AND 1))

