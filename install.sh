#!/bin/bash

###############################################################################
# Script d'installation BDA 2025 - Projet Oracle sur macOS
# Ce script configure automatiquement l'environnement complet
###############################################################################

set -e  # Arrêter en cas d'erreur

echo "=================================================="
echo "🚀 Installation BDA 2025 - Projet Oracle"
echo "=================================================="
echo ""

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Vérifier les prérequis
info "Vérification des prérequis..."

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    error "Docker n'est pas installé!"
    echo "Veuillez installer Docker Desktop depuis: https://www.docker.com/products/docker-desktop/"
    exit 1
fi
info "✓ Docker est installé ($(docker --version))"

# Vérifier Python
if ! command -v python3 &> /dev/null; then
    error "Python 3 n'est pas installé!"
    echo "Installez Python depuis: https://www.python.org/downloads/"
    exit 1
fi
info "✓ Python est installé ($(python3 --version))"

# Vérifier l'architecture
ARCH=$(uname -m)
info "Architecture détectée: $ARCH"

# 2. Démarrer Oracle Database avec Docker
echo ""
info "=================================================="
info "Étape 1: Configuration d'Oracle Database"
info "=================================================="

# Vérifier si le conteneur existe déjà
if docker ps -a --format '{{.Names}}' | grep -q '^oracle-xe$'; then
    warn "Le conteneur oracle-xe existe déjà"
    read -p "Voulez-vous le supprimer et recommencer? (o/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        info "Suppression du conteneur existant..."
        docker rm -f oracle-xe || true
        docker volume rm oracle-data || true
    else
        info "Utilisation du conteneur existant"
        docker start oracle-xe || true
    fi
else
    # Utiliser Oracle Free (fonctionne sur Intel et Apple Silicon)
    info "Démarrage d'Oracle Database Free 23c..."
    docker run -d \
        --name oracle-xe \
        -p 1521:1521 \
        -e ORACLE_PASSWORD=Oracle123 \
        -e APP_USER=BDA2025 \
        -e APP_USER_PASSWORD=BDA2025Password \
        --shm-size=2g \
        -v oracle-data:/opt/oracle/oradata \
        gvenzl/oracle-free:23-slim
fi

# Attendre que la base soit prête
info "Attente du démarrage d'Oracle (cela peut prendre 3-5 minutes la première fois)..."
echo "Vous pouvez suivre les logs dans un autre terminal avec: docker logs -f oracle-xe"
echo ""

# Boucle d'attente avec meilleure détection
MAX_WAIT=300  # 5 minutes
WAITED=0
READY=0

while [ $WAITED -lt $MAX_WAIT ]; do
    # Vérifier plusieurs patterns de succès
    LOGS=$(docker logs oracle-xe 2>&1)
    
    if echo "$LOGS" | grep -q "DATABASE IS READY TO USE"; then
        READY=1
        break
    elif echo "$LOGS" | grep -q "Completed: ALTER DATABASE OPEN"; then
        READY=1
        break
    elif echo "$LOGS" | grep -q "CONTAINER: Database up and running"; then
        READY=1
        break
    fi
    
    # Vérifier si Oracle a crashé
    if echo "$LOGS" | grep -q "ORA-03113" && [ $WAITED -gt 60 ]; then
        error "Oracle a crashé avec ORA-03113"
        warn "Ce problème peut être résolu en augmentant la mémoire Docker"
        warn "Ou en utilisant une autre image Oracle"
        echo ""
        echo "Solutions:"
        echo "1. Augmenter la RAM Docker (Préférences > Resources > Memory à 4GB+)"
        echo "2. Essayer avec une image différente"
        echo ""
        read -p "Voulez-vous réessayer avec l'image gvenzl/oracle-free:23-slim? (o/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Oo]$ ]]; then
            docker rm -f oracle-xe
            docker volume rm oracle-data
            docker run -d \
                --name oracle-xe \
                -p 1521:1521 \
                -e ORACLE_PASSWORD=Oracle123 \
                -e APP_USER=BDA2025 \
                -e APP_USER_PASSWORD=BDA2025Password \
                --shm-size=2g \
                -v oracle-data:/opt/oracle/oradata \
                gvenzl/oracle-free:23-slim
            WAITED=0
            continue
        else
            exit 1
        fi
    fi
    
    echo -n "."
    sleep 5
    WAITED=$((WAITED + 5))
    
    # Afficher un message toutes les 30 secondes
    if [ $((WAITED % 30)) -eq 0 ]; then
        echo " ($WAITED secondes écoulées)"
    fi
