-- ============================================================================
-- Script 05: Procédures et fonctions PL/SQL (Partie 5.1-5.3)
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Procédures d'analyse et de notation des locations
-- Ordre d'exécution: 5ème script
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED

PROMPT ============================================================
PROMPT Partie 5.1: Procédure de notation automatique
PROMPT ============================================================

CREATE OR REPLACE PROCEDURE noter_location(p_codeC NUMBER DEFAULT NULL) AS
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Début de la notation des locations...');
    
    -- Si p_codeC est fourni, on ne traite que ce client
    -- Sinon, on traite tous les clients
    FOR r IN (
        SELECT * 
        FROM Location 
        WHERE p_codeC IS NULL OR codeC = p_codeC
        ORDER BY codeC, annee, mois
    ) LOOP
        -- Règles de notation:
        -- - NULL si km NULL ou duree NULL ou duree = 1
        -- - 5 si km > 1000 ET duree > 50
        -- - 4 si duree >= 14
        -- - 3 sinon
        
        IF r.km IS NULL OR r.duree IS NULL OR r.duree = 1 THEN
            -- Laisser la note à NULL
            UPDATE Location 
            SET note = NULL
            WHERE codeC = r.codeC 
              AND immat = r.immat
              AND annee = r.annee 
              AND mois = r.mois 
              AND numLoc = r.numLoc;
              
        ELSIF r.km > 1000 AND r.duree > 50 THEN
            -- Excellente location
            UPDATE Location 
            SET note = 5
            WHERE codeC = r.codeC 
              AND immat = r.immat
              AND annee = r.annee 
              AND mois = r.mois 
              AND numLoc = r.numLoc;
            v_count := v_count + 1;
            
        ELSIF r.duree >= 14 THEN
            -- Bonne location
            UPDATE Location 
            SET note = 4
            WHERE codeC = r.codeC 
              AND immat = r.immat
              AND annee = r.annee 
              AND mois = r.mois 
              AND numLoc = r.numLoc;
            v_count := v_count + 1;
            
        ELSE
            -- Location standard
            UPDATE Location 
            SET note = 3
            WHERE codeC = r.codeC 
              AND immat = r.immat
              AND annee = r.annee 
              AND mois = r.mois 
              AND numLoc = r.numLoc;
            v_count := v_count + 1;
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Notation terminée: ' || v_count || ' locations notées');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Erreur: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END noter_location;
/

PROMPT ✓ Procédure noter_location créée

PROMPT ============================================================
PROMPT Partie 5.2: Procédure de mise à jour des avis
PROMPT ============================================================

CREATE OR REPLACE PROCEDURE maj_avis AS
    v_count NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Mise à jour des avis...');
    
    UPDATE Location
    SET avis = CASE
                 WHEN note IS NULL THEN 'non évalué'
                 WHEN note >= 4    THEN 'très satisfait'
                 WHEN note = 3     THEN 'satisfait'
                 ELSE 'mécontent'
               END;
    
    v_count := SQL%ROWCOUNT;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ ' || v_count || ' avis mis à jour');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Erreur: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END maj_avis;
/

PROMPT ✓ Procédure maj_avis créée

PROMPT ============================================================
PROMPT Partie 5.3: Procédure d'analyse par client
PROMPT ============================================================

CREATE OR REPLACE PROCEDURE synthese_client(
    p_codeC IN NUMBER,
    p_duree OUT NUMBER,
    p_nbveh OUT NUMBER,
    p_moy OUT NUMBER
) AS
BEGIN
    SELECT 
        NVL(SUM(duree), 0),
        COUNT(DISTINCT immat),
        ROUND(AVG(note), 2)
    INTO p_duree, p_nbveh, p_moy
    FROM Location
    WHERE codeC = p_codeC;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_duree := 0;
        p_nbveh := 0;
        p_moy := NULL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Erreur: ' || SQLERRM);
        RAISE;
END synthese_client;
/

PROMPT ✓ Procédure synthese_client créée

PROMPT ============================================================
PROMPT Fonction utilitaire: Obtenir le statut d'un client
PROMPT ============================================================

CREATE OR REPLACE FUNCTION get_client_status(p_codeC NUMBER)
RETURN VARCHAR2
AS
    v_nb_locations NUMBER;
    v_note_moyenne NUMBER;
