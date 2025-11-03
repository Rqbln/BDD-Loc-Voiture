"""
Script d'import des données CSV dans Oracle
"""
import pandas as pd
import sys
from pathlib import Path

# Ajouter le dossier app au path
sys.path.insert(0, str(Path(__file__).parent))

from database import db
from config import CSV_FILES

def import_proprietaires():
    """Importer les propriétaires"""
    print("\n📊 Import des PROPRIETAIRES...")
    
    try:
        df = pd.read_csv(CSV_FILES['proprietaire'], sep=';')
        print(f"   Fichier chargé: {len(df)} lignes")
        
        # Préparer les données
        data = []
        for _, row in df.iterrows():
            data.append((
                str(row['codeP']).strip() if pd.notna(row['codeP']) else None,
                str(row['Pseudo']).strip() if pd.notna(row['Pseudo']) else None,
                str(row['email']).strip() if pd.notna(row['email']) and str(row['email']) != 'NULL' else None,
                str(row['ville']).strip() if pd.notna(row['ville']) else None,
                int(float(row['anneeI'])) if pd.notna(row['anneeI']) else None
            ))
        
        # Insérer
        query = """
            INSERT INTO Proprietaire (CodeP, pseudo, email, Ville, anneeI)
            VALUES (:1, :2, :3, :4, :5)
        """
        
        rows = db.execute_many(query, data)
        print(f"   ✓ {rows} propriétaires importés")
        return True
        
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def import_clients():
    """Importer les clients"""
    print("\n📊 Import des CLIENTS...")
    
    try:
        df = pd.read_csv(CSV_FILES['client'], sep=';')
        print(f"   Fichier chargé: {len(df)} lignes")
        
        data = []
        for _, row in df.iterrows():
            data.append((
                str(row['CodeC']).strip() if pd.notna(row['CodeC']) else None,
                str(row['Nom']).strip() if pd.notna(row['Nom']) else None,
                str(row['Prenom']).strip() if pd.notna(row['Prenom']) else None,
                int(row['age']) if pd.notna(row['age']) else None,
                str(row['Permis']).strip() if pd.notna(row['Permis']) else None,
                str(row['Adresse']).strip() if pd.notna(row['Adresse']) else None,
                str(row['Ville']).strip() if pd.notna(row['Ville']) else None
            ))
        
        query = """
            INSERT INTO Client (CodeC, Nom, Prenom, Age, Permis, Adresse, Ville)
            VALUES (:1, :2, :3, :4, :5, :6, :7)
        """
        
        rows = db.execute_many(query, data)
        print(f"   ✓ {rows} clients importés")
        return True
        
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def import_voitures():
    """Importer les voitures"""
    print("\n📊 Import des VOITURES...")
    
    try:
        df = pd.read_csv(CSV_FILES['voiture'], sep=';')
        print(f"   Fichier chargé: {len(df)} lignes")
        # Préparer les données
        data = []
        for _, row in df.iterrows():
            data.append((
                str(row['Immat']).strip() if pd.notna(row['Immat']) else None,
                str(row['modele']).strip() if pd.notna(row['modele']) else None,
                str(row['Marque']).strip() if pd.notna(row['Marque']) else None,
                str(row['Categorie']).strip() if pd.notna(row['Categorie']) else None,
                str(row['couleur']).strip() if pd.notna(row['couleur']) else None,
                int(row['places']) if pd.notna(row['places']) else None,
                int(float(row['achatA'])) if pd.notna(row['achatA']) else None,
                int(row['compteur']) if pd.notna(row['compteur']) else None,
                float(row['prixJ']) if pd.notna(row['prixJ']) else None,
                str(row['codeP']).strip() if pd.notna(row['codeP']) else None
            ))
        
        query = """
            INSERT INTO Voiture (Immat, Modele, Marque, Categorie, Couleur, 
                               Places, achatA, compteur, prixJ, codeP)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10)
        """
        
        rows = db.execute_many(query, data)
        print(f"   ✓ {rows} voitures importées")
        return True
        
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def import_locations():
    """Importer les locations"""
    print("\n📊 Import des LOCATIONS...")
    
    try:
        df = pd.read_csv(CSV_FILES['location'], sep=';')
        print(f"   Fichier chargé: {len(df)} lignes")
        
        data = []
        for _, row in df.iterrows():
            # Convertir les dates si présentes
            dated = None
            datef = None
            
            if pd.notna(row.get('dated')):
                try:
                    dated = pd.to_datetime(row['dated'])
                except:
                    pass
            
            if pd.notna(row.get('datef')):
                try:
                    datef = pd.to_datetime(row['datef'])
                except:
                    pass
            
            data.append((
                str(row['CodeC']).strip() if pd.notna(row['CodeC']) else None,
                str(row['immat']).strip() if pd.notna(row['immat']) else None,
                int(row['annee']) if pd.notna(row['annee']) else None,
                int(row['mois']) if pd.notna(row['mois']) else None,
                str(row['numloc']).strip() if pd.notna(row['numloc']) else None,
                int(row['km']) if pd.notna(row['km']) else None,
                int(row['duree']) if pd.notna(row['duree']) else None,
                str(row['villed']).strip() if pd.notna(row['villed']) else None,
                str(row['villea']).strip() if pd.notna(row['villea']) else None,
                dated,
                datef,
                int(row['note']) if pd.notna(row.get('note')) and str(row['note']) != 'NULL' else None,
                str(row['avis']).strip() if pd.notna(row.get('avis')) and str(row['avis']) != 'NULL' else None
            ))
        
        query = """
            INSERT INTO Location (CodeC, Immat, Annee, Mois, numLoc, km, duree,
                                villed, villea, dated, datef, note, avis)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11, :12, :13)
        """
        
        rows = db.execute_many(query, data)
        print(f"   ✓ {rows} locations importées")
        return True
        
    except Exception as e:
        print(f"   ❌ Erreur: {e}")
        return False

