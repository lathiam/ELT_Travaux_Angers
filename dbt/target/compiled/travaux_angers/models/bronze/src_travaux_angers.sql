-- bronze/src_travaux_angers.sql
-- Source brute des données de travaux
SELECT
    *,
    CURRENT_TIMESTAMP() as _loaded_at
FROM `my-project-travaux-angers`.`travaux_angers`.`travaux_angers`