BEGIN
    SELECT COUNT(*), AVG(note)
    INTO v_nb_locations, v_note_moyenne
    FROM Location
    WHERE codeC = p_codeC;
    
    IF v_nb_locations = 0 THEN
        RETURN 'Nouveau client';
    ELSIF v_nb_locations >= 10 AND v_note_moyenne >= 4 THEN
        RETURN 'Client VIP';
    ELSIF v_nb_locations >= 5 THEN
        RETURN 'Client régulier';
    ELSE
        RETURN 'Client occasionnel';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Erreur';
END get_client_status;
/

PROMPT ✓ Fonction get_client_status créée

PROMPT ============================================================
PROMPT Fonction: Calculer le CA généré par une location
PROMPT ============================================================

CREATE OR REPLACE FUNCTION calculer_ca_location(
    p_immat VARCHAR2,
    p_duree NUMBER
) RETURN NUMBER
AS
    v_prix_jour NUMBER;
    v_ca NUMBER;
BEGIN
    SELECT prixJ INTO v_prix_jour
    FROM Voiture
    WHERE immat = p_immat;
    
    v_ca := v_prix_jour * NVL(p_duree, 0);
    RETURN v_ca;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        RETURN 0;
END calculer_ca_location;
/

PROMPT ✓ Fonction calculer_ca_location créée

PROMPT ============================================================
PROMPT Package: Gestion avancée des locations
PROMPT ============================================================

CREATE OR REPLACE PACKAGE pkg_location AS
    -- Obtenir le top N des clients par distance
    PROCEDURE top_clients_distance(p_limit NUMBER DEFAULT 10);
    
    -- Obtenir les locations en cours (date fin future ou NULL)
    PROCEDURE locations_en_cours;
    
    -- Calculer le CA total d'une période
    FUNCTION ca_periode(p_annee NUMBER, p_mois NUMBER DEFAULT NULL) RETURN NUMBER;
    
    -- Vérifier la disponibilité d'une voiture
    FUNCTION voiture_disponible(p_immat VARCHAR2, p_date DATE) RETURN BOOLEAN;
    
END pkg_location;
/

CREATE OR REPLACE PACKAGE BODY pkg_location AS

    PROCEDURE top_clients_distance(p_limit NUMBER DEFAULT 10) AS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== Top ' || p_limit || ' clients par distance ===');
        DBMS_OUTPUT.PUT_LINE('');
        
        FOR r IN (
            SELECT c.codeC, c.nom, c.prenom, NVL(SUM(l.km), 0) AS total_km
            FROM Client c
            LEFT JOIN Location l ON l.codeC = c.codeC
            GROUP BY c.codeC, c.nom, c.prenom
            ORDER BY total_km DESC
            FETCH FIRST p_limit ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.nom || ' ' || r.prenom, 30) || ' : ' || 
                LPAD(TO_CHAR(r.total_km, '999,999'), 10) || ' km'
            );
        END LOOP;
    END top_clients_distance;
    
    PROCEDURE locations_en_cours AS
        v_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== Locations en cours ===');
        DBMS_OUTPUT.PUT_LINE('');
        
        FOR r IN (
            SELECT l.*, c.nom, c.prenom, v.marque, v.modele
            FROM Location l
            JOIN Client c ON c.codeC = l.codeC
            JOIN Voiture v ON v.immat = l.immat
            WHERE l.datef IS NULL OR l.datef >= SYSDATE
            ORDER BY l.dated DESC
        ) LOOP
            DBMS_OUTPUT.PUT_LINE(
                r.nom || ' ' || r.prenom || ' - ' ||
                r.marque || ' ' || r.modele || ' (' || r.immat || ')' ||
                ' - Depuis le ' || TO_CHAR(r.dated, 'DD/MM/YYYY')
            );
            v_count := v_count + 1;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Total: ' || v_count || ' location(s) en cours');
    END locations_en_cours;
    
    FUNCTION ca_periode(p_annee NUMBER, p_mois NUMBER DEFAULT NULL) 
    RETURN NUMBER AS
        v_ca NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(v.prixJ * l.duree), 0)
        INTO v_ca
        FROM Location l
        JOIN Voiture v ON v.immat = l.immat
        WHERE l.annee = p_annee
          AND (p_mois IS NULL OR l.mois = p_mois)
          AND l.duree IS NOT NULL;
        
        RETURN v_ca;
    END ca_periode;
    
    FUNCTION voiture_disponible(p_immat VARCHAR2, p_date DATE)
    RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM Location
        WHERE immat = p_immat
          AND p_date BETWEEN dated AND NVL(datef, dated + duree);
        
        RETURN (v_count = 0);
    END voiture_disponible;
    