def verify_import():
    """Vérifier les données importées"""
    print("\n📊 Vérification des données...")
    
    stats = db.get_table_stats()
    if stats:
        for table_name, num_rows in stats:
            print(f"   {table_name}: {num_rows or 0} lignes")
    
    # Analyser les statistiques
    db.execute_update("BEGIN DBMS_STATS.GATHER_SCHEMA_STATS(USER); END;")
    print("   ✓ Statistiques mises à jour")

def main():
    """Fonction principale"""
    print("="*60)
    print("🚀 Import des données CSV dans Oracle")
    print("="*60)
    
    # Connexion
    if not db.connect():
        print("\n❌ Impossible de se connecter à la base de données")
        return
    
    try:
        # Vérifier les fichiers CSV
        print("\n📁 Vérification des fichiers CSV...")
        for name, path in CSV_FILES.items():
            if Path(path).exists():
                print(f"   ✓ {name}: {path}")
            else:
                print(f"   ❌ MANQUANT: {path}")
                return
        
        # Nettoyer les tables existantes
        print("\n🗑️  Nettoyage des tables...")
        db.execute_update("DELETE FROM Location")
        db.execute_update("DELETE FROM Voiture")
        db.execute_update("DELETE FROM Client")
        db.execute_update("DELETE FROM Proprietaire")
        print("   ✓ Tables vidées")
        
        # Importer dans l'ordre (à cause des clés étrangères)
        success = True
        success = success and import_proprietaires()
        success = success and import_clients()
        success = success and import_voitures()
        success = success and import_locations()
        
        if success:
            # Vérifier
            verify_import()
            
            print("\n" + "="*60)
            print("✅ Import terminé avec succès!")
            print("="*60)
            print("\nProchaines étapes:")
            print("  1. Exécuter: @sql/02_constraints.sql (mise à jour des dates)")
            print("  2. Exécuter: @sql/03_views.sql (création des vues)")
            print("  3. Continuer avec les autres scripts SQL")
        else:
            print("\n❌ Import échoué")
    
    finally:
        db.disconnect()

if __name__ == "__main__":
    main()
