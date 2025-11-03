-- ============================================================================
-- Script 07: Gestion de la concurrence (Partie 4)
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Démonstration des problèmes de concurrence et solutions
-- Ordre d'exécution: 7ème script
-- Note: Certains tests nécessitent 2 sessions SQL*Plus simultanées
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON

PROMPT ============================================================
PROMPT Partie 4: Gestion de la concurrence
PROMPT ============================================================
PROMPT 
PROMPT Ce script présente:
PROMPT  1. Mise à jour perdue (Lost Update)
PROMPT  2. Lecture sale (Dirty Read) / Lecture non répétable
PROMPT  3. Solution avec SELECT FOR UPDATE
PROMPT 
PROMPT Note: Pour les tests réels, ouvrez 2 sessions SQL*Plus
PROMPT       et exécutez les commandes manuellement
PROMPT 

PROMPT ============================================================
PROMPT Partie 4.1: Problème de mise à jour perdue (Lost Update)
PROMPT ============================================================

PROMPT Scénario:
PROMPT  - Session A et Session B lisent le compteur d'une voiture (ex: 50000 km)
PROMPT  - Session A ajoute 100 km → 50100 km
PROMPT  - Session B ajoute 150 km → 50150 km (écrase la mise à jour de A)
PROMPT  - Résultat final: 50150 km au lieu de 50250 km
PROMPT  → 100 km ont été "perdus"
PROMPT 

-- Préparer une voiture de test
CREATE OR REPLACE PROCEDURE demo_lost_update AS
    v_immat VARCHAR2(20);
    v_compteur_initial NUMBER;
    v_compteur_final NUMBER;