done

if [ $READY -eq 0 ]; then
    error "Timeout: Oracle n'a pas démarré dans les temps"
    echo ""
    echo "Dernières lignes des logs:"
    docker logs oracle-xe 2>&1 | tail -20
    echo ""
    echo "Pour voir tous les logs: docker logs oracle-xe"
    exit 1
fi

info "✓ Oracle Database est prêt!"

# 3. Créer l'utilisateur et le schéma BDA2025
echo ""
info "=================================================="
info "Étape 2: Création de l'utilisateur BDA2025"
info "=================================================="

# Attendre encore un peu pour être sûr
sleep 5

# Créer l'utilisateur (BDA2025 est déjà créé par APP_USER)
info "Vérification de l'utilisateur BDA2025..."
docker exec oracle-xe sqlplus -s BDA2025/BDA2025Password@FREEPDB1 <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT 'Utilisateur ' || USER || ' connecté à ' || SYS_CONTEXT('USERENV','DB_NAME') FROM DUAL;
EXIT;
EOF

info "✓ Utilisateur BDA2025 prêt!"

# Configuration Python
echo ""
info "=================================================="
info "Étape 3: Configuration de l'environnement Python"
info "=================================================="

# Créer l'environnement virtuel
if [ ! -d "venv" ]; then
    info "Création de l'environnement virtuel Python..."
    python3 -m venv venv
    info "✓ Environnement virtuel créé"
else
    info "✓ Environnement virtuel existe déjà"
fi

# Activer et installer les dépendances
info "Installation des dépendances Python..."
source venv/bin/activate
pip install --upgrade pip -q
pip install -q oracledb pandas matplotlib seaborn plotly fastapi uvicorn sqlalchemy

info "✓ Dépendances Python installées"

# 5. Déplacer les CSV dans le dossier data
echo ""
info "=================================================="
info "Étape 4: Organisation des fichiers CSV"
info "=================================================="

# Déplacer les CSV s'ils sont à la racine
for file in client.csv proprietaire.csv voiture.csv location.csv; do
    if [ -f "$file" ] && [ ! -f "data/$file" ]; then
        info "Déplacement de $file vers data/"
        mv "$file" "data/"
    fi
done

# 6. Résumé
echo ""
info "=================================================="
info "✅ Installation terminée avec succès!"
info "=================================================="
echo ""
echo "📋 Paramètres de connexion Oracle:"
echo "   Host:     localhost"
echo "   Port:     1521"
echo "   Service:  FREEPDB1"
echo "   User:     BDA2025"
echo "   Password: BDA2025Password"
echo ""
echo "🐍 Environnement Python:"
echo "   Pour activer: source venv/bin/activate"
echo ""
echo "🚀 Prochaines étapes:"
echo "   1. Activer l'environnement Python: source venv/bin/activate"
echo "   2. Créer les tables: docker exec -it oracle-xe sqlplus BDA2025/BDA2025Password@FREEPDB1 @sql/01_schema.sql"
echo "   3. Importer les données: python app/import_data.py"
echo "   4. Exécuter les autres scripts SQL dans l'ordre"
echo ""
echo "📚 Pour plus d'informations, consultez le README.md"
echo ""

# Sauvegarder les informations de connexion
cat > .env <<EOF
# Configuration Oracle Database
ORACLE_USER=BDA2025
ORACLE_PASSWORD=BDA2025Password
ORACLE_DSN=localhost:1521/FREEPDB1
ORACLE_HOST=localhost
ORACLE_PORT=1521
ORACLE_SERVICE=FREEPDB1
EOF

info "✓ Fichier .env créé avec les paramètres de connexion"

echo ""
info "Installation complète! Bon travail! 🎉"
