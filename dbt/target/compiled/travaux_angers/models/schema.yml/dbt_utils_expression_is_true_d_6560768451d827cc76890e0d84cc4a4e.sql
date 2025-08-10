



select
    1
from `my-project-travaux-angers`.`travaux_angers_gold`.`dim_travaux_details`

where not(date_fin date_fin >= date_debut)

