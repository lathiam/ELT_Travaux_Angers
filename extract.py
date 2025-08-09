import requests
from pathlib import Path
import pandas as pd
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)

parent = Path(__file__).parent
data_path = parent / "data"
data_path.mkdir(exist_ok=True)
log_path = parent / "logs"
log_path.mkdir(exist_ok=True)

# Créer un handler pour écrire dans log_extract.txt
file_handler = logging.FileHandler(str(log_path / "log_extract.txt"), encoding="utf-8")
file_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logging.getLogger().addHandler(file_handler)

all_results = []

logging.info("Début de la récupération des données.")

for i in range(0, 45):
    url = f"https://data.angers.fr/api/explore/v2.1/catalog/datasets/info-travaux/records?where=startat%3C=now()%20AND%20endat%3E=now()&limit=100&offset={i}"
    logging.info(f"Requête {i+1}/45 : {url}")
    response = requests.get(url)
    try:
        data = response.json()
        if "results" in data:
            all_results.extend(data["results"])
            logging.info(f"{len(data['results'])} résultats ajoutés (total : {len(all_results)})")
        else:
            logging.warning("Aucun champ 'results' dans la réponse.")
    except Exception as e:
        logging.error(f"Erreur lors du décodage JSON : {e}")

df = pd.DataFrame(all_results)
df.to_csv(data_path / "data.csv", index=False)
logging.info(f"Toutes les données ont été enregistrées dans {data_path / 'data.csv'}")