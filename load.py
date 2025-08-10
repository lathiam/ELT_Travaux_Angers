import os
import logging
from pathlib import Path

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Création du dossier logs et configuration du FileHandler
path = Path(__file__).parent
log_path = path / "logs"
log_path.mkdir(exist_ok=True)
file_handler = logging.FileHandler(str(log_path / "log_load.txt"), encoding="utf-8")
file_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logger.addHandler(file_handler)

# Tentative d'importation de google.cloud.bigquery
try:
    from google.cloud import bigquery
    logger.info("Module google.cloud.bigquery importé avec succès")
except ImportError as e:
    logger.error(f"Erreur lors de l'importation de google.cloud.bigquery: {e}")
    logger.error("Essayez d'installer le module avec: sudo pip3 install --break-system-packages google-cloud-bigquery")
    exit(1)

logger.info("Début du script load.py")

csv_path = path / "data" / "data.csv"
logger.info(f"Chemin du fichier CSV : {csv_path}")

# Vérification de la variable d'environnement GOOGLE_APPLICATION_CREDENTIALS
credentials_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
if not credentials_path:
    logger.error("La variable d'environnement GOOGLE_APPLICATION_CREDENTIALS n'est pas définie.")
    exit(1)
elif not Path(credentials_path).exists():
    logger.error(f"Le fichier d'identifiants spécifié n'existe pas : {credentials_path}")
    exit(1)

# Initialisation du client BigQuery
try:
    client = bigquery.Client()
    logger.info("Client BigQuery initialisé")
except Exception as e:
    logger.error(f"Erreur lors de l'initialisation du client BigQuery : {e}")
    exit(1)

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

try:
    with open(csv_path, "rb") as source_file:
        logger.info("Début du chargement des données dans BigQuery")
        job = client.load_table_from_file(source_file, table_id, job_config=job_config)
    job.result()  # Attendre la fin du chargement
    logger.info("Chargement terminé dans BigQuery")
    print("Import terminé dans BigQuery:", table_id)
except Exception as e:
    logger.error(f"Erreur lors du chargement des données dans BigQuery : {e}")
    exit(1)