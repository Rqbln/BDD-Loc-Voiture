"""
Configuration de la connexion à la base de données Oracle
"""
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Configuration Oracle
ORACLE_CONFIG = {
    'user': os.getenv('ORACLE_USER', 'BDA2025'),
    'password': os.getenv('ORACLE_PASSWORD', 'BDA2025Password'),
    'dsn': os.getenv('ORACLE_DSN', 'localhost:1521/FREEPDB1')
}

# Configuration des chemins
DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data')
SQL_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'sql')

# Fichiers CSV
CSV_FILES = {
    'proprietaire': os.path.join(DATA_DIR, 'proprietaire.csv'),
    'client': os.path.join(DATA_DIR, 'client.csv'),
    'voiture': os.path.join(DATA_DIR, 'voiture.csv'),
    'location': os.path.join(DATA_DIR, 'location.csv')
}
