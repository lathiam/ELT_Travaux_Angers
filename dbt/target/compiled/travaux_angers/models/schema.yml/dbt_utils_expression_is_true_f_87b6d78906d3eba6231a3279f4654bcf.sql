



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

where not(ratio_actif BETWEEN 0 AND 1)

