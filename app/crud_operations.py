#!/usr/bin/env python3
"""
Module CRUD - Opérations Create, Read, Update, Delete
Gestion complète des entités: Clients, Voitures, Locations, Propriétaires
"""

from database import Database
from datetime import datetime, date
import sys

class CRUDClient:
    """Opérations CRUD pour les clients"""
    
    def __init__(self, db: Database):
        self.db = db
    
    def create(self, codec: str, nom: str, prenom: str, age: int, 
               permis: str, adresse: str, ville: str) -> bool:
        """Créer un nouveau client"""
        query = """
            INSERT INTO Client (CodeC, Nom, Prenom, Age, Permis, Adresse, Ville)
            VALUES (:1, :2, :3, :4, :5, :6, :7)
        """
        try:
            self.db.execute_update(query, (codec, nom, prenom, age, permis, adresse, ville))
            print(f"✅ Client {nom} {prenom} créé avec succès (Code: {codec})")
            return True
        except Exception as e:
            print(f"❌ Erreur lors de la création: {e}")
            return False
    
    def read(self, codec: str = None) -> list:
        """Lire un ou tous les clients"""
        if codec:
            query = "SELECT * FROM Client WHERE CodeC = :1"
            return self.db.execute_query(query, (codec,))
        else:
            query = "SELECT * FROM Client ORDER BY Nom, Prenom"
            return self.db.execute_query(query)
    
    def update(self, codec: str, **kwargs) -> bool:
        """Mettre à jour un client (kwargs: nom, prenom, age, permis, adresse, ville)"""
        # Construire la requête dynamiquement
        updates = []
        values = []
        
        mapping = {
            'nom': 'Nom',
            'prenom': 'Prenom',
            'age': 'Age',
            'permis': 'Permis',
            'adresse': 'Adresse',
            'ville': 'Ville'
        }
        
        for key, value in kwargs.items():
            if key in mapping and value is not None:
                updates.append(f"{mapping[key]} = :{len(values) + 1}")
                values.append(value)
        
        if not updates:
            print("❌ Aucune modification à effectuer")
            return False
        
        values.append(codec)
        query = f"UPDATE Client SET {', '.join(updates)} WHERE CodeC = :{len(values)}"
        
        try:
            rows = self.db.execute_update(query, tuple(values))
            if rows > 0:
                print(f"✅ Client {codec} mis à jour ({rows} ligne(s))")
                return True
            else:
                print(f"⚠️  Client {codec} non trouvé")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la mise à jour: {e}")
            return False
    
    def delete(self, codec: str) -> bool:
        """Supprimer un client"""
        # Vérifier d'abord s'il a des locations
        check_query = "SELECT COUNT(*) FROM Location WHERE CodeC = :1"
        result = self.db.execute_query(check_query, (codec,))
        nb_locations = result[0][0] if result else 0
        
        if nb_locations > 0:
            print(f"⚠️  Impossible de supprimer: {nb_locations} location(s) associée(s)")
            print("   Supprimez d'abord les locations ou utilisez CASCADE")
            return False
        
        query = "DELETE FROM Client WHERE CodeC = :1"
        try:
            rows = self.db.execute_update(query, (codec,))
            if rows > 0:
                print(f"✅ Client {codec} supprimé")
                return True
            else:
                print(f"⚠️  Client {codec} non trouvé")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la suppression: {e}")
            return False
    
    def list_all(self):
        """Afficher tous les clients de manière formatée"""
        clients = self.read()
        if not clients:
            print("Aucun client trouvé")
            return
        
        print(f"\n{'='*100}")
        print(f"{'Code':<10} {'Nom':<20} {'Prénom':<20} {'Âge':<5} {'Ville':<20}")
        print(f"{'='*100}")
        
        for client in clients:
            codec, nom, prenom, age, permis, adresse, ville = client
            nom_str = nom if nom else ""
            prenom_str = prenom if prenom else ""
            age_str = str(age) if age is not None else "N/A"
            ville_str = ville if ville else "N/A"
            print(f"{codec:<10} {nom_str:<20} {prenom_str:<20} {age_str:<5} {ville_str:<20}")
        
        print(f"{'='*100}")
        print(f"Total: {len(clients)} client(s)")


