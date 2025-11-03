"""
Gestion de la connexion à la base de données Oracle
"""
import oracledb
from config import ORACLE_CONFIG

class Database:
    """Classe pour gérer la connexion Oracle"""
    
    def __init__(self):
        self.connection = None
        self.cursor = None
    
    def connect(self):
        """Établir la connexion à Oracle"""
        try:
            # Mode Thin (pas besoin d'Oracle Instant Client)
            self.connection = oracledb.connect(**ORACLE_CONFIG)
            self.cursor = self.connection.cursor()
            print(f"✓ Connecté à Oracle Database (version {self.connection.version})")
            return True
        except Exception as e:
            print(f"❌ Erreur de connexion: {e}")
            return False
    
    def disconnect(self):
        """Fermer la connexion"""
        if self.cursor:
            self.cursor.close()
        if self.connection:
            self.connection.close()
            print("✓ Déconnexion réussie")
    
    def execute_query(self, query, params=None):
        """Exécuter une requête SELECT"""
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            return self.cursor.fetchall()
        except Exception as e:
            print(f"❌ Erreur d'exécution: {e}")
            return None
    
    def execute_update(self, query, params=None):
        """Exécuter une requête INSERT/UPDATE/DELETE"""
        try:
            if params:
                self.cursor.execute(query, params)
            else:
                self.cursor.execute(query)
            self.connection.commit()
            return self.cursor.rowcount
        except Exception as e:
            print(f"❌ Erreur d'exécution: {e}")
            self.connection.rollback()
            return None
    
    def execute_many(self, query, data_list):
        """Exécuter une requête en batch"""
        try:
            self.cursor.executemany(query, data_list)
            self.connection.commit()
            return self.cursor.rowcount
        except Exception as e:
            print(f"❌ Erreur d'exécution batch: {e}")
            self.connection.rollback()
            return None
    
    def call_procedure(self, proc_name, params=None):
        """Appeler une procédure stockée"""
        try:
            if params:
                self.cursor.callproc(proc_name, params)
            else:
                self.cursor.callproc(proc_name)
            self.connection.commit()
            return True
        except Exception as e:
            print(f"❌ Erreur d'appel de procédure: {e}")
            self.connection.rollback()
            return False
    
    def get_table_stats(self):
        """Obtenir les statistiques des tables"""
        query = """
            SELECT table_name, num_rows
            FROM user_tables
            WHERE table_name IN ('PROPRIETAIRE', 'CLIENT', 'VOITURE', 'LOCATION')
            ORDER BY table_name
        """
        return self.execute_query(query)

# Instance globale (singleton)
db = Database()
