import requests
from pathlib import Path
import pandas as pd
import logging
from time import sleep

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

parent = Path(__file__).parent
data_path = parent / "data"; data_path.mkdir(exist_ok=True)
log_path = parent / "logs"; log_path.mkdir(exist_ok=True)

file_handler = logging.FileHandler(str(log_path / "log_extract.txt"), encoding="utf-8")
file_handler.setFormatter(logging.Formatter("%(asctime)s - %(levelname)s - %(message)s"))
logging.getLogger().addHandler(file_handler)

BASE = "https://data.angers.fr/api/explore/v2.1/catalog/datasets/info-travaux/records"
LIMIT = 100

# ⚠️ Choisis l'un des deux WHERE selon ton besoin :
# 1) Tout le jeu (aucun filtre) :
WHERE = None
# 2) Uniquement les travaux en cours :
# WHERE = "startAt<=now() AND endAt>=now()"  # respecte bien la casse des champs

params = {
    "limit": LIMIT,
}
if WHERE:
    params["where"] = WHERE

all_rows = []
offset = 0
page = 0

logging.info("Début de la récupération…")

while True:
    page += 1
    params["offset"] = offset
    logging.info(f"Page {page} | offset={offset}")

    r = requests.get(BASE, params=params, timeout=30)
    r.raise_for_status()
    data = r.json()

    rows = data.get("results", [])
    if not rows:
        logging.info("Plus de résultats, arrêt.")
        break

    all_rows.extend(rows)
    logging.info(f"+{len(rows)} lignes (total {len(all_rows)})")

    # prochaine page
    offset += LIMIT
    sleep(0.1)  # petite pause pour être gentil avec l’API

# DataFrame + dédoublonnage (au cas où)
df = pd.DataFrame(all_rows)

# Si le dataset a une clé unique (ex: 'id' ou 'gid'), dédoublonne dessus :
for key in ["id", "gid", "recordid"]:  # adapte au vrai nom présent dans le JSON
    if key in df.columns:
        before = len(df)
        df = df.drop_duplicates(subset=[key])
        logging.info(f"Dédoublonné sur {key}: {before} -> {len(df)}")
        break
else:
    # sinon dédoublonne sur toutes colonnes (plus lent)
    before = len(df)
    df = df.drop_duplicates()
    logging.info(f"Dédoublonné sur toutes colonnes: {before} -> {len(df)}")

out = data_path / "data.csv"
df.to_csv(out, index=False)
logging.info(f"CSV écrit: {out} ({len(df)} lignes)")
print(f"CSV écrit: {out} ({len(df)} lignes)")