class CRUDVoiture:
    """Opérations CRUD pour les voitures"""
    
    def __init__(self, db: Database):
        self.db = db
    
    def create(self, immat: str, modele: str, marque: str, categorie: str,
               couleur: str, places: int, achat_annee: int, compteur: int,
               prix_jour: float, code_proprio: str) -> bool:
        """Créer une nouvelle voiture"""
        query = """
            INSERT INTO Voiture (Immat, Modele, Marque, Categorie, Couleur,
                               Places, achatA, compteur, prixJ, codeP)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10)
        """
        try:
            self.db.execute_update(query, (immat, modele, marque, categorie, couleur,
                                          places, achat_annee, compteur, prix_jour, code_proprio))
            print(f"✅ Voiture {marque} {modele} créée (Immat: {immat})")
            return True
        except Exception as e:
            print(f"❌ Erreur lors de la création: {e}")
            return False
    
    def read(self, immat: str = None) -> list:
        """Lire une ou toutes les voitures"""
        if immat:
            query = "SELECT * FROM Voiture WHERE Immat = :1"
            return self.db.execute_query(query, (immat,))
        else:
            query = "SELECT * FROM Voiture ORDER BY Marque, Modele"
            return self.db.execute_query(query)
    
    def update(self, immat: str, **kwargs) -> bool:
        """Mettre à jour une voiture"""
        updates = []
        values = []
        
        mapping = {
            'modele': 'Modele',
            'marque': 'Marque',
            'categorie': 'Categorie',
            'couleur': 'Couleur',
            'places': 'Places',
            'achat_annee': 'achatA',
            'compteur': 'compteur',
            'prix_jour': 'prixJ',
            'code_proprio': 'codeP',
            'etat': 'etat'
        }
        
        for key, value in kwargs.items():
            if key in mapping and value is not None:
                updates.append(f"{mapping[key]} = :{len(values) + 1}")
                values.append(value)
        
        if not updates:
            print("❌ Aucune modification à effectuer")
            return False
        
        values.append(immat)
        query = f"UPDATE Voiture SET {', '.join(updates)} WHERE Immat = :{len(values)}"
        
        try:
            rows = self.db.execute_update(query, tuple(values))
            if rows > 0:
                print(f"✅ Voiture {immat} mise à jour ({rows} ligne(s))")
                return True
            else:
                print(f"⚠️  Voiture {immat} non trouvée")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la mise à jour: {e}")
            return False
    
    def delete(self, immat: str) -> bool:
        """Supprimer une voiture"""
        # Vérifier les locations
        check_query = "SELECT COUNT(*) FROM Location WHERE Immat = :1"
        result = self.db.execute_query(check_query, (immat,))
        nb_locations = result[0][0] if result else 0
        
        if nb_locations > 0:
            print(f"⚠️  Impossible de supprimer: {nb_locations} location(s) associée(s)")
            return False
        
        query = "DELETE FROM Voiture WHERE Immat = :1"
        try:
            rows = self.db.execute_update(query, (immat,))
            if rows > 0:
                print(f"✅ Voiture {immat} supprimée")
                return True
            else:
                print(f"⚠️  Voiture {immat} non trouvée")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la suppression: {e}")
            return False
    
    def list_all(self, disponibles_only=False):
        """Afficher toutes les voitures"""
        if disponibles_only:
            query = "SELECT * FROM Voiture WHERE etat = 'disponible' ORDER BY Marque, Modele"
            voitures = self.db.execute_query(query)
        else:
            voitures = self.read()
        
        if not voitures:
            print("Aucune voiture trouvée")
            return
        
        print(f"\n{'='*120}")
        print(f"{'Immat':<12} {'Marque':<15} {'Modèle':<15} {'Catégorie':<12} {'Prix/J':<8} {'KM':<10} {'État':<15}")
        print(f"{'='*120}")
        
        for v in voitures:
            immat, modele, marque, categorie, couleur, places, achat, compteur, prix, codep, etat = v
            print(f"{immat:<12} {marque:<15} {modele:<15} {categorie:<12} {prix:>6.2f}€ {compteur:>9,} {etat or 'N/A':<15}")
        
        print(f"{'='*120}")
        print(f"Total: {len(voitures)} voiture(s)")


