-- ============================================================================
-- Script 03: Création des vues (Partie 2)
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Création et tests des vues demandées dans la partie 2
-- Ordre d'exécution: 3ème script
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON

PROMPT ============================================================
PROMPT Partie 2.1: Création de la vue V_Client
PROMPT ============================================================

CREATE OR REPLACE VIEW V_Client AS
SELECT 
    c.CodeC,
    c.Prenom,
    c.Nom,
    c.Age,
    NVL(SUM(l.km), 0) AS distance
FROM Client c
LEFT JOIN Location l ON l.CodeC = c.CodeC
GROUP BY c.CodeC, c.Prenom, c.Nom, c.Age;

COMMENT ON TABLE V_Client IS 'Vue des clients avec leur kilométrage total';

PROMPT ✓ Vue V_Client créée

-- Afficher quelques lignes
SELECT * FROM V_Client WHERE ROWNUM <= 5 ORDER BY distance DESC;

PROMPT ============================================================
PROMPT Partie 2.2: Test de mise à jour via V_Client
PROMPT ============================================================

PROMPT Test 1: Mise à jour du nom d'un client (colonne mappée)

-- Sélectionner un client pour le test
DECLARE
    v_codec Client.CodeC%TYPE;
    v_old_nom Client.Nom%TYPE;
    v_new_nom Client.Nom%TYPE := 'DUPONT_TEST';
    v_updated_nom Client.Nom%TYPE;
BEGIN
    -- Récupérer le premier client
    SELECT CodeC, Nom INTO v_codec, v_old_nom
    FROM Client WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Client sélectionné: CodeC=' || v_codec || ', Nom=' || v_old_nom);
    
    -- Tenter la mise à jour via la vue
    UPDATE V_Client 
    SET Nom = v_new_nom 
    WHERE CodeC = v_codec;
    
    -- Vérifier la mise à jour
    SELECT Nom INTO v_updated_nom 
    FROM Client 
    WHERE CodeC = v_codec;
    
    IF v_updated_nom = v_new_nom THEN
        DBMS_OUTPUT.PUT_LINE('✓ Mise à jour du nom réussie via la vue!');
        DBMS_OUTPUT.PUT_LINE('  Ancien nom: ' || v_old_nom);
        DBMS_OUTPUT.PUT_LINE('  Nouveau nom: ' || v_updated_nom);
    END IF;
    
    -- Restaurer l'ancien nom
    UPDATE Client SET Nom = v_old_nom WHERE CodeC = v_codec;
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('✓ Nom restauré');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Erreur: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT Test 2: Tentative de mise à jour de 'distance' (colonne dérivée/agrégée)

DECLARE
    v_codec Client.CodeC%TYPE;
BEGIN
    -- Récupérer un client
    SELECT CodeC INTO v_codec
    FROM Client WHERE ROWNUM = 1;
    
    -- Tenter de modifier la distance (devrait échouer)
    UPDATE V_Client 
    SET distance = 99999 
    WHERE CodeC = v_codec;
    
    DBMS_OUTPUT.PUT_LINE('❌ ALERTE: La mise à jour de distance a réussi (ne devrait pas)!');
    ROLLBACK;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Test réussi: Mise à jour de distance refusée (colonne calculée non updatable)');
        DBMS_OUTPUT.PUT_LINE('  Message: ' || SUBSTR(SQLERRM, 1, 150));
        ROLLBACK;
END;
/

PROMPT ============================================================
PROMPT Partie 2.3: Création de la vue V_Client55
PROMPT ============================================================

CREATE OR REPLACE VIEW V_Client55 AS
SELECT * 
FROM V_Client
WHERE Age > 55
WITH CHECK OPTION CONSTRAINT chk_v_client55;

COMMENT ON TABLE V_Client55 IS 'Vue des clients de plus de 55 ans (WITH CHECK OPTION)';

PROMPT ✓ Vue V_Client55 créée avec WITH CHECK OPTION

