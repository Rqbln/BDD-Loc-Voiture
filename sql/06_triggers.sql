-- ============================================================================
-- Script 06: Triggers (Partie 5.4-5.5)
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Triggers pour gérer l'état des voitures et l'historique
-- Ordre d'exécution: 6ème script
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON

PROMPT ============================================================
PROMPT Partie 5.5: Trigger d'historique des changements d'état
PROMPT ============================================================

CREATE OR REPLACE TRIGGER trg_voiture_etat_hist
AFTER UPDATE OF etat ON Voiture
FOR EACH ROW
WHEN (NEW.etat IS DISTINCT FROM OLD.etat)
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;  -- Transaction autonome pour l'historique
BEGIN
    -- Insérer dans l'historique
    INSERT INTO Voiture_Etat_Histo (immat, etat_avant, etat_apres)
    VALUES (:NEW.immat, :OLD.etat, :NEW.etat);
    
    COMMIT;  -- Commit de la transaction autonome
    
    -- Log pour debug
    DBMS_OUTPUT.PUT_LINE(
        'Historique: ' || :NEW.immat || 
        ' | ' || NVL(:OLD.etat, 'NULL') || 
        ' → ' || NVL(:NEW.etat, 'NULL')
    );
    
EXCEPTION
    WHEN OTHERS THEN
        -- Ne pas bloquer la transaction principale en cas d'erreur
        DBMS_OUTPUT.PUT_LINE('⚠ Erreur historique: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT ✓ Trigger trg_voiture_etat_hist créé

PROMPT ============================================================
PROMPT Partie 5.4: Trigger de vérification avant location
PROMPT ============================================================

CREATE OR REPLACE TRIGGER trg_location_verification
BEFORE INSERT OR UPDATE ON Location
FOR EACH ROW
DECLARE
    v_etat_voiture Voiture.etat%TYPE;
    v_nb_locations NUMBER;
BEGIN
    -- Récupérer l'état actuel de la voiture
    SELECT etat INTO v_etat_voiture
    FROM Voiture
    WHERE immat = :NEW.immat;
    
    -- Vérifier que la voiture est disponible
    IF v_etat_voiture != 'disponible' THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'La voiture ' || :NEW.immat || ' n''est pas disponible (état: ' || v_etat_voiture || ')');
    END IF;
    
    -- Vérifier qu'il n'y a pas de chevauchement de dates
    IF :NEW.dated IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_nb_locations
        FROM Location
        WHERE immat = :NEW.immat
          AND (CodeC != :NEW.CodeC OR Annee != :NEW.Annee OR Mois != :NEW.Mois OR numLoc != :NEW.numLoc)
          AND dated IS NOT NULL
          AND datef IS NOT NULL
          AND (
              :NEW.dated BETWEEN dated AND datef
              OR NVL(:NEW.datef, :NEW.dated + 365) BETWEEN dated AND datef
          );
        
        IF v_nb_locations > 0 THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Chevauchement de dates pour la voiture ' || :NEW.immat);
        END IF;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('✓ Vérification location OK pour ' || :NEW.immat);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Voiture ' || :NEW.immat || ' introuvable');
END;
/

PROMPT ✓ Trigger trg_location_verification créé

PROMPT ============================================================
PROMPT Trigger: Mise à jour automatique de l'état lors de location
PROMPT ============================================================

CREATE OR REPLACE TRIGGER trg_location_update_etat
AFTER INSERT ON Location
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Mettre la voiture en location si la date de début est aujourd'hui ou passée
    IF :NEW.dated <= SYSDATE THEN
        UPDATE Voiture
        SET etat = 'en location'
        WHERE immat = :NEW.immat
          AND etat = 'disponible';
        
        IF SQL%ROWCOUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('✓ Voiture ' || :NEW.immat || ' mise en location');
        END IF;
        
        COMMIT;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Erreur mise à jour état: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT ✓ Trigger trg_location_update_etat créé

PROMPT ============================================================
PROMPT Trigger: Mise à jour du compteur après location
PROMPT ============================================================

