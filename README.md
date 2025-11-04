# 🚗 BDA 2025 - Système de Gestion de Location de Voitures

Projet complet de base de données Oracle pour la gestion d'une agence de location de voitures, développé dans le cadre du cours BDA 2025.

---

## 🎯 Pourquoi Oracle Free 23c (Docker) au lieu de Oracle XE + SQL Developer ?

### Choix technique justifié

**Oracle Database Free 23c via Docker** plutôt que l'installation classique Oracle XE + SQL Developer pour plusieurs raisons :

1. **Compatibilité macOS** 
   - Oracle XE n'existe pas nativement pour macOS (surtout Apple Silicon M1/M2/M3)
   - Docker permet d'utiliser Oracle sur n'importe quelle plateforme (macOS, Linux, Windows)
   - Pas besoin de VM ou d'environnements complexes

2. **Installation simplifiée**
   - Une seule commande `docker run` au lieu d'un installeur lourd
   - Environnement reproductible et portable
   - Suppression facile (`docker rm`) sans pollution du système

3. **Version moderne**
   - Oracle Free 23c (dernière version gratuite) vs Oracle XE 21c (plus ancienne)
   - Fonctionnalités SQL et PL/SQL plus récentes
   - Meilleures performances

4. **Gestion des ressources**
   - Isolation complète dans un conteneur
   - Contrôle facile de la mémoire/CPU (`--shm-size`, limites Docker)
   - Pas d'impact sur les services système

5. **Interface moderne**
   - Python avec `oracledb` (mode thin) au lieu de SQL Developer lourd
   - Scripts SQL automatisés via terminal
   - Menus interactifs Python pour une UX moderne

**Résultat :** Installation en ~5 minutes vs plusieurs heures pour Oracle XE classique, tout en gardant 100% des fonctionnalités Oracle.

---

## 📋 Description du Projet

Système complet de gestion d'agence de location incluant :

- **Gestion des entités** : Clients, Propriétaires, Voitures, Locations
- **Contraintes d'intégrité** : CHECK, FK, UNIQUE, validation métier
- **Vues SQL** : Agrégations, filtres, WITH CHECK OPTION
- **Procédures PL/SQL** : Notation automatique, analyse clients, packages
- **Triggers** : Audit, validation, historique des changements
- **Gestion des accès** : Authentification MD5, rôles Oracle
- **Concurrence** : Gestion des verrous et transactions
- **Application Python** : CRUD complet, menu interactif, visualisations
- **Tests** : Suite complète de validation

---

## 🛠️ Technologies

