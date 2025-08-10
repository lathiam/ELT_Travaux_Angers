

  create or replace view `my-project-travaux-angers`.`travaux_angers`.`check_source`
  OPTIONS()
  as 

SELECT
    column_name,
    data_type
FROM `my-project-travaux-angers.travaux_angers`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name = 'travaux_angers'
ORDER BY ordinal_position;