CREATE OR REPLACE TRIGGER trg_location_update_compteur
AFTER UPDATE OF datef ON Location
FOR EACH ROW
WHEN (NEW.datef IS NOT NULL AND OLD.datef IS NULL AND NEW.km IS NOT NULL)
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    -- Ajouter les km parcourus au compteur de la voiture
    UPDATE Voiture
    SET compteur = compteur + :NEW.km,
        etat = 'disponible'
    WHERE immat = :NEW.immat;
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE(
        '✓ Compteur mis à jour pour ' || :NEW.immat || 
        ' (+' || :NEW.km || ' km)'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Erreur compteur: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT ✓ Trigger trg_location_update_compteur créé

PROMPT ============================================================
PROMPT Trigger: Audit des modifications de prix
PROMPT ============================================================

-- Table d'audit pour les modifications de prix
CREATE TABLE Voiture_Prix_Audit (
    audit_id   NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    immat      VARCHAR2(20),
    prix_avant NUMBER(10,2),
    prix_apres NUMBER(10,2),
    changed_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    changed_by VARCHAR2(100) DEFAULT USER
);

COMMENT ON TABLE Voiture_Prix_Audit IS 'Audit des modifications de prix';

CREATE OR REPLACE TRIGGER trg_voiture_prix_audit
AFTER UPDATE OF prixJ ON Voiture
FOR EACH ROW
WHEN (NEW.prixJ != OLD.prixJ)
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO Voiture_Prix_Audit (immat, prix_avant, prix_apres)
    VALUES (:NEW.immat, :OLD.prixJ, :NEW.prixJ);
    
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE(
        'Audit prix: ' || :NEW.immat || 
        ' | ' || :OLD.prixJ || '€ → ' || :NEW.prixJ || '€'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('⚠ Erreur audit: ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT ✓ Trigger trg_voiture_prix_audit créé

PROMPT ============================================================
PROMPT Trigger: Validation des dates de location
PROMPT ============================================================

CREATE OR REPLACE TRIGGER trg_location_dates
BEFORE INSERT OR UPDATE ON Location
FOR EACH ROW
BEGIN
    -- Vérifier que dated est définie
    IF :NEW.dated IS NULL THEN
        RAISE_APPLICATION_ERROR(-20010, 'La date de début est obligatoire');
    END IF;
    
    -- Vérifier que dated n'est pas dans le futur lointain (> 1 an)
    IF :NEW.dated > ADD_MONTHS(SYSDATE, 12) THEN
        RAISE_APPLICATION_ERROR(-20011, 'La date de début est trop éloignée dans le futur');
    END IF;
    
    -- Vérifier la cohérence dated/datef
    IF :NEW.datef IS NOT NULL AND :NEW.datef < :NEW.dated THEN
        RAISE_APPLICATION_ERROR(-20012, 'La date de fin doit être après la date de début');
    END IF;
    
    -- Calculer automatiquement la durée si les deux dates sont présentes
    IF :NEW.dated IS NOT NULL AND :NEW.datef IS NOT NULL THEN
        :NEW.duree := :NEW.datef - :NEW.dated;
    END IF;
    
END;
/

PROMPT ✓ Trigger trg_location_dates créé

PROMPT ============================================================
PROMPT Tests des triggers
PROMPT ============================================================

PROMPT Test 1: Changement d'état d'une voiture
DECLARE
    v_immat VARCHAR2(20);
BEGIN
    -- Récupérer une voiture
    SELECT immat INTO v_immat
    FROM Voiture
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('Test sur la voiture: ' || v_immat);
    
    -- Changer l'état plusieurs fois
    UPDATE Voiture SET etat = 'en réparation' WHERE immat = v_immat;
    UPDATE Voiture SET etat = 'disponible' WHERE immat = v_immat;
    UPDATE Voiture SET etat = 'en location' WHERE immat = v_immat;
    UPDATE Voiture SET etat = 'disponible' WHERE immat = v_immat;
    
    COMMIT;
    
    -- Afficher l'historique
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Historique des changements:');
    FOR r IN (
        SELECT etat_avant, etat_apres, 
               TO_CHAR(changed_at, 'DD/MM/YYYY HH24:MI:SS') AS quand
        FROM Voiture_Etat_Histo
        WHERE immat = v_immat
        ORDER BY changed_at
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || r.quand || ' : ' || 
                           NVL(r.etat_avant, 'NULL') || ' → ' || r.etat_apres);
    END LOOP;
    
END;
/

PROMPT Test 2: Modification de prix
DECLARE
    v_immat VARCHAR2(20);
    v_prix_initial NUMBER;
BEGIN
    SELECT immat, prixJ INTO v_immat, v_prix_initial
    FROM Voiture
    WHERE ROWNUM = 1;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Test modification de prix sur: ' || v_immat);
    
    -- Modifier le prix plusieurs fois
    UPDATE Voiture SET prixJ = prixJ * 1.1 WHERE immat = v_immat;
    UPDATE Voiture SET prixJ = prixJ * 0.9 WHERE immat = v_immat;
    UPDATE Voiture SET prixJ = v_prix_initial WHERE immat = v_immat;
    
    COMMIT;
    
    -- Afficher l'audit
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Audit des prix:');
    FOR r IN (
        SELECT prix_avant, prix_apres,
               TO_CHAR(changed_at, 'DD/MM/YYYY HH24:MI:SS') AS quand
        FROM Voiture_Prix_Audit
        WHERE immat = v_immat
        ORDER BY changed_at DESC
        FETCH FIRST 5 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('  ' || r.quand || ' : ' || 
                           r.prix_avant || '€ → ' || r.prix_apres || '€');
    END LOOP;
    
END;
/

PROMPT ============================================================
PROMPT Statistiques des triggers
PROMPT ============================================================

SELECT 
    trigger_name,
    triggering_event,
    table_name,
    status
FROM user_triggers
WHERE table_name IN ('VOITURE', 'LOCATION')
ORDER BY table_name, trigger_name;

-- Vérifier les erreurs de compilation
SELECT name, type, line, position, text
FROM user_errors
WHERE name LIKE 'TRG_%'
ORDER BY name, sequence;

PROMPT ============================================================
PROMPT Exemples de requêtes sur l'historique
PROMPT ============================================================

PROMPT Nombre de changements d'état par voiture (top 10):
SELECT 
    immat,
    COUNT(*) AS nb_changements,
    MIN(changed_at) AS premier_changement,
    MAX(changed_at) AS dernier_changement
FROM Voiture_Etat_Histo
GROUP BY immat
ORDER BY nb_changements DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT ✅ Script 06_triggers.sql exécuté avec succès
PROMPT ============================================================
PROMPT 
PROMPT Triggers créés:
PROMPT  - trg_voiture_etat_hist        : Historique des changements d'état
PROMPT  - trg_location_verification    : Vérification avant location
PROMPT  - trg_location_update_etat     : Mise à jour de l'état en location
PROMPT  - trg_location_update_compteur : Mise à jour du compteur
PROMPT  - trg_voiture_prix_audit       : Audit des modifications de prix
PROMPT  - trg_location_dates           : Validation des dates
PROMPT 
PROMPT Tables d'audit créées:
PROMPT  - Voiture_Etat_Histo          : Historique des états
PROMPT  - Voiture_Prix_Audit          : Historique des prix
PROMPT 
PROMPT Prochaine étape: Exécuter 07_concurrency.sql
PROMPT 
