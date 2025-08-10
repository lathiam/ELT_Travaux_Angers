
  
    

    create or replace table `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats_geo`
      
    
    

    
    OPTIONS()
    as (
      SELECT
  *
FROM `my-project-travaux-angers`.`travaux_angers_gold`.`fct_travaux_stats`
WHERE a_geometrie = 'Oui'
    );
  