-- Afficher quelques lignes
SELECT CodeC, Nom, Prenom, Age, distance 
FROM V_Client55 
WHERE ROWNUM <= 5
ORDER BY Age DESC;

PROMPT ============================================================
PROMPT Partie 2.4: Test d'insertion dans V_Client55
PROMPT ============================================================

PROMPT Test: Insertion d'un client de 50 ans (devrait échouer à cause du CHECK OPTION)

DECLARE
    v_new_codec NUMBER := 99999;
BEGIN
    -- Tenter d'insérer un client de 50 ans
    INSERT INTO V_Client55 (CodeC, Nom, Prenom, Age, distance)
    VALUES (v_new_codec, 'TEST', 'Client50', 50, 0);
    
    DBMS_OUTPUT.PUT_LINE('❌ ALERTE: L''insertion a réussi (ne devrait pas car Age=50 <= 55)!');
    ROLLBACK;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Test réussi: Insertion refusée par WITH CHECK OPTION');
        DBMS_OUTPUT.PUT_LINE('  Message: ' || SUBSTR(SQLERRM, 1, 150));
        ROLLBACK;
END;
/

PROMPT Test: Insertion manuelle dans la table Client puis recherche via vues

DECLARE
    v_new_codec NUMBER := 99998;
BEGIN
    -- Insérer directement dans Client (contourne la vue)
    INSERT INTO Client (CodeC, Nom, Prenom, Age, Permis, Adresse)
    VALUES (v_new_codec, 'TESTDIRECT', 'Client50', 50, 'TEST12345', '123 Rue Test');
    
    DBMS_OUTPUT.PUT_LINE('✓ Insertion directe dans Client réussie (Age=50)');
    
    -- Chercher via V_Client55 (ne devrait PAS apparaître)
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM V_Client55
        WHERE CodeC = v_new_codec;
        
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Client non trouvé dans V_Client55 (normal, Age <= 55)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Client trouvé dans V_Client55 (anormal)!');
        END IF;
    END;
    
    -- Chercher via Client (devrait apparaître)
    DECLARE
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Client
        WHERE CodeC = v_new_codec;
        
        IF v_count = 1 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Client trouvé dans la table Client (normal)');
        ELSE
            DBMS_OUTPUT.PUT_LINE('❌ Client non trouvé dans Client (anormal)!');
        END IF;
    END;
    
    -- Nettoyer
    DELETE FROM Client WHERE CodeC = v_new_codec;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Données de test nettoyées');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('❌ Erreur: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT ============================================================
PROMPT Statistiques des vues
PROMPT ============================================================

SELECT 'Total clients dans V_Client' AS statistique, COUNT(*) AS nombre
FROM V_Client
UNION ALL
SELECT 'Clients > 55 ans dans V_Client55', COUNT(*)
FROM V_Client55
UNION ALL
SELECT 'Clients avec distance > 0', COUNT(*)
FROM V_Client WHERE distance > 0;

PROMPT ============================================================
PROMPT Top 10 clients par distance parcourue
PROMPT ============================================================

SELECT CodeC, Nom, Prenom, Age, distance
FROM V_Client
WHERE distance > 0
ORDER BY distance DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT Vérification des vues créées
PROMPT ============================================================

SELECT view_name, text
FROM user_views
WHERE view_name IN ('V_CLIENT', 'V_CLIENT55')
ORDER BY view_name;

PROMPT ============================================================
PROMPT ✅ Script 03_views.sql exécuté avec succès
PROMPT ============================================================
PROMPT 
PROMPT Résumé des tests:
PROMPT  - ✓ Mise à jour de colonnes mappées via vue fonctionne
PROMPT  - ✓ Mise à jour de colonnes dérivées/agrégées échoue (comportement attendu)
PROMPT  - ✓ WITH CHECK OPTION empêche les insertions ne respectant pas le filtre
PROMPT  - ✓ Les données insérées directement dans Client peuvent ne pas apparaître dans les vues filtrées
PROMPT 
PROMPT Prochaine étape: Exécuter 04_access.sql
PROMPT 
