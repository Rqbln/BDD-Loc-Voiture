#!/bin/bash

###############################################################################
# Script d'exécution automatique de tous les scripts SQL
# BDA 2025 - Projet Oracle
###############################################################################

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

echo "============================================================"
echo "🚀 Exécution automatique des scripts SQL BDA 2025"
echo "============================================================"
echo ""

# Vérifier que Oracle est démarré
if ! docker ps | grep -q oracle-xe; then
    error "Le conteneur oracle-xe n'est pas démarré"
    echo "Exécutez: docker start oracle-xe"
    exit 1
fi

info "✓ Conteneur Oracle détecté"

# Liste des scripts à exécuter
SCRIPTS=(
    "01_schema.sql"
    "02_constraints.sql"
    "03_views.sql"
    "04_access.sql"
    "05_plsql.sql"
    "06_triggers.sql"
    "07_concurrency.sql"
    "99_demo.sql"
)

SCRIPT_DIR="sql"
TOTAL=${#SCRIPTS[@]}
CURRENT=0

echo ""
info "Nombre de scripts à exécuter: $TOTAL"
echo ""

# Fonction pour exécuter un script SQL
execute_sql() {
    local script=$1
    CURRENT=$((CURRENT + 1))
    
    step "[$CURRENT/$TOTAL] Exécution de $script..."
    
    # Créer un fichier temporaire avec les commandes
    cat > /tmp/run_script.sql <<EOF
SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
WHENEVER SQLERROR CONTINUE

PROMPT ============================================================
PROMPT Exécution de $script
PROMPT ============================================================

@$SCRIPT_DIR/$script

PROMPT
PROMPT ✅ $script terminé
PROMPT

EXIT;
EOF

    # Exécuter via Docker
    if docker exec -i oracle-xe sqlplus -S BDA2025/BDA2025Password@XEPDB1 < /tmp/run_script.sql > /tmp/sql_output.log 2>&1; then
        info "✓ $script exécuté avec succès"
        
        # Afficher les erreurs éventuelles
        if grep -q "ORA-" /tmp/sql_output.log; then
            warn "Avertissements détectés dans $script"
            grep "ORA-" /tmp/sql_output.log | head -5
        fi
    else
        error "Échec de l'exécution de $script"
        cat /tmp/sql_output.log
        return 1
    fi
    
    echo ""
}

# Demander confirmation
echo "Les scripts suivants seront exécutés dans l'ordre:"
for script in "${SCRIPTS[@]}"; do
    echo "  - $script"
done
echo ""

read -p "Continuer? (o/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    info "Annulé par l'utilisateur"
    exit 0
fi

echo ""
info "Début de l'exécution..."
echo ""

# Exécuter chaque script
for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        error "Script introuvable: $SCRIPT_DIR/$script"
        exit 1
    fi
    
    execute_sql "$script" || {
        error "Arrêt à cause d'une erreur dans $script"
        exit 1
    }
    
    # Petite pause entre les scripts
    sleep 1
done

# Nettoyer
rm -f /tmp/run_script.sql /tmp/sql_output.log

# Résumé final
echo ""
echo "============================================================"
info "✅ Tous les scripts ont été exécutés avec succès!"
echo "============================================================"
echo ""

# Afficher quelques statistiques
info "Statistiques de la base de données:"
docker exec oracle-xe sqlplus -S BDA2025/BDA2025Password@XEPDB1 <<EOF
SET PAGESIZE 100
SET LINESIZE 150

SELECT 'PROPRIETAIRE' AS table_name, COUNT(*) AS nb_lignes FROM Proprietaire
UNION ALL
SELECT 'CLIENT', COUNT(*) FROM Client
UNION ALL
SELECT 'VOITURE', COUNT(*) FROM Voiture
UNION ALL
SELECT 'LOCATION', COUNT(*) FROM Location
ORDER BY table_name;

EXIT;
EOF

echo ""
info "Pour voir une démonstration complète, connectez-vous:"
echo "  docker exec -it oracle-xe sqlplus BDA2025/BDA2025Password@XEPDB1"
echo ""
info "Ou relancez uniquement la démo:"
echo "  docker exec -it oracle-xe sqlplus BDA2025/BDA2025Password@XEPDB1 @sql/99_demo.sql"
echo ""
