#!/usr/bin/env python3
"""
Menu interactif pour gérer la base de données
Interface utilisateur en ligne de commande
"""

from database import Database
from crud_operations import CRUDClient, CRUDVoiture, CRUDLocation, CRUDProprietaire
from datetime import datetime, date
import os
import sys

def clear_screen():
    """Nettoyer l'écran"""
    os.system('clear' if os.name != 'nt' else 'cls')

def pause():
    """Pause pour lire les résultats"""
    input("\nAppuyez sur Entrée pour continuer...")

def print_header(title):
    """Afficher un en-tête"""
    print("\n" + "="*80)
    print(f"  {title}")
    print("="*80)

class MenuInteractif:
    """Menu interactif pour la gestion de la BDD"""
    
    def __init__(self):
        self.db = Database()
        self.crud_client = None
        self.crud_voiture = None
        self.crud_location = None
        self.crud_proprio = None
    
    def connect(self):
        """Connexion à la base de données"""
        if self.db.connect():
            self.crud_client = CRUDClient(self.db)
            self.crud_voiture = CRUDVoiture(self.db)
            self.crud_location = CRUDLocation(self.db)
            self.crud_proprio = CRUDProprietaire(self.db)
            return True
        return False
    
    def disconnect(self):
        """Déconnexion"""
        self.db.disconnect()
    
    # ========== MENUS CLIENTS ==========
    
    def menu_clients(self):
        """Menu de gestion des clients"""
        while True:
            clear_screen()
            print_header("GESTION DES CLIENTS")
            print("1. Lister tous les clients")
            print("2. Rechercher un client")
            print("3. Créer un nouveau client")
            print("4. Modifier un client")
            print("5. Supprimer un client")
            print("0. Retour au menu principal")
            
            choix = input("\nVotre choix: ").strip()
            
            if choix == "1":
                self.lister_clients()
            elif choix == "2":
                self.rechercher_client()
            elif choix == "3":
                self.creer_client()
            elif choix == "4":
                self.modifier_client()
            elif choix == "5":
                self.supprimer_client()
            elif choix == "0":
                break
    
    def lister_clients(self):
        """Lister tous les clients"""
        clear_screen()
        print_header("LISTE DES CLIENTS")
        self.crud_client.list_all()
        pause()
    
    def rechercher_client(self):
        """Rechercher un client"""
        clear_screen()
        print_header("RECHERCHER UN CLIENT")
        codec = input("Code client (ex: C654): ").strip()
        
        clients = self.crud_client.read(codec)
        if clients:
            print(f"\n✅ Client trouvé:")
            codec, nom, prenom, age, permis, adresse, ville = clients[0]
            print(f"   Code: {codec}")
            print(f"   Nom: {nom} {prenom}")
            print(f"   Âge: {age} ans")
            print(f"   Permis: {permis}")
            print(f"   Adresse: {adresse}, {ville}")
            
            # Afficher ses locations
            print(f"\n📊 Locations de ce client:")
            locations = self.crud_location.read(codec=codec)
            if locations:
                print(f"   Nombre de locations: {len(locations)}")
                km_total = sum(loc[5] for loc in locations)
                print(f"   Kilométrage total: {km_total:,} km")
            else:
                print("   Aucune location")
        else:
            print(f"\n❌ Client {codec} non trouvé")
        
        pause()
    
    def creer_client(self):
        """Créer un nouveau client"""
        clear_screen()
        print_header("CRÉER UN NOUVEAU CLIENT")
        
        try:
            codec = input("Code client (ex: C999): ").strip()
            nom = input("Nom: ").strip()
            prenom = input("Prénom: ").strip()
            age = int(input("Âge: ").strip())
            permis = input("Numéro de permis: ").strip()
            adresse = input("Adresse: ").strip()
            ville = input("Ville: ").strip()
            
            print("\n📝 Résumé:")
            print(f"   Code: {codec}")
            print(f"   Nom: {nom} {prenom}")
            print(f"   Âge: {age} ans")
            print(f"   Ville: {ville}")
            
            confirmer = input("\nConfirmer la création ? (o/n): ").strip().lower()
            if confirmer == 'o':
                self.crud_client.create(codec, nom, prenom, age, permis, adresse, ville)
        except ValueError as e:
            print(f"❌ Erreur de saisie: {e}")
        except Exception as e:
            print(f"❌ Erreur: {e}")
        
        pause()
    
    def modifier_client(self):
        """Modifier un client"""
        clear_screen()
        print_header("MODIFIER UN CLIENT")
        
        codec = input("Code du client à modifier: ").strip()
        clients = self.crud_client.read(codec)
        
        if not clients:
            print(f"❌ Client {codec} non trouvé")
            pause()
            return
        
        # Afficher les infos actuelles
        _, nom, prenom, age, permis, adresse, ville = clients[0]
        print(f"\n📋 Informations actuelles:")
        print(f"   Nom: {nom}")
        print(f"   Prénom: {prenom}")
        print(f"   Âge: {age}")
        print(f"   Ville: {ville}")
        
        print("\n✏️  Nouvelles valeurs (Entrée pour conserver):")
        
        updates = {}
        
        new_nom = input(f"Nouveau nom [{nom}]: ").strip()
        if new_nom:
            updates['nom'] = new_nom
        
        new_prenom = input(f"Nouveau prénom [{prenom}]: ").strip()
        if new_prenom:
            updates['prenom'] = new_prenom
        
        new_age = input(f"Nouvel âge [{age}]: ").strip()
        if new_age:
            updates['age'] = int(new_age)
        
        new_ville = input(f"Nouvelle ville [{ville}]: ").strip()
        if new_ville:
            updates['ville'] = new_ville
        
        if updates:
            self.crud_client.update(codec, **updates)
        else:
            print("Aucune modification")
        
        pause()
    
    def supprimer_client(self):
        """Supprimer un client"""
        clear_screen()
        print_header("SUPPRIMER UN CLIENT")
        
        codec = input("Code du client à supprimer: ").strip()
        clients = self.crud_client.read(codec)
        
        if not clients:
            print(f"❌ Client {codec} non trouvé")
            pause()
            return
        
        _, nom, prenom, age, permis, adresse, ville = clients[0]
        print(f"\n⚠️  Voulez-vous vraiment supprimer:")
        print(f"   {nom} {prenom} (Code: {codec})")
        
        confirmer = input("\nConfirmer la suppression ? (o/n): ").strip().lower()
        if confirmer == 'o':
            self.crud_client.delete(codec)
        else:
            print("Suppression annulée")
        
        pause()
    
    # ========== MENUS VOITURES ==========
    
    def menu_voitures(self):
        """Menu de gestion des voitures"""
        while True:
            clear_screen()
            print_header("GESTION DES VOITURES")
            print("1. Lister toutes les voitures")
            print("2. Lister les voitures disponibles")
            print("3. Rechercher une voiture")
            print("4. Créer une nouvelle voiture")
            print("5. Modifier une voiture")
            print("6. Supprimer une voiture")
            print("7. Changer l'état d'une voiture")
            print("0. Retour au menu principal")
            
            choix = input("\nVotre choix: ").strip()
            
            if choix == "1":
                self.lister_voitures(False)
            elif choix == "2":
                self.lister_voitures(True)
            elif choix == "3":
                self.rechercher_voiture()
            elif choix == "4":
                self.creer_voiture()
            elif choix == "5":
                self.modifier_voiture()
            elif choix == "6":
                self.supprimer_voiture()
            elif choix == "7":
                self.changer_etat_voiture()
            elif choix == "0":
                break
    
    def lister_voitures(self, disponibles_only):
        """Lister les voitures"""
        clear_screen()
        titre = "VOITURES DISPONIBLES" if disponibles_only else "TOUTES LES VOITURES"
        print_header(titre)
        self.crud_voiture.list_all(disponibles_only)
        pause()
    
    def rechercher_voiture(self):
        """Rechercher une voiture"""
        clear_screen()
        print_header("RECHERCHER UNE VOITURE")
        immat = input("Immatriculation (ex: 11FG62): ").strip()
        
        voitures = self.crud_voiture.read(immat)
        if voitures:
            print(f"\n✅ Voiture trouvée:")
            immat, modele, marque, categorie, couleur, places, achat, compteur, prix, codep, etat = voitures[0]
            print(f"   Immatriculation: {immat}")
            print(f"   Véhicule: {marque} {modele}")
            print(f"   Catégorie: {categorie}")
            print(f"   Couleur: {couleur}")
            print(f"   Places: {places}")
            print(f"   Compteur: {compteur:,} km")
            print(f"   Prix/jour: {prix}€")
            print(f"   État: {etat}")
            print(f"   Propriétaire: {codep}")
            
            # Nombre de locations
            locations = self.crud_location.read(immat=immat)
            print(f"\n📊 Nombre de locations: {len(locations) if locations else 0}")
        else:
            print(f"\n❌ Voiture {immat} non trouvée")
        
        pause()
    
    def creer_voiture(self):
        """Créer une nouvelle voiture"""
        clear_screen()
        print_header("CRÉER UNE NOUVELLE VOITURE")
        
        try:
            immat = input("Immatriculation: ").strip()
            marque = input("Marque: ").strip()
            modele = input("Modèle: ").strip()
            categorie = input("Catégorie (luxe, premium, familiale, etc.): ").strip()
            couleur = input("Couleur: ").strip()
            places = int(input("Nombre de places: ").strip())
            achat_annee = int(input("Année d'achat: ").strip())
            compteur = int(input("Kilométrage: ").strip())
            prix_jour = float(input("Prix par jour (€): ").strip())
            code_proprio = input("Code propriétaire: ").strip()
            
            confirmer = input("\nConfirmer la création ? (o/n): ").strip().lower()
            if confirmer == 'o':
                self.crud_voiture.create(immat, modele, marque, categorie, couleur,
                                        places, achat_annee, compteur, prix_jour, code_proprio)
        except ValueError as e:
            print(f"❌ Erreur de saisie: {e}")
        
        pause()
    
    def modifier_voiture(self):
        """Modifier une voiture"""
        clear_screen()
        print_header("MODIFIER UNE VOITURE")
        
        immat = input("Immatriculation de la voiture à modifier: ").strip()
        voitures = self.crud_voiture.read(immat)
        
        if not voitures:
            print(f"❌ Voiture {immat} non trouvée")
            pause()
            return
        
        _, modele, marque, categorie, couleur, places, achat, compteur, prix, codep, etat = voitures[0]
        
        print(f"\n📋 Informations actuelles:")
        print(f"   Compteur: {compteur:,} km")
        print(f"   Prix/jour: {prix}€")
        print(f"   État: {etat}")
        
        print("\n✏️  Nouvelles valeurs (Entrée pour conserver):")
        
        updates = {}
        
        new_compteur = input(f"Nouveau compteur [{compteur}]: ").strip()
        if new_compteur:
            updates['compteur'] = int(new_compteur)
        
        new_prix = input(f"Nouveau prix/jour [{prix}]: ").strip()
        if new_prix:
            updates['prix_jour'] = float(new_prix)
        
        if updates:
            self.crud_voiture.update(immat, **updates)
        else:
            print("Aucune modification")
        
        pause()
    
    def supprimer_voiture(self):
        """Supprimer une voiture"""
        clear_screen()
        print_header("SUPPRIMER UNE VOITURE")
        
        immat = input("Immatriculation de la voiture à supprimer: ").strip()
        voitures = self.crud_voiture.read(immat)
        
        if not voitures:
            print(f"❌ Voiture {immat} non trouvée")
            pause()
            return
        
        _, modele, marque, categorie, couleur, places, achat, compteur, prix, codep, etat = voitures[0]
        print(f"\n⚠️  Voulez-vous vraiment supprimer:")
        print(f"   {marque} {modele} ({immat})")
        
        confirmer = input("\nConfirmer la suppression ? (o/n): ").strip().lower()
        if confirmer == 'o':
            self.crud_voiture.delete(immat)
        else:
            print("Suppression annulée")
        
        pause()
    
    def changer_etat_voiture(self):
        """Changer l'état d'une voiture"""
        clear_screen()
        print_header("CHANGER L'ÉTAT D'UNE VOITURE")
        
        immat = input("Immatriculation: ").strip()
        voitures = self.crud_voiture.read(immat)
        
        if not voitures:
            print(f"❌ Voiture {immat} non trouvée")
            pause()
            return
        
        _, modele, marque, categorie, couleur, places, achat, compteur, prix, codep, etat = voitures[0]
        print(f"\n📋 Voiture: {marque} {modele}")
        print(f"   État actuel: {etat}")
        
        print("\nÉtats possibles:")
        print("1. disponible")
        print("2. en location")
        print("3. en réparation")
        print("4. hors service")
        
        choix = input("\nNouveau état (1-4): ").strip()
        etats = {
            '1': 'disponible',
            '2': 'en location',
            '3': 'en réparation',
            '4': 'hors service'
        }
        
        if choix in etats:
            self.crud_voiture.update(immat, etat=etats[choix])
        else:
            print("❌ Choix invalide")
        
        pause()
    
    # ========== MENUS LOCATIONS ==========
    
    def menu_locations(self):
        """Menu de gestion des locations"""
        while True:
            clear_screen()
            print_header("GESTION DES LOCATIONS")
            print("1. Lister les locations récentes")
            print("2. Locations d'un client")
            print("3. Locations d'une voiture")
            print("4. Créer une nouvelle location")
            print("5. Modifier une location")
            print("0. Retour au menu principal")
            
            choix = input("\nVotre choix: ").strip()
            
            if choix == "1":
                self.lister_locations()
            elif choix == "2":
                self.locations_client()
            elif choix == "3":
                self.locations_voiture()
            elif choix == "4":
                self.creer_location()
            elif choix == "5":
                self.modifier_location()
            elif choix == "0":
                break
    
    def lister_locations(self):
        """Lister les locations récentes"""
        clear_screen()
        print_header("LOCATIONS RÉCENTES")
        self.crud_location.list_all(limit=30)
        pause()
    
    def locations_client(self):
        """Afficher les locations d'un client"""
        clear_screen()
        print_header("LOCATIONS D'UN CLIENT")
        
        codec = input("Code client: ").strip()
        locations = self.crud_location.read(codec=codec)
        
        if locations:
            print(f"\n✅ {len(locations)} location(s) trouvée(s)")
            km_total = sum(loc[5] for loc in locations)
            print(f"   Kilométrage total: {km_total:,} km")
        else:
            print(f"\n❌ Aucune location pour le client {codec}")
        
        pause()
    
    def locations_voiture(self):
        """Afficher les locations d'une voiture"""
        clear_screen()
        print_header("LOCATIONS D'UNE VOITURE")
        
        immat = input("Immatriculation: ").strip()
        locations = self.crud_location.read(immat=immat)
        
        if locations:
            print(f"\n✅ {len(locations)} location(s) trouvée(s)")
            km_total = sum(loc[5] for loc in locations)
            print(f"   Kilométrage total: {km_total:,} km")
        else:
            print(f"\n❌ Aucune location pour la voiture {immat}")
        
        pause()
    
    def creer_location(self):
        """Créer une nouvelle location"""
        clear_screen()
        print_header("CRÉER UNE NOUVELLE LOCATION")
        
        try:
            codec = input("Code client: ").strip()
            immat = input("Immatriculation voiture: ").strip()
            annee = int(input("Année: ").strip())
            mois = int(input("Mois (1-12): ").strip())
            numloc = input("Numéro location: ").strip()
            km = int(input("Kilométrage: ").strip())
            duree = int(input("Durée (jours): ").strip())
            villed = input("Ville de départ: ").strip()
            villea = input("Ville d'arrivée: ").strip()
            
            date_str = input("Date début (YYYY-MM-DD): ").strip()
            dated = datetime.strptime(date_str, "%Y-%m-%d").date()
            
            confirmer = input("\nConfirmer la création ? (o/n): ").strip().lower()
            if confirmer == 'o':
                self.crud_location.create(codec, immat, annee, mois, numloc,
                                         km, duree, villed, villea, dated)
        except ValueError as e:
            print(f"❌ Erreur de saisie: {e}")
        
        pause()
    
    def modifier_location(self):
        """Modifier une location"""
        clear_screen()
        print_header("MODIFIER UNE LOCATION")
        
        print("Pour modifier une location, vous devez fournir sa clé complète:")
        codec = input("Code client: ").strip()
        immat = input("Immatriculation: ").strip()
        annee = int(input("Année: ").strip())
        mois = int(input("Mois: ").strip())
        numloc = input("Numéro location: ").strip()
        
        print("\n✏️  Modifications (Entrée pour conserver):")
        
        updates = {}
        
        new_note = input("Note (1-5): ").strip()
        if new_note:
            updates['note'] = int(new_note)
        
        new_avis = input("Avis: ").strip()
        if new_avis:
            updates['avis'] = new_avis
        
        if updates:
            self.crud_location.update(codec, immat, annee, mois, numloc, **updates)
        else:
            print("Aucune modification")
        
        pause()
    
    # ========== MENU STATISTIQUES ==========
    
    def menu_statistiques(self):
        """Menu des statistiques"""
        while True:
            clear_screen()
            print_header("STATISTIQUES")
            print("1. Vue d'ensemble")
            print("2. Propriétaires avec stats")
            print("3. Top clients")
            print("4. Voitures rentables")
            print("0. Retour au menu principal")
            
            choix = input("\nVotre choix: ").strip()
            
            if choix == "1":
                self.stats_vue_ensemble()
            elif choix == "2":
                self.stats_proprietaires()
            elif choix == "3":
                self.stats_top_clients()
            elif choix == "4":
                self.stats_voitures_rentables()
            elif choix == "0":
                break
    
    def stats_vue_ensemble(self):
        """Statistiques générales"""
        clear_screen()
        print_header("VUE D'ENSEMBLE DU SYSTÈME")
        
        query = """
            SELECT 
                (SELECT COUNT(*) FROM Client) as nb_clients,
                (SELECT COUNT(*) FROM Voiture) as nb_voitures,
                (SELECT COUNT(*) FROM Location) as nb_locations,
                (SELECT COUNT(*) FROM Proprietaire) as nb_proprios,
                (SELECT AVG(note) FROM Location WHERE note IS NOT NULL) as note_moyenne
            FROM DUAL
        """
        
        result = self.db.execute_query(query)
        if result:
            nb_clients, nb_voitures, nb_locations, nb_proprios, note_moy = result[0]
            
            print(f"\n📊 Statistiques:")
            print(f"   Clients: {nb_clients}")
            print(f"   Voitures: {nb_voitures}")
            print(f"   Locations: {nb_locations}")
            print(f"   Propriétaires: {nb_proprios}")
            print(f"   Note moyenne: {note_moy:.2f}/5" if note_moy else "   Note moyenne: N/A")
        
        pause()
    
    def stats_proprietaires(self):
        """Stats des propriétaires"""
        clear_screen()
        print_header("STATISTIQUES DES PROPRIÉTAIRES")
        self.crud_proprio.list_with_stats()
        pause()
    
    def stats_top_clients(self):
        """Top clients"""
        clear_screen()
        print_header("TOP 10 CLIENTS PAR KILOMÉTRAGE")
        
        query = """
            SELECT c.CodeC, c.Nom, c.Prenom, 
                   COUNT(*) as nb_locations,
                   SUM(l.km) as km_total
            FROM Client c
            JOIN Location l ON c.CodeC = l.CodeC
            GROUP BY c.CodeC, c.Nom, c.Prenom
            ORDER BY km_total DESC
            FETCH FIRST 10 ROWS ONLY
        """
        
        clients = self.db.execute_query(query)
        
        if clients:
            print(f"\n{'Rang':<6} {'Client':<30} {'Locations':<12} {'KM Total':<15}")
            print("="*70)
            
            for i, (codec, nom, prenom, nb_loc, km) in enumerate(clients, 1):
                client_nom = f"{nom} {prenom}"
                print(f"{i:<6} {client_nom:<30} {nb_loc:>11} {km:>14,}")
        
        pause()
    
    def stats_voitures_rentables(self):
        """Voitures les plus rentables"""
        clear_screen()
        print_header("TOP 10 VOITURES PAR NOMBRE DE LOCATIONS")
        
        query = """
            SELECT v.Immat, v.Marque, v.Modele, v.prixJ,
                   COUNT(*) as nb_locations,
                   SUM(l.duree) as jours_total
            FROM Voiture v
            JOIN Location l ON v.Immat = l.Immat
            GROUP BY v.Immat, v.Marque, v.Modele, v.prixJ
            ORDER BY nb_locations DESC
            FETCH FIRST 10 ROWS ONLY
        """
        
        voitures = self.db.execute_query(query)
        
        if voitures:
            print(f"\n{'Immat':<12} {'Véhicule':<30} {'Prix/J':<10} {'Locations':<12} {'Jours':<10}")
            print("="*80)
            
            for immat, marque, modele, prix, nb_loc, jours in voitures:
                vehicule = f"{marque} {modele}"
                print(f"{immat:<12} {vehicule:<30} {prix:>7.2f}€ {nb_loc:>11} {jours:>9}")
        
        pause()
    
    # ========== MENU PRINCIPAL ==========
    
    def menu_principal(self):
        """Menu principal"""
        while True:
            clear_screen()
            print("╔" + "="*78 + "╗")
            print("║" + " "*20 + "SYSTÈME DE GESTION DE LOCATION" + " "*28 + "║")
            print("║" + " "*30 + "BDA 2025" + " "*41 + "║")
            print("╚" + "="*78 + "╝")
            
            print("\n📋 MENUS PRINCIPAUX:")
            print("   1. Gestion des Clients")
            print("   2. Gestion des Voitures")
            print("   3. Gestion des Locations")
            print("   4. Statistiques")
            print("\n   0. Quitter")
            
            choix = input("\nVotre choix: ").strip()
            
            if choix == "1":
                self.menu_clients()
            elif choix == "2":
                self.menu_voitures()
            elif choix == "3":
                self.menu_locations()
            elif choix == "4":
                self.menu_statistiques()
            elif choix == "0":
                print("\n👋 Au revoir !")
                break
            else:
                print("❌ Choix invalide")
                pause()
    
    def run(self):
        """Lancer l'application"""
        if self.connect():
            try:
                self.menu_principal()
            finally:
                self.disconnect()
        else:
            print("❌ Impossible de se connecter à la base de données")
            sys.exit(1)


if __name__ == "__main__":
    app = MenuInteractif()
    app.run()
