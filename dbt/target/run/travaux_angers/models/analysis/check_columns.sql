

  create or replace view `my-project-travaux-angers`.`travaux_angers`.`check_columns`
  OPTIONS()
  as 

SELECT *
FROM `my-project-travaux-angers`.`travaux_angers`.`travaux_angers`
LIMIT 1;

