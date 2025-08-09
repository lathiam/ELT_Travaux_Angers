import os
import logging
from google.cloud import bigquery
from pathlib import Path

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Création du dossier logs et configuration du FileHandler pour log_load.txt
path = Path(__file__).parent
log_path = path / "logs"
log_path.mkdir(exist_ok=True)
file_handler = logging.FileHandler(str(log_path / "log_load.txt"), encoding="utf-8")
file_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logger.addHandler(file_handler)

logger.info("Début du script load.py")

csv_path = path / "data" / "data.csv"
logger.info(f"Chemin du fichier CSV : {csv_path}")

# Initialisation du client BigQuery
client = bigquery.Client()
logger.info("Client BigQuery initialisé")

# Paramètres de la table
table_id = os.environ.get("TABLE_ID")
if not table_id:
    logger.error("TABLE_ID n'est pas défini dans l'environnement")
    exit(1)
logger.info(f"Table cible : {table_id}")

job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,
    skip_leading_rows=1,
    autodetect=True,
)

with open(csv_path, "rb") as source_file:
    logger.info("Début du chargement des données dans BigQuery")
    job = client.load_table_from_file(source_file, table_id, job_config=job_config)

job.result()  # Attendre la fin du chargement
logger.info("Chargement terminé dans BigQuery")

print("Import terminé dans BigQuery:", table_id)