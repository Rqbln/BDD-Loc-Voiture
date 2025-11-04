#!/usr/bin/env python3
"""
Module de visualisations - 5 graphiques pour analyser les données
"""

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import numpy as np
from database import Database
from datetime import datetime
import os

# Configuration matplotlib
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

# Créer le dossier pour les graphiques
OUTPUT_DIR = "visualizations"
os.makedirs(OUTPUT_DIR, exist_ok=True)

class DataVisualizer:
    """Classe pour créer les visualisations"""
    
    def __init__(self):
        self.db = Database()
        self.connect()
    
    def connect(self):
        """Connexion à la BDD"""
        if not self.db.connect():
            raise Exception("Impossible de se connecter à la base de données")
    
    def disconnect(self):
        """Déconnexion"""
        self.db.disconnect()
    
    def get_dataframe(self, query):
        """Exécuter une requête et retourner un DataFrame pandas"""
        result = self.db.execute_query(query)
        if result:
            return pd.DataFrame(result)
        return pd.DataFrame()
    
    # ========== VISUALISATION 1: Distribution des voitures par catégorie ==========
    
    def viz1_categories_voitures(self):
        """Graphique 1: Camembert des catégories de voitures"""
        print("\n📊 Visualisation 1: Distribution des catégories...")
        
        query = """
            SELECT Categorie, COUNT(*) as nombre
            FROM Voiture
            GROUP BY Categorie
            ORDER BY nombre DESC
        """
        
        df = self.get_dataframe(query)
        if df.empty:
            print("❌ Pas de données")
            return
        
        df.columns = ['Categorie', 'Nombre']
        
        # Créer le graphique
        fig, ax = plt.subplots(figsize=(10, 8))
        
        colors = sns.color_palette('pastel')[0:len(df)]
        wedges, texts, autotexts = ax.pie(
            df['Nombre'], 
            labels=df['Categorie'],
            autopct='%1.1f%%',
            colors=colors,
            startangle=90
        )
        
        # Améliorer l'apparence
        for autotext in autotexts:
            autotext.set_color('black')
            autotext.set_fontsize(10)
            autotext.set_weight('bold')
        
        ax.set_title('Distribution des Voitures par Catégorie', 
                     fontsize=16, weight='bold', pad=20)
        
        plt.tight_layout()
        filepath = f"{OUTPUT_DIR}/01_categories_voitures.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    # ========== VISUALISATION 2: Top 10 clients par kilométrage ==========
    
    def viz2_top_clients_km(self):
        """Graphique 2: Barres horizontales - Top clients par km"""
        print("\n📊 Visualisation 2: Top clients par kilométrage...")
        
        query = """
            SELECT c.Nom || ' ' || c.Prenom as client,
                   SUM(l.km) as km_total
            FROM Client c
            JOIN Location l ON c.CodeC = l.CodeC
            GROUP BY c.Nom, c.Prenom
            ORDER BY km_total DESC
            FETCH FIRST 10 ROWS ONLY
        """
        
        df = self.get_dataframe(query)
        if df.empty:
            print("❌ Pas de données")
            return
        
        df.columns = ['Client', 'KM_Total']
        
        # Créer le graphique
        fig, ax = plt.subplots(figsize=(12, 8))
        
        bars = ax.barh(df['Client'], df['KM_Total'], color=sns.color_palette('viridis', len(df)))
        
        # Ajouter les valeurs sur les barres
        for i, bar in enumerate(bars):
            width = bar.get_width()
            ax.text(width, bar.get_y() + bar.get_height()/2, 
                   f'{int(width):,} km',
                   ha='left', va='center', fontsize=9, weight='bold')
        
        ax.set_xlabel('Kilométrage Total (km)', fontsize=12, weight='bold')
        ax.set_title('Top 10 Clients par Kilométrage Parcouru', 
                     fontsize=16, weight='bold', pad=20)
        ax.invert_yaxis()
        ax.grid(axis='x', alpha=0.3)
        
        plt.tight_layout()
        filepath = f"{OUTPUT_DIR}/02_top_clients_km.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    # ========== VISUALISATION 3: Évolution des locations par mois ==========
    
    def viz3_evolution_locations(self):
        """Graphique 3: Courbe d'évolution des locations"""
        print("\n📊 Visualisation 3: Évolution des locations...")
        
        query = """
            SELECT Annee, Mois, COUNT(*) as nb_locations
            FROM Location
            GROUP BY Annee, Mois
            ORDER BY Annee, Mois
        """
        
        df = self.get_dataframe(query)
        if df.empty:
            print("❌ Pas de données")
            return
        
        df.columns = ['Annee', 'Mois', 'Nb_Locations']
        
        # Créer une colonne période
        df['Periode'] = df['Annee'].astype(str) + '-' + df['Mois'].astype(str).str.zfill(2)
        df = df.sort_values(['Annee', 'Mois'])
        
        # Créer le graphique
        fig, ax = plt.subplots(figsize=(14, 6))
        
        ax.plot(range(len(df)), df['Nb_Locations'], 
                marker='o', linewidth=2, markersize=8, 
                color='#2E86AB', label='Nombre de locations')
        
        # Remplir sous la courbe
        ax.fill_between(range(len(df)), df['Nb_Locations'], 
                        alpha=0.3, color='#2E86AB')
        
        # Personnaliser les axes
        ax.set_xticks(range(len(df)))
        ax.set_xticklabels(df['Periode'], rotation=45, ha='right')
        ax.set_xlabel('Période', fontsize=12, weight='bold')
        ax.set_ylabel('Nombre de Locations', fontsize=12, weight='bold')
        ax.set_title('Évolution du Nombre de Locations par Mois', 
                     fontsize=16, weight='bold', pad=20)
        ax.grid(True, alpha=0.3)
        ax.legend()
        
        plt.tight_layout()
        filepath = f"{OUTPUT_DIR}/03_evolution_locations.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    # ========== VISUALISATION 4: Distribution des notes de satisfaction ==========
    
    def viz4_satisfaction_notes(self):
        """Graphique 4: Analyse des notes de satisfaction"""
        print("\n📊 Visualisation 4: Notes de satisfaction...")
        
        query = """
            SELECT note, COUNT(*) as nb_locations
            FROM Location
            WHERE note IS NOT NULL
            GROUP BY note
            ORDER BY note
        """
        
        df = self.get_dataframe(query)
        if df.empty:
            print("❌ Pas de données")
            return
        
        df.columns = ['Note', 'Nb_Locations']
        
        # Créer une figure avec 2 sous-graphiques
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 6))
        
        # Graphique 1: Histogramme des notes
        colors = sns.color_palette('RdYlGn', len(df))
        bars = ax1.bar(df['Note'], df['Nb_Locations'], color=colors, edgecolor='black', linewidth=2, width=0.6)
        
        # Ajouter les valeurs sur les barres
        for bar in bars:
            height = bar.get_height()
            ax1.text(bar.get_x() + bar.get_width()/2., height,
                    f'{int(height)}',
                    ha='center', va='bottom', fontsize=12, weight='bold')
        
        ax1.set_xlabel('Note de Satisfaction (sur 5)', fontsize=14, weight='bold')
        ax1.set_ylabel('Nombre de Locations', fontsize=14, weight='bold')
        ax1.set_title('Distribution des Notes de Satisfaction', fontsize=16, weight='bold', pad=20)
        ax1.set_xticks([1, 2, 3, 4, 5])
        ax1.set_xlim(0.5, 5.5)
        ax1.grid(axis='y', alpha=0.3)
        
        # Ajouter statistiques
        total = df['Nb_Locations'].sum()
        moyenne = (df['Note'] * df['Nb_Locations']).sum() / total
        ax1.text(0.98, 0.98, f'Note moyenne: {moyenne:.2f}/5\nTotal: {total} locations',
                transform=ax1.transAxes, fontsize=12,
                verticalalignment='top', horizontalalignment='right',
                bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))
        
        # Graphique 2: Camembert (Pie chart)
        colors_pie = ['#ff6b6b', '#ffd93d', '#6bcf7f'][:len(df)]
        explode = [0.05] * len(df)
        
        wedges, texts, autotexts = ax2.pie(df['Nb_Locations'], 
                                            labels=[f'Note {int(n)}' for n in df['Note']], 
                                            autopct='%1.1f%%',
                                            colors=colors_pie,
                                            explode=explode,
                                            startangle=90,
                                            textprops={'fontsize': 11, 'weight': 'bold'})
        
        ax2.set_title('Répartition des Satisfactions', fontsize=16, weight='bold', pad=20)
        
        # Améliorer la lisibilité du pie chart
        for autotext in autotexts:
            autotext.set_color('white')
            autotext.set_fontsize(12)
        
        plt.tight_layout()
        filepath = f"{OUTPUT_DIR}/04_satisfaction_notes.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    # ========== VISUALISATION 5: Analyse multi-critères ==========
    
    def viz5_analyse_multicriteres(self):
        """Graphique 5: Analyse avancée - Popularité par catégorie"""
        print("\n📊 Visualisation 5: Analyse multi-critères...")
        
        query = """
            SELECT v.Categorie,
                   COUNT(DISTINCT v.Immat) as nb_voitures,
                   COUNT(l.CodeC) as nb_locations,
                   AVG(v.prixJ) as prix_moyen
            FROM Voiture v
            LEFT JOIN Location l ON v.Immat = l.Immat
            GROUP BY v.Categorie
            ORDER BY nb_locations DESC
        """
        
        df = self.get_dataframe(query)
        if df.empty:
            print("❌ Pas de données")
            return
        
        df.columns = ['Categorie', 'Nb_Voitures', 'Nb_Locations', 'Prix_Moyen']
        
        # Créer un graphique simple montrant la popularité par catégorie
        fig, ax = plt.subplots(1, 1, figsize=(14, 8))
        
        # Barres groupées - Voitures et Locations
        x = np.arange(len(df))
        width = 0.35
        
        bars1 = ax.bar(x - width/2, df['Nb_Voitures'], width, 
                       label='Nombre de voitures', color='skyblue', edgecolor='black', linewidth=1.5)
        bars2 = ax.bar(x + width/2, df['Nb_Locations'], width, 
                       label='Nombre de locations', color='salmon', edgecolor='black', linewidth=1.5)
        
        ax.set_xlabel('Catégorie', fontsize=14, weight='bold')
        ax.set_ylabel('Nombre', fontsize=14, weight='bold')
        ax.set_title('Analyse Popularité: Voitures et Locations par Catégorie', fontsize=16, weight='bold', pad=20)
        ax.set_xticks(x)
        ax.set_xticklabels(df['Categorie'], rotation=45, ha='right', fontsize=11)
        ax.legend(fontsize=12)
        ax.grid(axis='y', alpha=0.3)
        
        # Ajouter les valeurs sur les barres
        for bars in [bars1, bars2]:
            for bar in bars:
                height = bar.get_height()
                ax.text(bar.get_x() + bar.get_width()/2., height,
                        f'{int(height)}',
                        ha='center', va='bottom', fontsize=10, weight='bold')
        
        # Ajouter une note sur les prix
        note_prix = f"Prix moyen: {df['Prix_Moyen'].mean():.0f}€/jour"
        ax.text(0.98, 0.98, note_prix,
                transform=ax.transAxes, fontsize=12,
                verticalalignment='top', horizontalalignment='right',
                bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.8))
        
        plt.tight_layout()
        filepath = f"{OUTPUT_DIR}/05_analyse_multicriteres.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    # ========== BONUS: Dashboard récapitulatif ==========
    
    def viz_bonus_dashboard(self):
        """Bonus: Dashboard avec statistiques clés"""
        print("\n📊 Bonus: Dashboard récapitulatif...")
        
        # Récupérer les stats
        stats_query = """
            SELECT 
                (SELECT COUNT(*) FROM Client) as nb_clients,
                (SELECT COUNT(*) FROM Voiture) as nb_voitures,
                (SELECT COUNT(*) FROM Location) as nb_locations,
                (SELECT AVG(note) FROM Location WHERE note IS NOT NULL) as note_moy,
                (SELECT SUM(km) FROM Location) as km_total
            FROM DUAL
        """
        
        result = self.db.execute_query(stats_query)
        if not result:
            print("❌ Pas de données")
            return
        
        nb_clients, nb_voitures, nb_locations, note_moy, km_total = result[0]
        
        # Créer le dashboard
        fig = plt.figure(figsize=(16, 10))
        gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.3)
        
        # Titre principal
        fig.suptitle('DASHBOARD - SYSTÈME DE LOCATION DE VOITURES', 
                    fontsize=20, weight='bold', y=0.98)
        
        # Zone 1: Statistiques clés (en haut, sur toute la largeur)
        ax_stats = fig.add_subplot(gs[0, :])
        ax_stats.axis('off')
        
        stats_text = f"""
        📊 STATISTIQUES GÉNÉRALES
        
        Clients: {nb_clients}  |  Voitures: {nb_voitures}  |  Locations: {nb_locations}  |  Note moyenne: {note_moy:.2f}/5  |  Km total: {km_total:,} km
        """
        
        ax_stats.text(0.5, 0.5, stats_text, 
                     ha='center', va='center', fontsize=14, weight='bold',
                     bbox=dict(boxstyle='round', facecolor='lightblue', alpha=0.5))
        
        # Zone 2: Top 5 clients (milieu gauche)
        ax_clients = fig.add_subplot(gs[1, 0])
        
        top_clients_query = """
            SELECT c.Nom || ' ' || SUBSTR(c.Prenom, 1, 1) || '.' as client,
                   SUM(l.km) as km
            FROM Client c
            JOIN Location l ON c.CodeC = l.CodeC
            GROUP BY c.Nom, c.Prenom
            ORDER BY km DESC
            FETCH FIRST 5 ROWS ONLY
        """
        df_clients = self.get_dataframe(top_clients_query)
        df_clients.columns = ['Client', 'KM']
        
        ax_clients.barh(df_clients['Client'], df_clients['KM'], color='teal')
        ax_clients.set_title('Top 5 Clients (km)', fontsize=12, weight='bold')
        ax_clients.invert_yaxis()
        
        # Zone 3: Catégories (milieu centre)
        ax_cat = fig.add_subplot(gs[1, 1])
        
        cat_query = "SELECT Categorie, COUNT(*) FROM Voiture GROUP BY Categorie"
        df_cat = self.get_dataframe(cat_query)
        df_cat.columns = ['Categorie', 'Nombre']
        
        ax_cat.pie(df_cat['Nombre'], labels=df_cat['Categorie'], autopct='%1.0f%%')
        ax_cat.set_title('Répartition Catégories', fontsize=12, weight='bold')
        
        # Zone 4: Notes (milieu droite)
        ax_notes = fig.add_subplot(gs[1, 2])
        
        notes_query = "SELECT note, COUNT(*) FROM Location WHERE note IS NOT NULL GROUP BY note ORDER BY note"
        df_notes = self.get_dataframe(notes_query)
        df_notes.columns = ['Note', 'Nombre']
        
        ax_notes.bar(df_notes['Note'], df_notes['Nombre'], 
                    color=sns.color_palette('RdYlGn', len(df_notes)))
        ax_notes.set_title('Distribution Notes', fontsize=12, weight='bold')
        ax_notes.set_xlabel('Note')
        ax_notes.set_ylabel('Nombre')
        
        # Zone 5: Évolution (bas, sur toute la largeur)
        ax_evol = fig.add_subplot(gs[2, :])
        
        evol_query = """
            SELECT Annee, Mois, COUNT(*) as nb
            FROM Location
            GROUP BY Annee, Mois
            ORDER BY Annee, Mois
        """
        df_evol = self.get_dataframe(evol_query)
        df_evol.columns = ['Annee', 'Mois', 'Nb']
        df_evol['Periode'] = df_evol['Annee'].astype(str) + '-' + df_evol['Mois'].astype(str).str.zfill(2)
        
        ax_evol.plot(range(len(df_evol)), df_evol['Nb'], marker='o', linewidth=2)
        ax_evol.fill_between(range(len(df_evol)), df_evol['Nb'], alpha=0.3)
        ax_evol.set_title('Évolution des Locations', fontsize=12, weight='bold')
        ax_evol.set_xlabel('Période')
        ax_evol.set_ylabel('Nombre')
        ax_evol.set_xticks(range(0, len(df_evol), max(1, len(df_evol)//10)))
        ax_evol.set_xticklabels(df_evol['Periode'].iloc[::max(1, len(df_evol)//10)], rotation=45)
        ax_evol.grid(True, alpha=0.3)
        
        filepath = f"{OUTPUT_DIR}/BONUS_dashboard.png"
        plt.savefig(filepath, dpi=300, bbox_inches='tight')
        print(f"✅ Sauvegardé: {filepath}")
        plt.close()
    
    def generer_toutes_visualisations(self):
        """Générer toutes les visualisations"""
        print("="*80)
        print("GÉNÉRATION DES VISUALISATIONS")
        print("="*80)
        
        try:
            self.viz1_categories_voitures()
            self.viz2_top_clients_km()
            self.viz3_evolution_locations()
            self.viz4_satisfaction_notes()
            self.viz5_analyse_multicriteres()
            self.viz_bonus_dashboard()
            
            print("\n" + "="*80)
            print(f"✅ TOUTES LES VISUALISATIONS GÉNÉRÉES DANS '{OUTPUT_DIR}/'")
            print("="*80)
            print("\nFichiers créés:")
            for i in range(1, 6):
                print(f"  • 0{i}_*.png")
            print(f"  • BONUS_dashboard.png")
            
        finally:
            self.disconnect()


if __name__ == "__main__":
    viz = DataVisualizer()
    viz.generer_toutes_visualisations()
