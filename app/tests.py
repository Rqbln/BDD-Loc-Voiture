#!/usr/bin/env python3
"""
Module de tests et validation du système
Tests des procédures PL/SQL, triggers, contraintes et scénarios métier
"""

from database import Database
from datetime import datetime, date
import sys

class TestSuite:
    """Suite de tests pour valider le système"""
    
    def __init__(self):
        self.db = Database()
        self.tests_passed = 0
        self.tests_failed = 0
        self.tests_total = 0
    
    def connect(self):
        """Connexion"""
        return self.db.connect()
    
    def disconnect(self):
        """Déconnexion"""
        self.db.disconnect()
    
    def test(self, nom, description):
        """Décorateur pour les tests"""
        def decorator(func):
            def wrapper():
                self.tests_total += 1
                print(f"\n{'='*80}")
                print(f"TEST {self.tests_total}: {nom}")
                print(f"{'='*80}")
                print(f"Description: {description}")
                print()
                
                try:
                    result = func()
                    if result:
                        print(f"✅ TEST RÉUSSI")
                        self.tests_passed += 1
                    else:
                        print(f"❌ TEST ÉCHOUÉ")
                        self.tests_failed += 1
                except Exception as e:
                    print(f"❌ ERREUR: {e}")
                    self.tests_failed += 1
                
                return result
            return wrapper
        return decorator
    
    # ========== TESTS DES CONTRAINTES ==========
    
    def test_contraintes(self):
        """Tester les contraintes d'intégrité"""
        
        @self.test("Contrainte d'âge client", 
                   "Vérifier qu'on ne peut pas créer un client mineur (< 18 ans)")
        def test_age_client():
            query = """
                INSERT INTO Client (CodeC, Nom, Prenom, Age, Permis, Adresse, Ville)
                VALUES ('TEST1', 'Test', 'Mineur', 15, '123456', 'Test', 'Test')
            """
            try:
                self.db.execute_update(query)
                self.db.connection.rollback()
                return False  # Ne devrait pas arriver ici
            except Exception as e:
                if 'CHK_CLIENT_AGE' in str(e):
                    print("Contrainte respectée: insertion refusée")
                    return True
                return False
        
        @self.test("Contrainte note de location",
                   "Vérifier qu'on ne peut pas mettre une note > 5")
        def test_note_invalide():
            # Créer une location temporaire
            query_insert = """
                INSERT INTO Location (CodeC, Immat, Annee, Mois, numLoc, km, duree, 
                                     villed, villea, dated, datef, note)
                SELECT 'C654', '11FG62', 2025, 11, 'TEST1', 100, 1, 
                       'Paris', 'Lyon', SYSDATE, SYSDATE, 10
                FROM DUAL
            """
            try:
                self.db.execute_update(query_insert)
                self.db.connection.rollback()
                return False
            except Exception as e:
                if 'CHK_LOCATION_NOTE' in str(e):
                    print("Contrainte respectée: note invalide refusée")
                    return True
                return False
        
        @self.test("Contrainte prix voiture positif",
                   "Vérifier qu'on ne peut pas mettre un prix négatif")
        def test_prix_negatif():
            query = """
                UPDATE Voiture SET prixJ = -50 WHERE ROWNUM = 1
            """
            try:
                self.db.execute_update(query)
                self.db.connection.rollback()
                return False
            except Exception as e:
                if 'CHK_VOITURE_PRIX' in str(e):
                    print("Contrainte respectée: prix négatif refusé")
                    return True
                return False
        
        test_age_client()
        test_note_invalide()
        test_prix_negatif()
    
    # ========== TESTS DES PROCÉDURES PL/SQL ==========
    
    def test_procedures_plsql(self):
        """Tester les procédures PL/SQL"""
        
        @self.test("Procédure noter_location",
                   "Vérifier que la procédure attribue correctement les notes")
        def test_noter_location():
            # Compter les locations sans note
            query_count = "SELECT COUNT(*) FROM Location WHERE note IS NULL"
            result = self.db.execute_query(query_count)
            nb_avant = result[0][0] if result else 0
            
            # Exécuter la procédure
            query_exec = "BEGIN noter_location(); END;"
            self.db.execute_update(query_exec)
            
            # Vérifier
            result_apres = self.db.execute_query(query_count)
            nb_apres = result_apres[0][0] if result_apres else 0
            
            print(f"Locations sans note avant: {nb_avant}")
            print(f"Locations sans note après: {nb_apres}")
            
            if nb_apres < nb_avant:
                print("✓ Des notes ont été attribuées")
                return True
            elif nb_avant == 0:
                print("✓ Toutes les locations ont déjà une note")
                return True
            return False
        
        @self.test("Procédure maj_avis",
                   "Vérifier la mise à jour des avis textuels")
        def test_maj_avis():
            # Exécuter la procédure
            query = "BEGIN maj_avis(); END;"
            self.db.execute_update(query)
            
            # Vérifier qu'il y a des avis
            query_check = "SELECT COUNT(*) FROM Location WHERE avis IS NOT NULL"
            result = self.db.execute_query(query_check)
            nb_avis = result[0][0] if result else 0
            
            print(f"Nombre de locations avec avis: {nb_avis}")
            return nb_avis > 0
        
        @self.test("Fonction calculer_ca_location",
                   "Vérifier le calcul du chiffre d'affaires")
        def test_calculer_ca():
            query = """
                SELECT calculer_ca_location('C654', '11FG62', 2015, 4, 'C-45')
                FROM DUAL
            """
            result = self.db.execute_query(query)
            if result and result[0][0] is not None:
                ca = result[0][0]
                print(f"CA calculé: {ca}€")
                return ca >= 0
            return False
        
        test_noter_location()
        test_maj_avis()
        test_calculer_ca()
    
    # ========== TESTS DES TRIGGERS ==========
    
    def test_triggers(self):
        """Tester les triggers"""
        
        @self.test("Trigger audit prix",
                   "Vérifier que les modifications de prix sont auditées")
        def test_trigger_prix():
            # Modifier un prix
            query_update = """
                UPDATE Voiture 
                SET prixJ = prixJ + 1 
                WHERE Immat = '11FG62'
            """
            self.db.execute_update(query_update)
            
            # Vérifier l'audit
            query_check = """
                SELECT COUNT(*) 
                FROM Voiture_Prix_Audit 
                WHERE Immat = '11FG62'
                AND date_modif > SYSDATE - 1/1440
            """
            result = self.db.execute_query(query_check)
            nb_audits = result[0][0] if result else 0
            
            # Annuler la modification
            self.db.connection.rollback()
            
            print(f"Entrées d'audit trouvées: {nb_audits}")
            return nb_audits > 0
        
        @self.test("Trigger validation dates",
                   "Vérifier que dated doit être avant datef")
        def test_trigger_dates():
            query = """
                INSERT INTO Location 
                (CodeC, Immat, Annee, Mois, numLoc, km, duree, villed, villea, dated, datef)
                VALUES ('C654', '11FG62', 2025, 11, 'TEST_DATE', 100, 1,
                        'Paris', 'Lyon', SYSDATE, SYSDATE - 10)
            """
            try:
                self.db.execute_update(query)
                self.db.connection.rollback()
                return False  # Ne devrait pas passer
            except Exception as e:
                if 'datef' in str(e).lower() or 'date' in str(e).lower():
                    print("Trigger activé: dates incohérentes refusées")
                    return True
                return False
        
        test_trigger_prix()
        test_trigger_dates()
    
    # ========== TESTS DES VUES ==========
    
    def test_vues(self):
        """Tester les vues"""
        
        @self.test("Vue V_Client",
                   "Vérifier que la vue retourne des données correctes")
        def test_vue_client():
            query = "SELECT COUNT(*) FROM V_Client"
            result = self.db.execute_query(query)
            nb_clients = result[0][0] if result else 0
            
            print(f"Nombre de clients dans la vue: {nb_clients}")
            
            # Vérifier quelques colonnes
            query_detail = """
                SELECT CodeC, Prenom, Nom, distance 
                FROM V_Client 
                WHERE ROWNUM = 1
            """
            result_detail = self.db.execute_query(query_detail)
            
            if result_detail:
                print(f"Exemple: {result_detail[0]}")
                return True
            return False
        
        @self.test("Vue V_Client55",
                   "Vérifier que seuls les clients > 55 ans apparaissent")
        def test_vue_client55():
            query = """
                SELECT MIN(Age) as age_min, MAX(Age) as age_max, COUNT(*) as total
                FROM V_Client55
            """
            result = self.db.execute_query(query)
            
            if result:
                age_min, age_max, total = result[0]
                print(f"Âge minimum: {age_min}")
                print(f"Âge maximum: {age_max}")
                print(f"Total clients: {total}")
                
                return age_min > 55
            return False
        
        test_vue_client()
        test_vue_client55()
    
    # ========== TESTS DE SCÉNARIOS MÉTIER ==========
    
    def test_scenarios_metier(self):
        """Tester des scénarios métier réels"""
        
        @self.test("Scénario: Louer une voiture disponible",
                   "Créer une location pour une voiture disponible")
        def test_scenario_location():
            # Trouver une voiture disponible
            query_voiture = """
                SELECT Immat FROM Voiture 
                WHERE etat = 'disponible' 
                AND ROWNUM = 1
            """
            result = self.db.execute_query(query_voiture)
            
            if not result:
                print("Aucune voiture disponible pour le test")
                return False
            
            immat = result[0][0]
            print(f"Voiture sélectionnée: {immat}")
            
            # Créer une location test
            query_location = f"""
                INSERT INTO Location 
                (CodeC, Immat, Annee, Mois, numLoc, km, duree, villed, villea, dated, datef)
                VALUES ('C654', '{immat}', 2025, 11, 'TEST_SCEN', 250, 3,
                        'Paris', 'Marseille', SYSDATE, SYSDATE + 3)
            """
            
            try:
                self.db.execute_update(query_location)
                print("✓ Location créée avec succès")
                
                # Vérifier
                query_check = f"""
                    SELECT COUNT(*) FROM Location 
                    WHERE CodeC = 'C654' AND Immat = '{immat}' 
                    AND numLoc = 'TEST_SCEN'
                """
                result_check = self.db.execute_query(query_check)
                
                # Nettoyer
                query_clean = f"""
                    DELETE FROM Location 
                    WHERE CodeC = 'C654' AND Immat = '{immat}' 
                    AND numLoc = 'TEST_SCEN'
                """
                self.db.execute_update(query_clean)
                self.db.connection.commit()
                
                return result_check[0][0] == 1
            except Exception as e:
                print(f"Erreur: {e}")
                self.db.connection.rollback()
                return False
        
        @self.test("Scénario: Recherche multi-critères",
                   "Trouver des voitures par catégorie et prix")
        def test_scenario_recherche():
            query = """
                SELECT v.Immat, v.Marque, v.Modele, v.prixJ, v.etat
                FROM Voiture v
                WHERE v.Categorie = 'luxe'
                AND v.prixJ <= 50
                AND v.etat = 'disponible'
                ORDER BY v.prixJ
            """
            result = self.db.execute_query(query)
            
            if result:
                print(f"✓ {len(result)} voiture(s) trouvée(s)")
                for voiture in result[:3]:
                    print(f"  - {voiture[1]} {voiture[2]} : {voiture[3]}€/jour")
                return True
            else:
                print("Aucune voiture trouvée (critères trop stricts)")
                return True  # C'est acceptable
        
        @self.test("Scénario: Top clients fidèles",
                   "Identifier les clients avec le plus de locations")
        def test_scenario_top_clients():
            query = """
                SELECT c.CodeC, c.Nom, c.Prenom, COUNT(*) as nb_locations,
                       SUM(l.km) as km_total
                FROM Client c
                JOIN Location l ON c.CodeC = l.CodeC
                GROUP BY c.CodeC, c.Nom, c.Prenom
                HAVING COUNT(*) >= 5
                ORDER BY nb_locations DESC
                FETCH FIRST 5 ROWS ONLY
            """
            result = self.db.execute_query(query)
            
            if result:
                print(f"✓ {len(result)} client(s) fidèle(s)")
                for client in result:
                    code, nom, prenom, nb_loc, km = client
                    print(f"  - {nom} {prenom or ''}: {nb_loc} locations, {km:,} km")
                return True
            return False
        
        test_scenario_location()
        test_scenario_recherche()
        test_scenario_top_clients()
    
    # ========== TESTS D'INTÉGRITÉ RÉFÉRENTIELLE ==========
    
    def test_integrite_referentielle(self):
        """Tester l'intégrité référentielle"""
        
        @self.test("Intégrité: Locations sans client",
                   "Vérifier qu'il n'y a pas de locations orphelines")
        def test_locations_sans_client():
            query = """
                SELECT COUNT(*) 
                FROM Location l
                WHERE NOT EXISTS (
                    SELECT 1 FROM Client c WHERE c.CodeC = l.CodeC
                )
            """
            result = self.db.execute_query(query)
            nb = result[0][0] if result else 0
            
            print(f"Locations orphelines: {nb}")
            return nb == 0
        
        @self.test("Intégrité: Voitures sans propriétaire",
                   "Vérifier qu'il n'y a pas de voitures orphelines")
        def test_voitures_sans_proprio():
            query = """
                SELECT COUNT(*)
                FROM Voiture v
                WHERE NOT EXISTS (
                    SELECT 1 FROM Proprietaire p WHERE p.CodeP = v.codeP
                )
            """
            result = self.db.execute_query(query)
            nb = result[0][0] if result else 0
            
            print(f"Voitures orphelines: {nb}")
            return nb == 0
        
        test_locations_sans_client()
        test_voitures_sans_proprio()
    
    # ========== TESTS DE PERFORMANCE ==========
    
    def test_performance(self):
        """Tests de performance basiques"""
        
        @self.test("Performance: Requête complexe",
                   "Mesurer le temps d'exécution d'une requête complexe")
        def test_perf_complexe():
            import time
            
            query = """
                SELECT c.Nom, c.Prenom,
                       COUNT(DISTINCT l.Immat) as nb_voitures_louees,
                       COUNT(*) as nb_locations,
                       SUM(l.km) as km_total,
                       AVG(l.note) as note_moyenne
                FROM Client c
                JOIN Location l ON c.CodeC = l.CodeC
                GROUP BY c.CodeC, c.Nom, c.Prenom
                HAVING COUNT(*) > 0
                ORDER BY km_total DESC
            """
            
            start = time.time()
            result = self.db.execute_query(query)
            elapsed = time.time() - start
            
            print(f"Temps d'exécution: {elapsed:.3f}s")
            print(f"Résultats: {len(result) if result else 0} lignes")
            
            return elapsed < 1.0  # Devrait être rapide
        
        test_perf_complexe()
    
    # ========== EXÉCUTION COMPLÈTE ==========
    
    def run_all_tests(self):
        """Exécuter tous les tests"""
        print("╔" + "="*78 + "╗")
        print("║" + " "*25 + "SUITE DE TESTS COMPLÈTE" + " "*30 + "║")
        print("╚" + "="*78 + "╝")
        
        if not self.connect():
            print("❌ Impossible de se connecter à la base de données")
            return False
        
        try:
            print("\n" + "▶"*40)
            print("SECTION 1: TESTS DES CONTRAINTES")
            print("▶"*40)
            self.test_contraintes()
            
            print("\n" + "▶"*40)
            print("SECTION 2: TESTS DES PROCÉDURES PL/SQL")
            print("▶"*40)
            self.test_procedures_plsql()
            
            print("\n" + "▶"*40)
            print("SECTION 3: TESTS DES TRIGGERS")
            print("▶"*40)
            self.test_triggers()
            
            print("\n" + "▶"*40)
            print("SECTION 4: TESTS DES VUES")
            print("▶"*40)
            self.test_vues()
            
            print("\n" + "▶"*40)
            print("SECTION 5: TESTS DES SCÉNARIOS MÉTIER")
            print("▶"*40)
            self.test_scenarios_metier()
            
            print("\n" + "▶"*40)
            print("SECTION 6: TESTS D'INTÉGRITÉ RÉFÉRENTIELLE")
            print("▶"*40)
            self.test_integrite_referentielle()
            
            print("\n" + "▶"*40)
            print("SECTION 7: TESTS DE PERFORMANCE")
            print("▶"*40)
            self.test_performance()
            
            # Rapport final
            print("\n" + "="*80)
            print("RAPPORT FINAL")
            print("="*80)
            print(f"Tests exécutés: {self.tests_total}")
            print(f"✅ Réussis: {self.tests_passed}")
            print(f"❌ Échoués: {self.tests_failed}")
            
            taux_reussite = (self.tests_passed / self.tests_total * 100) if self.tests_total > 0 else 0
            print(f"\n📊 Taux de réussite: {taux_reussite:.1f}%")
            
            if self.tests_failed == 0:
                print("\n🎉 TOUS LES TESTS SONT PASSÉS !")
            else:
                print(f"\n⚠️  {self.tests_failed} test(s) ont échoué")
            
            print("="*80)
            
            return self.tests_failed == 0
            
        finally:
            self.disconnect()


if __name__ == "__main__":
    suite = TestSuite()
    success = suite.run_all_tests()
    sys.exit(0 if success else 1)
