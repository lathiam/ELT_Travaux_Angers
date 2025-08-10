



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`

where not(retard_jours retard_jours >= 0)