class CRUDLocation:
    """Opérations CRUD pour les locations"""
    
    def __init__(self, db: Database):
        self.db = db
    
    def create(self, codec: str, immat: str, annee: int, mois: int, numloc: str,
               km: int, duree: int, villed: str, villea: str, 
               dated: date, datef: date = None) -> bool:
        """Créer une nouvelle location"""
        query = """
            INSERT INTO Location (CodeC, Immat, Annee, Mois, numLoc, km, duree,
                                villed, villea, dated, datef)
            VALUES (:1, :2, :3, :4, :5, :6, :7, :8, :9, :10, :11)
        """
        try:
            self.db.execute_update(query, (codec, immat, annee, mois, numloc, km, duree,
                                          villed, villea, dated, datef))
            print(f"✅ Location créée: Client {codec}, Voiture {immat}")
            return True
        except Exception as e:
            print(f"❌ Erreur lors de la création: {e}")
            return False
    
    def read(self, codec: str = None, immat: str = None) -> list:
        """Lire les locations d'un client ou d'une voiture"""
        if codec:
            query = "SELECT * FROM Location WHERE CodeC = :1 ORDER BY Annee DESC, Mois DESC"
            return self.db.execute_query(query, (codec,))
        elif immat:
            query = "SELECT * FROM Location WHERE Immat = :1 ORDER BY Annee DESC, Mois DESC"
            return self.db.execute_query(query, (immat,))
        else:
            query = "SELECT * FROM Location ORDER BY Annee DESC, Mois DESC"
            return self.db.execute_query(query)
    
    def update(self, codec: str, immat: str, annee: int, mois: int, numloc: str, **kwargs) -> bool:
        """Mettre à jour une location"""
        updates = []
        values = []
        
        mapping = {
            'km': 'km',
            'duree': 'duree',
            'villed': 'villed',
            'villea': 'villea',
            'dated': 'dated',
            'datef': 'datef',
            'note': 'note',
            'avis': 'avis'
        }
        
        for key, value in kwargs.items():
            if key in mapping and value is not None:
                updates.append(f"{mapping[key]} = :{len(values) + 1}")
                values.append(value)
        
        if not updates:
            print("❌ Aucune modification à effectuer")
            return False
        
        values.extend([codec, immat, annee, mois, numloc])
        query = f"""UPDATE Location SET {', '.join(updates)} 
                   WHERE CodeC = :{len(values)-4} AND Immat = :{len(values)-3} 
                   AND Annee = :{len(values)-2} AND Mois = :{len(values)-1} 
                   AND numLoc = :{len(values)}"""
        
        try:
            rows = self.db.execute_update(query, tuple(values))
            if rows > 0:
                print(f"✅ Location mise à jour ({rows} ligne(s))")
                return True
            else:
                print(f"⚠️  Location non trouvée")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la mise à jour: {e}")
            return False
    
    def delete(self, codec: str, immat: str, annee: int, mois: int, numloc: str) -> bool:
        """Supprimer une location"""
        query = """DELETE FROM Location 
                   WHERE CodeC = :1 AND Immat = :2 AND Annee = :3 AND Mois = :4 AND numLoc = :5"""
        try:
            rows = self.db.execute_update(query, (codec, immat, annee, mois, numloc))
            if rows > 0:
                print(f"✅ Location supprimée")
                return True
            else:
                print(f"⚠️  Location non trouvée")
                return False
        except Exception as e:
            print(f"❌ Erreur lors de la suppression: {e}")
            return False
    
    def list_all(self, limit: int = 50):
        """Afficher les locations récentes"""
        query = f"""
            SELECT l.*, c.Nom, c.Prenom, v.Marque, v.Modele
            FROM Location l
            JOIN Client c ON l.CodeC = c.CodeC
            JOIN Voiture v ON l.Immat = v.Immat
            ORDER BY l.Annee DESC, l.Mois DESC
            FETCH FIRST {limit} ROWS ONLY
        """
        locations = self.db.execute_query(query)
        
        if not locations:
            print("Aucune location trouvée")
            return
        
        print(f"\n{'='*130}")
        print(f"{'Client':<25} {'Voiture':<25} {'Période':<15} {'Durée':<8} {'KM':<8} {'Note':<6} {'Avis':<20}")
        print(f"{'='*130}")
        
        for loc in locations:
            codec, immat, annee, mois, numloc, km, duree, villed, villea, dated, datef, note, avis, nom, prenom, marque, modele = loc
            client = f"{nom} {prenom}"
            voiture = f"{marque} {modele}"
            periode = f"{mois:02d}/{annee}"
            note_str = f"{note}/5" if note else "N/A"
            avis_str = (avis[:17] + '...') if avis and len(avis) > 20 else (avis or 'N/A')
            
            print(f"{client:<25} {voiture:<25} {periode:<15} {duree:>5} j {km:>7} {note_str:<6} {avis_str:<20}")
        
        print(f"{'='*130}")
        print(f"Total: {len(locations)} location(s) affichée(s)")


