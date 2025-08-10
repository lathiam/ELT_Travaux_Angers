



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`

where not(duree_prevue duree_prevue >= 0)

