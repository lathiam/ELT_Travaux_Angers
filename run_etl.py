import subprocess
import os
import sys
import logging
from datetime import datetime

# Configuration du logging
logging.basicConfig(
    filename='logs/cron_etl.log',
    level=logging.INFO,
    format='%(asctime)s %(levelname)s:%(message)s'
)

log_run_path = 'logs/log_run.txt'

def log_run(message):
    with open(log_run_path, 'a') as f:
        f.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - {message}\n")

def run_dbt_command(command):
    """Exécute une commande DBT dans le dossier dbt/"""
    try:
        result = subprocess.run(
            command,
            cwd='dbt',  # Change le répertoire de travail pour DBT
            check=True,
            capture_output=True,
            text=True
        )
        logging.info(f"Commande DBT réussie: {' '.join(command)}")
        log_run(f"Commande DBT réussie: {' '.join(command)}")
        return True
    except subprocess.CalledProcessError as e:
        logging.error(f"Erreur lors de l'exécution de la commande DBT : {e}")
        log_run(f"Erreur lors de l'exécution de la commande DBT : {e}")
        if e.stdout:
            logging.error(f"Sortie standard : {e.stdout}")
            log_run(f"Sortie standard : {e.stdout}")
        if e.stderr:
            logging.error(f"Erreur standard : {e.stderr}")
            log_run(f"Erreur standard : {e.stderr}")
        return False

def main():
    try:
        # Vérification des variables d'environnement
        required_env_vars = ["GOOGLE_APPLICATION_CREDENTIALS", "TABLE_ID"]
        for var in required_env_vars:
            if not os.getenv(var):
                raise EnvironmentError(f"La variable d'environnement {var} n'est pas définie.")

        # 1. Extract
        logging.info("Début de l'ETL")
        log_run("Début de l'ETL")

        logging.info("Exécution de extract.py...")
        log_run("Exécution de extract.py...")
        subprocess.run([sys.executable, "extract.py"], check=True)
        logging.info("extract.py terminé")
        log_run("extract.py terminé")

        # 2. Load
        logging.info("Exécution de load.py...")
        log_run("Exécution de load.py...")
        subprocess.run([sys.executable, "load.py"], check=True)
        logging.info("load.py terminé")
        log_run("load.py terminé")

        # 3. Transform (DBT)
        logging.info("Début des transformations DBT...")
        log_run("Début des transformations DBT...")

        # Sauvegarder le répertoire courant
        original_dir = os.getcwd()

        try:
            # Changer vers le répertoire DBT
            dbt_dir = "/usr/ELT_Travaux_Angers/dbt"
            os.chdir(dbt_dir)
            logging.info(f"Exécution des commandes DBT depuis : {os.getcwd()}")

            # Exécuter dbt deps avec capture détaillée
            logging.info("Exécution de 'dbt deps'...")
            deps_process = subprocess.run(
                ["dbt", "deps"],
                capture_output=True,
                text=True
            )
            if deps_process.stdout:
                logging.info("Sortie de dbt deps :\n" + deps_process.stdout)
            if deps_process.stderr:
                logging.warning("Erreurs de dbt deps :\n" + deps_process.stderr)

            if deps_process.returncode == 0:
                logging.info("Commande DBT réussie: dbt deps")
                log_run("Commande DBT réussie: dbt deps")
            else:
                raise subprocess.CalledProcessError(deps_process.returncode, "dbt deps")

            # Exécuter dbt run avec capture détaillée
            logging.info("Exécution de 'dbt run'...")
            run_process = subprocess.run(
                ["dbt", "run"],
                capture_output=True,
                text=True
            )
            if run_process.stdout:
                logging.info("Sortie de dbt run :\n" + run_process.stdout)
            if run_process.stderr:
                logging.warning("Erreurs de dbt run :\n" + run_process.stderr)

            if run_process.returncode == 0:
                logging.info("Transformations DBT terminées avec succès")
                log_run("Transformations DBT terminées avec succès")
            else:
                error_msg = f"Erreur lors de l'exécution de dbt run (code {run_process.returncode})"
                if run_process.stderr:
                    error_msg += f"\nErreurs:\n{run_process.stderr}"
                if run_process.stdout:
                    error_msg += f"\nSortie:\n{run_process.stdout}"
                raise Exception(error_msg)

        except subprocess.CalledProcessError as e:
            error_msg = f"Erreur lors de l'exécution de la commande DBT : {str(e)}"
            if hasattr(e, 'stdout') and e.stdout:
                error_msg += f"\nSortie standard:\n{e.stdout}"
            if hasattr(e, 'stderr') and e.stderr:
                error_msg += f"\nErreur standard:\n{e.stderr}"
            logging.error(error_msg)
            log_run(error_msg)
            raise Exception("Échec de la commande DBT : " + error_msg)

        except Exception as e:
            error_msg = f"Erreur inattendue lors de l'exécution de DBT : {str(e)}"
            logging.error(error_msg)
            log_run(error_msg)
            raise

        finally:
            # Revenir au répertoire original
            os.chdir(original_dir)

        logging.info("ETL terminé avec succès")
        log_run("ETL terminé avec succès")

    except Exception as e:
        logging.error(f"Erreur lors de l'exécution : {e}")
        log_run(f"Erreur lors de l'exécution : {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()