END pkg_location;
/

PROMPT ✓ Package pkg_location créé

PROMPT ============================================================
PROMPT Test des procédures et fonctions
PROMPT ============================================================

PROMPT Test 1: Exécution de noter_location()
BEGIN
    noter_location();
END;
/

PROMPT Test 2: Exécution de maj_avis()
BEGIN
    maj_avis();
END;
/

PROMPT Test 3: Synthèse pour le premier client
DECLARE
    v_codeC NUMBER;
    v_duree NUMBER;
    v_nbveh NUMBER;
    v_moy NUMBER;
    v_nom VARCHAR2(50);
    v_prenom VARCHAR2(50);
BEGIN
    -- Récupérer le premier client
    SELECT codeC, nom, prenom INTO v_codeC, v_nom, v_prenom
    FROM Client WHERE ROWNUM = 1;
    
    -- Appeler la procédure
    synthese_client(v_codeC, v_duree, v_nbveh, v_moy);
    
    -- Afficher les résultats
    DBMS_OUTPUT.PUT_LINE('=== Synthèse pour ' || v_nom || ' ' || v_prenom || ' ===');
    DBMS_OUTPUT.PUT_LINE('Durée totale de location: ' || v_duree || ' jours');
    DBMS_OUTPUT.PUT_LINE('Nombre de véhicules différents: ' || v_nbveh);
    DBMS_OUTPUT.PUT_LINE('Note moyenne: ' || NVL(TO_CHAR(v_moy, '9.99'), 'N/A'));
    DBMS_OUTPUT.PUT_LINE('Statut: ' || get_client_status(v_codeC));
END;
/

PROMPT Test 4: Top 5 clients par distance
BEGIN
    pkg_location.top_clients_distance(5);
END;
/

PROMPT ============================================================
PROMPT Statistiques des notes après traitement
PROMPT ============================================================

SELECT 
    note,
    COUNT(*) AS nombre,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pourcentage
FROM Location
GROUP BY note
ORDER BY note NULLS FIRST;

PROMPT ============================================================
PROMPT Statistiques des avis après traitement
PROMPT ============================================================

SELECT 
    avis,
    COUNT(*) AS nombre,
    ROUND(AVG(note), 2) AS note_moyenne
FROM Location
GROUP BY avis
ORDER BY avis;

PROMPT ============================================================
PROMPT Vérification des objets PL/SQL créés
PROMPT ============================================================

SELECT object_type, object_name, status
FROM user_objects
WHERE object_type IN ('PROCEDURE', 'FUNCTION', 'PACKAGE', 'PACKAGE BODY')
  AND object_name IN ('NOTER_LOCATION', 'MAJ_AVIS', 'SYNTHESE_CLIENT', 
                      'GET_CLIENT_STATUS', 'CALCULER_CA_LOCATION', 'PKG_LOCATION')
ORDER BY object_type, object_name;

-- Vérifier les erreurs de compilation
SELECT name, type, line, position, text
FROM user_errors
WHERE name IN ('NOTER_LOCATION', 'MAJ_AVIS', 'SYNTHESE_CLIENT', 
               'GET_CLIENT_STATUS', 'CALCULER_CA_LOCATION', 'PKG_LOCATION')
ORDER BY name, sequence;

PROMPT ============================================================
PROMPT ✅ Script 05_plsql.sql exécuté avec succès
PROMPT ============================================================
PROMPT 
PROMPT Procédures et fonctions créées:
PROMPT  - noter_location(p_codeC)      : Note les locations selon km et durée
PROMPT  - maj_avis()                   : Met à jour les avis textuels
PROMPT  - synthese_client(p_codeC)     : Analyse des locations d'un client
PROMPT  - get_client_status(p_codeC)   : Retourne le statut du client
PROMPT  - calculer_ca_location()       : Calcule le CA d'une location
PROMPT  - pkg_location                 : Package avec fonctions avancées
PROMPT 
PROMPT Prochaine étape: Exécuter 06_triggers.sql
PROMPT 
