#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import logging
from pathlib import Path

# =========================
# Logging (console + fichier)
# =========================
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Console handler (pour voir dans le terminal)
ch = logging.StreamHandler(sys.stdout)
ch.setLevel(logging.INFO)
ch.setFormatter(logging.Formatter("[%(levelname)s] %(message)s"))
logger.addHandler(ch)

# File handler (pour avoir un historique)
path = Path(__file__).parent
log_path = path / "logs"
log_path.mkdir(exist_ok=True)
fh = logging.FileHandler(str(log_path / "log_load.txt"), encoding="utf-8")
fh.setLevel(logging.INFO)
fh.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logger.addHandler(fh)

logger.info("Début du script load.py")

# =========================
# Import BigQuery
# =========================
try:
    from google.cloud import bigquery
    logger.info("Module google.cloud.bigquery importé avec succès")
except ImportError as e:
    logger.error(f"Erreur lors de l'importation de google.cloud.bigquery: {e}")
    logger.error("Astuce: pip install google-cloud-bigquery")
    sys.exit(1)

# =========================
# Localisation du CSV
# =========================
csv_dir = path / "data"
candidates = [csv_dir / "data.csv", csv_dir / "data.csv.gz"]

csv_path = None
for c in candidates:
    if c.exists():
        csv_path = c
        break

if not csv_path:
    logger.error(f"Aucun fichier CSV trouvé parmi: {', '.join(str(c) for c in candidates)}")
    sys.exit(1)

logger.info(f"Fichier détecté : {csv_path}")

# Comptage rapide des lignes si non-gz (indicatif)
if csv_path.suffix == ".csv":
    try:
        with open(csv_path, "rb") as f:
            line_count = sum(1 for _ in f)
        logger.info(f"Lignes détectées (brut, en-tête inclus): {line_count}")
        if line_count <= 1:
            logger.error("Le CSV semble vide (aucune donnée). Abandon.")
            sys.exit(1)
    except Exception as e:
        logger.warning(f"Impossible de compter les lignes rapidement: {e}")

# =========================
# Crédentials GCP (afficher et valider)
# =========================
credentials_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
logger.info(f"GOOGLE_APPLICATION_CREDENTIALS = {credentials_path}")

if not credentials_path:
    logger.error("La variable d'environnement GOOGLE_APPLICATION_CREDENTIALS n'est pas définie.")
    logger.error("Définis-la vers le fichier JSON du compte de service.")
    sys.exit(1)

cred_file = Path(credentials_path)
if not cred_file.exists():
    logger.error(f"Fichier d'identifiants inexistant : {credentials_path}")
    # Petits indices utiles à l'écran
    parent_dir = cred_file.parent
    try:
        if parent_dir.exists():
            logger.info(f"Contenu de {parent_dir}:")
            for p in sorted(parent_dir.iterdir()):
                logger.info(f" - {p}")
        else:
            logger.info(f"Le dossier parent n'existe pas: {parent_dir}")
    except Exception as e:
        logger.info(f"Impossible de lister {parent_dir}: {e}")
    logger.info("Vérifie bien le chemin (casse, orthographe, ex: 'credentiels' vs 'credentials').")
    logger.info("Sous WSL, utilise un chemin Linux, ex: /usr/ELT_Travaux_Angers/credentiels/mon_compte_de_service.json")
    sys.exit(1)

logger.info(f"Fichier d'identifiants trouvé : {credentials_path}")

# =========================
# Table cible (TABLE_ID ou reconstruction)
# =========================
table_id = os.environ.get("TABLE_ID")
if not table_id:
    project_id = os.environ.get("PROJECT_ID")
    dataset_id = os.environ.get("DATASET_ID")
    if not project_id or not dataset_id:
        logger.error("Impossible de déterminer TABLE_ID : définis TABLE_ID ou PROJECT_ID + DATASET_ID.")
        sys.exit(1)
    table_id = f"{project_id}.{dataset_id}.travaux_angers"
logger.info(f"Table cible : {table_id}")

# =========================
# Client BigQuery
# =========================
try:
    client = bigquery.Client(location=os.getenv("LOCATION") or None)
    logger.info("Client BigQuery initialisé")
except Exception as e:
    logger.error(f"Erreur lors de l'initialisation du client BigQuery : {e}")
    sys.exit(1)