| Composant | Technologie | Version |
|-----------|-------------|---------|
| Base de données | Oracle Database Free | 23c (23.9.0.25.7) |
| Conteneurisation | Docker | gvenzl/oracle-free:23-slim |
| Backend | Python | 3.9+ |
| Driver Oracle | oracledb | Mode Thin (pas d'Instant Client) |
| Visualisation | matplotlib, seaborn, pandas | Dernières versions |
| Environnement | macOS | Apple Silicon / Intel |

---

## ⚡ Installation Rapide

### Prérequis
- Docker Desktop installé et lancé
- Python 3.9+
- Git

### Installation automatique

```bash
# Cloner le projet
git clone git@github.com:Rqbln/BDD-Loc-Voiture.git
cd BDD-Loc-Voiture

# Tout installer en une commande
chmod +x install.sh
./install.sh
```

Le script `install.sh` effectue automatiquement :
1. ✅ Vérification des prérequis (Docker, Python)
2. ✅ Création de l'environnement virtuel Python
3. ✅ Installation des dépendances (`oracledb`, `pandas`, `matplotlib`, etc.)
4. ✅ Lancement d'Oracle Free 23c dans Docker
5. ✅ Création du schéma de base de données (5 tables)
6. ✅ Importation des données CSV (185 enregistrements)
7. ✅ Exécution de tous les scripts SQL (contraintes, vues, PL/SQL, triggers)

**Durée totale :** ~3-5 minutes

---

## 📁 Structure du Projet

```
BDD-Loc-Voiture/
├── sql/                        # Scripts SQL (exécutés dans l'ordre)
│   ├── 01_schema.sql           # Création tables (Proprietaire, Client, Voiture, Location, Audit)
│   ├── 02_constraints.sql      # Contraintes CHECK + génération dates aléatoires
│   ├── 03_views.sql            # Vues V_Client et V_Client55
│   ├── 04_access.sql           # Table ACESS + hash MD5 + rôles Oracle
│   ├── 05_plsql.sql            # Procédures (noter_location, maj_avis, synthese_client, pkg_location)
│   ├── 06_triggers.sql         # Triggers (audit prix, validation, historique état)
│   ├── 07_concurrency.sql      # Démo gestion concurrence (SELECT FOR UPDATE)
│   └── 99_demo.sql             # Démonstration complète avec stats
│
├── app/                        # Application Python
│   ├── config.py               # Configuration connexion Oracle
│   ├── database.py             # Classe Database pour connexion
│   ├── import_data.py          # Import CSV → Oracle
│   ├── crud_operations.py      # Classes CRUD (Create/Read/Update/Delete)
│   ├── menu_interactive.py     # Interface CLI interactive complète
│   ├── visualizations.py       # 5 graphiques + dashboard
│   └── tests.py                # Suite de 16 tests automatisés
│
├── data/                       # Données sources (CSV)
│   ├── proprietaire.csv        # 13 propriétaires
│   ├── client.csv              # 19 clients
│   ├── voiture.csv             # 20 voitures
│   └── location.csv            # 133 locations
│
├── visualizations/             # Graphiques générés (PNG)
│   ├── 01_categories_voitures.png
│   ├── 02_top_clients_km.png
│   ├── 03_evolution_locations.png
│   ├── 04_analyse_multicriteres.png
│   └── BONUS_dashboard.png
│
├── install.sh                  # Script installation automatique
└── README.md                   # Ce fichier
```

---

## 🚀 Utilisation

### 1️⃣ Menu Interactif Python (Recommandé)

Interface complète pour gérer toute la base :

```bash
source venv/bin/activate
python app/menu_interactive.py
```

**Fonctionnalités :**
- Gestion Clients : Lister, rechercher, créer, modifier, supprimer
- Gestion Voitures : CRUD complet, filtrage disponibilité, changement état
- Gestion Locations : Historique, recherche par client/voiture, création
- Statistiques : Vue d'ensemble, top clients, voitures rentables

### 2️⃣ Opérations CRUD en Python

Démo automatique des opérations CRUD :

```bash
source venv/bin/activate
python app/crud_operations.py
```

### 3️⃣ Générer les Visualisations

Créer 5 graphiques d'analyse :

```bash
source venv/bin/activate
python app/visualizations.py
```

**Graphiques générés :**
1. Distribution des catégories de voitures (camembert)
2. Top 10 clients par kilométrage (barres)
3. Évolution des locations par mois (courbe)
4. Analyse catégories vs popularité (multi-critères)
5. Dashboard récapitulatif complet (BONUS)


### SQL*Plus (Mode Avancé)

Connexion directe à Oracle :

```bash
# Se connecter
docker exec -it oracle-xe sqlplus BDA2025/BDA2025Password@FREEPDB1

# Exécuter un script SQL
docker exec -i oracle-xe sqlplus -s BDA2025/BDA2025Password@FREEPDB1 < sql/99_demo.sql
```

---

## 🔐 Informations de Connexion

| Paramètre | Valeur |
|-----------|--------|
| **Hôte** | localhost |
| **Port** | 1521 |
| **Service** | FREEPDB1 |
| **Utilisateur** | BDA2025 |
| **Mot de passe** | BDA2025Password |
| **Chaîne connexion** | `BDA2025/BDA2025Password@localhost:1521/FREEPDB1` |

---

## 📊 Contenu de la Base de Données

### Tables Principales

| Table | Enregistrements | Description |
|-------|-----------------|-------------|
| **Proprietaire** | 13 | Propriétaires de véhicules |
| **Client** | 19 | Clients locataires |
| **Voiture** | 20 | Parc automobile (7 catégories) |
| **Location** | 133 | Historique des locations |
| **Voiture_Etat_Histo** | - | Historique changements d'état |
| **Voiture_Prix_Audit** | - | Audit modifications de prix |
| **ACESS** | 19 | Authentification (MD5) |

### Procédures et Fonctions PL/SQL

- `noter_location()` : Calcule et attribue des notes selon km et durée
- `maj_avis()` : Génère des avis textuels selon la note
- `synthese_client(p_codeC)` : Analyse complète d'un client
- `get_client_status(p_codeC)` : Retourne le statut du client
- `calculer_ca_location()` : Calcule le CA d'une location
- **Package** `pkg_location` : Fonctions avancées de gestion

### Triggers Actifs

- `trg_voiture_etat_hist` : Historique états voiture
- `trg_location_verification` : Validation avant location
- `trg_location_update_etat` : MAJ état en location
- `trg_location_update_compteur` : MAJ compteur kilométrique
- `trg_voiture_prix_audit` : Audit changements prix
- `trg_location_dates` : Validation cohérence dates

---

## 🛠️ Commandes Utiles

### Gestion Docker

```bash
# Voir les logs Oracle
docker logs oracle-xe

# Redémarrer Oracle
docker restart oracle-xe

# Arrêter/Démarrer
docker stop oracle-xe
docker start oracle-xe

# Supprimer complètement (⚠️ perte données)
docker rm -f oracle-xe
```

### Import/Export Données

```bash
# Réimporter les CSV
source venv/bin/activate
python app/import_data.py

# Exporter le schéma (backup)
docker exec oracle-xe expdp BDA2025/BDA2025Password@FREEPDB1 \
  schemas=BDA2025 directory=DATA_PUMP_DIR dumpfile=backup_$(date +%Y%m%d).dmp
```

### Requêtes SQL Rapides

```sql
-- Statistiques générales
SELECT 
    (SELECT COUNT(*) FROM Client) as clients,
    (SELECT COUNT(*) FROM Voiture) as voitures,
    (SELECT COUNT(*) FROM Location) as locations,
    (SELECT AVG(note) FROM Location WHERE note IS NOT NULL) as note_moyenne
FROM DUAL;

-- Top 5 clients par km
SELECT c.Nom, c.Prenom, SUM(l.km) as km_total
FROM Client c JOIN Location l ON c.CodeC = l.CodeC
GROUP BY c.Nom, c.Prenom
ORDER BY km_total DESC
FETCH FIRST 5 ROWS ONLY;

-- Voitures disponibles
SELECT Marque, Modele, prixJ, etat
FROM Voiture
WHERE etat = 'disponible'
ORDER BY prixJ;
```

---

## 🐛 Dépannage

### Problème : Oracle ne démarre pas

```bash
# Vérifier les logs
docker logs oracle-xe

# Solution : Augmenter la mémoire partagée
docker rm -f oracle-xe
docker run -d --name oracle-xe \
  -p 1521:1521 \
  --shm-size=2g \
  -e ORACLE_PASSWORD=OraclePassword123 \
  -e APP_USER=BDA2025 \
  -e APP_USER_PASSWORD=BDA2025Password \
  gvenzl/oracle-free:23-slim
```

### Problème : Erreur de connexion Python

```bash
# Vérifier la config
cat app/config.py

# Tester la connexion
source venv/bin/activate
python -c "import oracledb; conn = oracledb.connect(user='BDA2025', password='BDA2025Password', dsn='localhost:1521/FREEPDB1'); print('✓ Connexion OK, version:', conn.version)"
```

### Problème : Import CSV échoue

```bash
# Vérifier les fichiers CSV
head -3 data/*.csv

# Relancer l'import
source venv/bin/activate
python app/import_data.py
```

---

## 📈 Évolutions Futures Possibles

- [ ] Interface web (Flask/Django)
- [ ] API REST pour intégration externe
- [ ] Système de réservation en temps réel
- [ ] Notifications par email
- [ ] Rapports PDF automatiques
- [ ] Dashboard temps réel (Dash/Streamlit)
- [ ] Machine Learning (prédiction de prix, recommandations)

---

## 👨‍💻 Auteur

**Robin Quériaux**
- GitHub: [@Rqbln](https://github.com/Rqbln)
- Projet: BDA 2025 - Gestion de Location de Voitures

---

## 📄 Licence

Projet académique - BDA 2025