class CRUDProprietaire:
    """Opérations CRUD pour les propriétaires"""
    
    def __init__(self, db: Database):
        self.db = db
    
    def create(self, codep: str, pseudo: str, email: str, ville: str, annee_inscription: int) -> bool:
        """Créer un nouveau propriétaire"""
        query = """
            INSERT INTO Proprietaire (CodeP, pseudo, email, Ville, anneeI)
            VALUES (:1, :2, :3, :4, :5)
        """
        try:
            self.db.execute_update(query, (codep, pseudo, email, ville, annee_inscription))
            print(f"✅ Propriétaire {pseudo} créé (Code: {codep})")
            return True
        except Exception as e:
            print(f"❌ Erreur lors de la création: {e}")
            return False
    
    def read(self, codep: str = None) -> list:
        """Lire un ou tous les propriétaires"""
        if codep:
            query = "SELECT * FROM Proprietaire WHERE CodeP = :1"
            return self.db.execute_query(query, (codep,))
        else:
            query = "SELECT * FROM Proprietaire ORDER BY pseudo"
            return self.db.execute_query(query)
    
    def list_with_stats(self):
        """Afficher les propriétaires avec leurs statistiques"""
        query = """
            SELECT p.CodeP, p.pseudo, p.email, p.Ville, p.anneeI,
                   COUNT(DISTINCT v.Immat) as nb_voitures,
                   COUNT(l.CodeC) as nb_locations
            FROM Proprietaire p
            LEFT JOIN Voiture v ON p.CodeP = v.codeP
            LEFT JOIN Location l ON v.Immat = l.Immat
            GROUP BY p.CodeP, p.pseudo, p.email, p.Ville, p.anneeI
            ORDER BY nb_locations DESC, nb_voitures DESC
        """
        proprios = self.db.execute_query(query)
        
        if not proprios:
            print("Aucun propriétaire trouvé")
            return
        
        print(f"\n{'='*110}")
        print(f"{'Code':<10} {'Pseudo':<20} {'Ville':<20} {'Voitures':<10} {'Locations':<10} {'Inscrit':<10}")
        print(f"{'='*110}")
        
        for p in proprios:
            codep, pseudo, email, ville, annee, nb_voit, nb_loc = p
            print(f"{codep:<10} {pseudo:<20} {ville or 'N/A':<20} {nb_voit:>9} {nb_loc:>10} {annee or 'N/A':>10}")
        
        print(f"{'='*110}")
        print(f"Total: {len(proprios)} propriétaire(s)")


def demo_crud_operations():
    """Démonstration des opérations CRUD"""
    print("="*80)
    print("DÉMONSTRATION DES OPÉRATIONS CRUD")
    print("="*80)
    
    db = Database()
    if not db.connect():
        print("Impossible de se connecter à la base de données")
        return
    
    try:
        # === CRUD Clients ===
        print("\n" + "="*80)
        print("1. OPÉRATIONS CRUD - CLIENTS")
        print("="*80)
        
        crud_client = CRUDClient(db)
        
        print("\n📋 Liste des clients actuels:")
        crud_client.list_all()
        
        print("\n➕ CREATE: Création d'un nouveau client")
        crud_client.create(
            codec="C999",
            nom="Dupont",
            prenom="Jean",
            age=35,
            permis="1234567890",
            adresse="123 rue de la Paix",
            ville="Paris"
        )
        
        print("\n📖 READ: Lecture du client créé")
        client = crud_client.read("C999")
        if client:
            print(f"   Client trouvé: {client[0]}")
        
        print("\n✏️  UPDATE: Modification de l'âge et de la ville")
        crud_client.update("C999", age=36, ville="Lyon")
        
        print("\n📖 READ après UPDATE:")
        client = crud_client.read("C999")
        if client:
            print(f"   Client modifié: {client[0]}")
        
        print("\n🗑️  DELETE: Suppression du client")
        crud_client.delete("C999")
        
        # === CRUD Voitures ===
        print("\n" + "="*80)
        print("2. OPÉRATIONS CRUD - VOITURES")
        print("="*80)
        
        crud_voiture = CRUDVoiture(db)
        
        print("\n📋 Voitures disponibles:")
        crud_voiture.list_all(disponibles_only=True)
        
        print("\n➕ CREATE: Ajout d'une nouvelle voiture")
        crud_voiture.create(
            immat="TEST123",
            modele="Model 3",
            marque="Tesla",
            categorie="electrique",
            couleur="Blanc",
            places=5,
            achat_annee=2024,
            compteur=5000,
            prix_jour=89.99,
            code_proprio="P12"
        )
        
        print("\n✏️  UPDATE: Modification du prix et de l'état")
        crud_voiture.update("TEST123", prix_jour=79.99, etat="en maintenance")
        
        print("\n📖 READ: Voiture après modification")
        voiture = crud_voiture.read("TEST123")
        if voiture:
            print(f"   Voiture: {voiture[0]}")
        
        print("\n🗑️  DELETE: Suppression de la voiture")
        crud_voiture.delete("TEST123")
        
        # === CRUD Locations ===
        print("\n" + "="*80)
        print("3. OPÉRATIONS CRUD - LOCATIONS")
        print("="*80)
        
        crud_location = CRUDLocation(db)
        
        print("\n📋 Locations récentes:")
        crud_location.list_all(limit=10)
        
        # === Propriétaires ===
        print("\n" + "="*80)
        print("4. STATISTIQUES - PROPRIÉTAIRES")
        print("="*80)
        
        crud_proprio = CRUDProprietaire(db)
        crud_proprio.list_with_stats()
        
    finally:
        db.disconnect()


if __name__ == "__main__":
    demo_crud_operations()