# =========================
# Paramètres du job (via env, avec logs)
# =========================
write_disposition_str = os.getenv("WRITE_DISPOSITION", "WRITE_TRUNCATE").upper()
create_disposition_str = os.getenv("CREATE_DISPOSITION", "CREATE_IF_NEEDED").upper()

wd_map = {
    "WRITE_TRUNCATE": bigquery.WriteDisposition.WRITE_TRUNCATE,
    "WRITE_APPEND": bigquery.WriteDisposition.WRITE_APPEND,
    "WRITE_EMPTY": bigquery.WriteDisposition.WRITE_EMPTY,
}
cd_map = {
    "CREATE_IF_NEEDED": bigquery.CreateDisposition.CREATE_IF_NEEDED,
    "CREATE_NEVER": bigquery.CreateDisposition.CREATE_NEVER,
}

write_disposition = wd_map.get(write_disposition_str, bigquery.WriteDisposition.WRITE_TRUNCATE)
create_disposition = cd_map.get(create_disposition_str, bigquery.CreateDisposition.CREATE_IF_NEEDED)

field_delimiter = os.getenv("FIELD_DELIMITER", ",")
encoding = os.getenv("ENCODING", "UTF-8")
ignore_unknown_values = os.getenv("IGNORE_UNKNOWN_VALUES", "true").lower() == "true"
allow_quoted_newlines = os.getenv("ALLOW_QUOTED_NEWLINES", "true").lower() == "true"

logger.info(f"WRITE_DISPOSITION={write_disposition_str} | CREATE_DISPOSITION={create_disposition_str}")
logger.info(f"DELIMITER='{field_delimiter}' | ENCODING={encoding} | QUOTED_NEWLINES={allow_quoted_newlines} | IGNORE_UNKNOWN={ignore_unknown_values}")

# Détection partitionnement table existante
is_partitioned = False
try:
    table_meta = client.get_table(table_id)
    is_partitioned = bool(getattr(table_meta, "time_partitioning", None) or getattr(table_meta, "range_partitioning", None))
    logger.info(f"Table existante détectée. Partitionnée: {is_partitioned}")
except Exception:
    logger.info("La table n'existe pas encore (elle sera créée si nécessaire).")

# Configuration du job
job_config = bigquery.LoadJobConfig(
    source_format=bigquery.SourceFormat.CSV,  # BigQuery accepte CSV et CSV.gz
    skip_leading_rows=1,
    autodetect=True,
    write_disposition=write_disposition,
    create_disposition=create_disposition,
    field_delimiter=field_delimiter,
    allow_quoted_newlines=allow_quoted_newlines,
    encoding=encoding,
    ignore_unknown_values=ignore_unknown_values,
)

# schema_update_options uniquement si autorisé
can_use_schema_update = (
    write_disposition == bigquery.WriteDisposition.WRITE_APPEND
    or (write_disposition == bigquery.WriteDisposition.WRITE_TRUNCATE and is_partitioned)
)
if can_use_schema_update:
    job_config.schema_update_options = [
        bigquery.SchemaUpdateOption.ALLOW_FIELD_ADDITION,
        bigquery.SchemaUpdateOption.ALLOW_FIELD_RELAXATION,
    ]
    logger.info("schema_update_options activé.")
else:
    logger.info("schema_update_options désactivé (non autorisé pour cette combinaison).")

# =========================
# Lancement du load
# =========================
try:
    with open(csv_path, "rb") as source_file:
        logger.info("Début du chargement des données dans BigQuery…")
        job = client.load_table_from_file(source_file, table_id, job_config=job_config)

    job.result()  # attend la fin du job
    logger.info("Chargement terminé.")

    # Récap
    errors = job.errors or []
    output_rows = getattr(job, "output_rows", None)

    table = client.get_table(table_id)
    logger.info(f"Table {table_id} -> {table.num_rows} lignes, {len(table.schema)} colonnes.")
    if output_rows is not None:
        logger.info(f"Lignes chargées (job): {output_rows}")
    if errors:
        logger.error(f"Erreurs BQ (job.errors): {errors}")
    else:
        logger.info("Aucune erreur BQ reportée par le job.")

    # Message final lisible en console
    print(f"[OK] Import terminé dans BigQuery: {table_id} | lignes table: {table.num_rows}")

except Exception as e:
    logger.error(f"Erreur lors du chargement des données dans BigQuery : {e}", exc_info=True)
    print(f"[ERREUR] Échec du chargement BigQuery: {e}")
    sys.exit(1)
