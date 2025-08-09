# Utilise l'image officielle Airflow avec Python
FROM apache/airflow:2.8.1-python3.9

# Copie les scripts dans le dossier de travail
COPY extract.py load.py requirement.txt ./
COPY credentiels/ ./credentiels/
COPY data/ ./data/

# Installe les dépendances
RUN pip install --no-cache-dir -r requirement.txt

# Variables d'environnement
ENV TABLE_ID=my-project-travaux-angers.travaux_angers.travaux_angers
ENV DATASET_ID=my-project-travaux-angers.travaux_angers
ENV PROJECT_ID=my-project-travaux-angers

# Dossier de travail
WORKDIR /opt/airflow

# Par défaut, Airflow démarre
CMD ["bash"]