BEGIN
    -- Sélectionner une voiture
    SELECT immat, compteur INTO v_immat, v_compteur_initial
    FROM Voiture
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('=== Démonstration de la mise à jour perdue ===');
    DBMS_OUTPUT.PUT_LINE('Voiture: ' || v_immat);
    DBMS_OUTPUT.PUT_LINE('Compteur initial: ' || v_compteur_initial || ' km');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('SANS PROTECTION:');
    DBMS_OUTPUT.PUT_LINE('----------------');
    DBMS_OUTPUT.PUT_LINE('Session A:');
    DBMS_OUTPUT.PUT_LINE('  SELECT compteur FROM Voiture WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  -- Lit: ' || v_compteur_initial);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session B:');
    DBMS_OUTPUT.PUT_LINE('  SELECT compteur FROM Voiture WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  -- Lit: ' || v_compteur_initial);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session A:');
    DBMS_OUTPUT.PUT_LINE('  UPDATE Voiture SET compteur = ' || (v_compteur_initial + 100));
    DBMS_OUTPUT.PUT_LINE('  WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  COMMIT;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session B:');
    DBMS_OUTPUT.PUT_LINE('  UPDATE Voiture SET compteur = ' || (v_compteur_initial + 150));
    DBMS_OUTPUT.PUT_LINE('  WHERE immat = ''' || v_immat || ''';  -- ÉCRASE la mise à jour de A!');
    DBMS_OUTPUT.PUT_LINE('  COMMIT;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Résultat: ' || (v_compteur_initial + 150) || ' au lieu de ' || (v_compteur_initial + 250));
    DBMS_OUTPUT.PUT_LINE('→ 100 km perdus!');
    DBMS_OUTPUT.PUT_LINE('');
    
    DBMS_OUTPUT.PUT_LINE('AVEC PROTECTION (UPDATE en une seule opération):');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Session A:');
    DBMS_OUTPUT.PUT_LINE('  UPDATE Voiture SET compteur = compteur + 100');
    DBMS_OUTPUT.PUT_LINE('  WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  COMMIT;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session B:');
    DBMS_OUTPUT.PUT_LINE('  UPDATE Voiture SET compteur = compteur + 150');
    DBMS_OUTPUT.PUT_LINE('  WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  COMMIT;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Résultat: ' || (v_compteur_initial + 250));
    DBMS_OUTPUT.PUT_LINE('✓ Aucune perte!');
    
END demo_lost_update;
/

EXECUTE demo_lost_update;

PROMPT ============================================================
PROMPT Script pour tester la mise à jour perdue (2 sessions)
PROMPT ============================================================

-- Créer un fichier de test pour Session A
BEGIN
    DECLARE
        v_file UTL_FILE.FILE_TYPE;
    BEGIN
        -- Ce bloc génère juste les instructions à copier-coller
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('=== Instructions pour Session A ===');
        DBMS_OUTPUT.PUT_LINE('1. Ouvrir une nouvelle fenêtre SQL*Plus');
        DBMS_OUTPUT.PUT_LINE('2. Se connecter: sqlplus BDA2025/BDA2025Password@XEPDB1');
        DBMS_OUTPUT.PUT_LINE('3. Exécuter:');
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('   DECLARE');
        DBMS_OUTPUT.PUT_LINE('     v_compteur NUMBER;');
        DBMS_OUTPUT.PUT_LINE('   BEGIN');
        DBMS_OUTPUT.PUT_LINE('     SELECT compteur INTO v_compteur');
        DBMS_OUTPUT.PUT_LINE('     FROM Voiture WHERE ROWNUM = 1;');
        DBMS_OUTPUT.PUT_LINE('     ');
        DBMS_OUTPUT.PUT_LINE('     DBMS_OUTPUT.PUT_LINE(''Compteur lu: '' || v_compteur);');
        DBMS_OUTPUT.PUT_LINE('     DBMS_LOCK.SLEEP(5);  -- Attendre 5 secondes');
        DBMS_OUTPUT.PUT_LINE('     ');
        DBMS_OUTPUT.PUT_LINE('     UPDATE Voiture SET compteur = compteur + 100');
        DBMS_OUTPUT.PUT_LINE('     WHERE ROWNUM = 1;');
        DBMS_OUTPUT.PUT_LINE('     ');
        DBMS_OUTPUT.PUT_LINE('     COMMIT;');
        DBMS_OUTPUT.PUT_LINE('     DBMS_OUTPUT.PUT_LINE(''Session A: +100 km'');');
        DBMS_OUTPUT.PUT_LINE('   END;');
        DBMS_OUTPUT.PUT_LINE('   /');
    END;
END;
/

PROMPT ============================================================
PROMPT Partie 4.2: Lecture sale / Non-repeatable read
PROMPT ============================================================

PROMPT Scénario sous Oracle:
PROMPT Oracle empêche les lectures sales (Dirty Read) grâce au Read Consistency
PROMPT Mais on peut observer une lecture non répétable (Non-Repeatable Read)
PROMPT 

CREATE OR REPLACE PROCEDURE demo_nonrepeatable_read AS
    v_immat VARCHAR2(20);
    v_prix1 NUMBER;
    v_prix2 NUMBER;
BEGIN
    SELECT immat, prixJ INTO v_immat, v_prix1
    FROM Voiture
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('=== Démonstration de la lecture non répétable ===');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session A (Lecture):');
    DBMS_OUTPUT.PUT_LINE('  SELECT prixJ FROM Voiture WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  -- Résultat: ' || v_prix1 || '€');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session B (Modification):');
    DBMS_OUTPUT.PUT_LINE('  UPDATE Voiture SET prixJ = 9999 WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  COMMIT;');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Session A (Re-lecture):');
    DBMS_OUTPUT.PUT_LINE('  SELECT prixJ FROM Voiture WHERE immat = ''' || v_immat || ''';');
    DBMS_OUTPUT.PUT_LINE('  -- Résultat: 9999€  ← Différent!');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Note: Oracle empêche la lecture sale (la session A ne voit pas');
    DBMS_OUTPUT.PUT_LINE('      la valeur non commitée), mais permet la lecture non répétable');
    DBMS_OUTPUT.PUT_LINE('      (la valeur change entre deux lectures si B a commité)');
    
END demo_nonrepeatable_read;
/

EXECUTE demo_nonrepeatable_read;

PROMPT ============================================================
PROMPT Partie 4.3: Solution avec SELECT FOR UPDATE
PROMPT ============================================================

CREATE OR REPLACE PROCEDURE demo_select_for_update AS
    v_immat VARCHAR2(20);
    v_compteur NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== SELECT FOR UPDATE - Verrouillage explicite ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Sélectionner une voiture avec verrou
    SELECT immat, compteur INTO v_immat, v_compteur
    FROM Voiture
    WHERE ROWNUM = 1
    FOR UPDATE;  -- VERROUILLE la ligne
    
    DBMS_OUTPUT.PUT_LINE('✓ Ligne verrouillée pour: ' || v_immat);
    DBMS_OUTPUT.PUT_LINE('  Compteur actuel: ' || v_compteur || ' km');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Toute autre session qui tente un SELECT FOR UPDATE');
    DBMS_OUTPUT.PUT_LINE('ou un UPDATE sur cette voiture sera BLOQUÉE jusqu''au COMMIT/ROLLBACK');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Simuler un traitement
    DBMS_LOCK.SLEEP(2);
    
    -- Mise à jour sécurisée
    UPDATE Voiture
    SET compteur = v_compteur + 100
    WHERE immat = v_immat;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Mise à jour effectuée et verrou relâché');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END demo_select_for_update;
/

EXECUTE demo_select_for_update;

PROMPT ============================================================
PROMPT Exemples d'utilisation de SELECT FOR UPDATE
PROMPT ============================================================

PROMPT Exemple 1: Réserver une voiture disponible

CREATE OR REPLACE PROCEDURE reserver_voiture(
    p_immat VARCHAR2,
    p_codeC NUMBER
) AS
    v_etat VARCHAR2(20);
BEGIN
    -- Verrouiller et vérifier
    SELECT etat INTO v_etat
    FROM Voiture
    WHERE immat = p_immat
    FOR UPDATE;
    
    IF v_etat != 'disponible' THEN
        RAISE_APPLICATION_ERROR(-20100, 
            'Voiture non disponible (état: ' || v_etat || ')');
    END IF;
    
    -- Mettre à jour l'état
    UPDATE Voiture
    SET etat = 'en location'
    WHERE immat = p_immat;
    
    DBMS_OUTPUT.PUT_LINE('✓ Voiture ' || p_immat || ' réservée pour client ' || p_codeC);
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20101, 'Voiture non trouvée');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END reserver_voiture;
/

PROMPT Exemple 2: SELECT FOR UPDATE avec timeout

PROMPT 
PROMPT Usage:
PROMPT   SELECT * FROM Voiture 
PROMPT   WHERE immat = 'AA-123-AA'
PROMPT   FOR UPDATE WAIT 5;  -- Attendre max 5 secondes
PROMPT 
PROMPT   SELECT * FROM Voiture
PROMPT   WHERE immat = 'AA-123-AA'
PROMPT   FOR UPDATE NOWAIT;  -- Ne pas attendre, erreur immédiate si verrouillé
PROMPT 

PROMPT ============================================================
PROMPT Exemple 3: SELECT FOR UPDATE sur plusieurs tables
PROMPT ============================================================

CREATE OR REPLACE PROCEDURE transfert_voiture(
    p_immat VARCHAR2,
    p_ancien_proprio NUMBER,
    p_nouveau_proprio NUMBER
) AS
    v_ancien Proprietaire%ROWTYPE;
    v_nouveau Proprietaire%ROWTYPE;
    v_voiture Voiture%ROWTYPE;
BEGIN
    -- Verrouiller dans l'ordre pour éviter les deadlocks
    -- (toujours verrouiller dans le même ordre!)
    
    -- 1. Propriétaires
    SELECT * INTO v_ancien
    FROM Proprietaire
    WHERE CodeP = p_ancien_proprio
    FOR UPDATE;
    
    SELECT * INTO v_nouveau
    FROM Proprietaire
    WHERE CodeP = p_nouveau_proprio
    FOR UPDATE;
    
    -- 2. Voiture
    SELECT * INTO v_voiture
    FROM Voiture
    WHERE immat = p_immat
    FOR UPDATE;
    
    -- Vérifier que la voiture appartient bien à l'ancien proprio
    IF v_voiture.codeP != p_ancien_proprio THEN
        RAISE_APPLICATION_ERROR(-20200, 'La voiture n''appartient pas à ce propriétaire');
    END IF;
    
    -- Effectuer le transfert
    UPDATE Voiture
    SET codeP = p_nouveau_proprio
    WHERE immat = p_immat;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Transfert effectué: ' || p_immat || 
                        ' de ' || v_ancien.pseudo || ' à ' || v_nouveau.pseudo);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END transfert_voiture;
/

PROMPT ============================================================
PROMPT Tests pratiques à exécuter manuellement
PROMPT ============================================================

PROMPT === Test 1: Lost Update ===
PROMPT 
PROMPT Terminal 1:
PROMPT   BEGIN
PROMPT     UPDATE Voiture SET compteur = compteur + 100 WHERE ROWNUM = 1;
PROMPT     DBMS_LOCK.SLEEP(10);
PROMPT     COMMIT;
PROMPT   END;
PROMPT   /
PROMPT 
PROMPT Terminal 2 (pendant les 10 secondes):
PROMPT   UPDATE Voiture SET compteur = compteur + 150 WHERE ROWNUM = 1;
PROMPT   -- Sera bloqué jusqu'au COMMIT du Terminal 1
PROMPT   COMMIT;
PROMPT 
PROMPT Résultat: Les deux updates sont appliqués correctement!
PROMPT 

PROMPT === Test 2: SELECT FOR UPDATE avec timeout ===
PROMPT 
PROMPT Terminal 1:
PROMPT   SELECT * FROM Voiture WHERE ROWNUM = 1 FOR UPDATE;
PROMPT   -- Ne pas faire COMMIT
PROMPT 
PROMPT Terminal 2:
PROMPT   SELECT * FROM Voiture WHERE ROWNUM = 1 FOR UPDATE WAIT 3;
PROMPT   -- Attendra 3 secondes puis erreur ORA-30006
PROMPT 
PROMPT Terminal 1:
PROMPT   COMMIT;  -- Libère le verrou
PROMPT 

PROMPT ============================================================
PROMPT Résumé des niveaux d'isolation Oracle
PROMPT ============================================================

PROMPT Oracle supporte 3 niveaux d'isolation:
PROMPT 
PROMPT 1. READ COMMITTED (par défaut)
PROMPT    - Empêche les lectures sales (dirty reads)
PROMPT    - Permet les lectures non répétables (non-repeatable reads)
PROMPT    - Permet les lectures fantômes (phantom reads)
PROMPT 
PROMPT 2. SERIALIZABLE
PROMPT    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
PROMPT    - Empêche tous les problèmes ci-dessus
PROMPT    - Peut générer des erreurs ORA-08177 (can't serialize access)
PROMPT 
PROMPT 3. READ ONLY
PROMPT    SET TRANSACTION READ ONLY;
PROMPT    - Lecture seule, snapshot au moment du BEGIN
PROMPT 

PROMPT ============================================================
PROMPT ✅ Script 07_concurrency.sql terminé
PROMPT ============================================================
PROMPT 
PROMPT Concepts couverts:
PROMPT  ✓ Mise à jour perdue (Lost Update)
PROMPT  ✓ Lecture non répétable (Non-Repeatable Read)
PROMPT  ✓ SELECT FOR UPDATE et ses variantes
PROMPT  ✓ Gestion des verrous et timeouts
PROMPT  ✓ Niveaux d'isolation Oracle
PROMPT 
PROMPT Pour les tests réels, ouvrez plusieurs sessions SQL*Plus
PROMPT et reproduisez les scénarios décrits ci-dessus
PROMPT 
PROMPT Prochaine étape: Exécuter 99_demo.sql pour une démo complète
PROMPT 
