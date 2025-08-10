



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`

where not(taux_retard taux_retard IS NULL OR (taux_retard BETWEEN 0 AND 1))

