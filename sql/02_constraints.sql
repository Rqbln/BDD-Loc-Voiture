-- ============================================================================
-- Script 02: Contraintes d'intégrité et mises à jour
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Ajout de contraintes et préparation des données (partie 1.2-1.4)
-- Ordre d'exécution: 2ème script (après import des CSV)
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON

PROMPT ============================================================
PROMPT Partie 1.2a: Mise à jour aléatoire de datef
PROMPT ============================================================

-- Mettre à jour la date de fin avec une valeur aléatoire (0 à 100 jours)
UPDATE Location
SET datef = dated + TRUNC(DBMS_RANDOM.VALUE(0, 100))
WHERE dated IS NOT NULL AND datef IS NULL;

PROMPT ✓ Dates de fin générées aléatoirement

PROMPT ============================================================
PROMPT Recalcul de la durée (datef - dated)
PROMPT ============================================================

UPDATE Location
SET duree = datef - dated
WHERE dated IS NOT NULL AND datef IS NOT NULL;

COMMIT;

PROMPT ✓ Durées recalculées

PROMPT ============================================================
PROMPT Partie 1.3: Ajout de contraintes d'intégrité
PROMPT ============================================================

-- Contrainte: Age du client doit être >= 18
ALTER TABLE Client ADD CONSTRAINT chk_client_age 
    CHECK (Age >= 18 AND Age <= 120);

PROMPT ✓ Contrainte âge client ajoutée

-- Contrainte: Note entre 1 et 5 ou NULL
ALTER TABLE Location ADD CONSTRAINT chk_location_note 
    CHECK (note IS NULL OR (note >= 1 AND note <= 5));

PROMPT ✓ Contrainte note ajoutée

-- Contrainte: Mois entre 1 et 12
ALTER TABLE Location ADD CONSTRAINT chk_location_mois 
    CHECK (Mois >= 1 AND Mois <= 12);

PROMPT ✓ Contrainte mois ajoutée

-- Contrainte: datef >= dated
ALTER TABLE Location ADD CONSTRAINT chk_location_dates 
    CHECK (datef IS NULL OR datef >= dated);

PROMPT ✓ Contrainte dates cohérentes ajoutée

-- Contrainte: prix journalier positif
ALTER TABLE Voiture ADD CONSTRAINT chk_voiture_prix 
    CHECK (prixJ > 0);

PROMPT ✓ Contrainte prix positif ajoutée

-- Contrainte: places entre 1 et 9
ALTER TABLE Voiture ADD CONSTRAINT chk_voiture_places 
    CHECK (Places >= 1 AND Places <= 9);

PROMPT ✓ Contrainte nombre de places ajoutée

-- Contrainte: compteur >= 0
ALTER TABLE Voiture ADD CONSTRAINT chk_voiture_compteur 
    CHECK (compteur >= 0);

PROMPT ✓ Contrainte compteur positif ajoutée

-- Contrainte: km parcouru >= 0
ALTER TABLE Location ADD CONSTRAINT chk_location_km 
    CHECK (km IS NULL OR km >= 0);

PROMPT ✓ Contrainte km positifs ajoutée

-- Contrainte: duree >= 0
ALTER TABLE Location ADD CONSTRAINT chk_location_duree 
    CHECK (duree IS NULL OR duree >= 0);

PROMPT ✓ Contrainte durée positive ajoutée

-- Contrainte: états valides pour voiture
ALTER TABLE Voiture ADD CONSTRAINT chk_voiture_etat 
    CHECK (etat IN ('disponible', 'en location', 'en réparation', 'hors service'));

PROMPT ✓ Contrainte état voiture ajoutée

-- Contrainte: email unique pour propriétaire
ALTER TABLE Proprietaire ADD CONSTRAINT uk_proprietaire_email 
    UNIQUE (email);

PROMPT ✓ Contrainte email unique ajoutée

-- Contrainte: format email basique
ALTER TABLE Proprietaire ADD CONSTRAINT chk_proprietaire_email 
    CHECK (email LIKE '%@%.%');

PROMPT ✓ Contrainte format email ajoutée

PROMPT ============================================================
PROMPT Création d'index pour améliorer les performances
PROMPT ============================================================

-- Index sur les clés étrangères
CREATE INDEX idx_voiture_codep ON Voiture(codeP);
CREATE INDEX idx_location_codec ON Location(CodeC);
CREATE INDEX idx_location_immat ON Location(Immat);

-- Index sur les colonnes fréquemment utilisées pour les recherches
CREATE INDEX idx_location_dated ON Location(dated);
CREATE INDEX idx_location_datef ON Location(datef);
CREATE INDEX idx_voiture_categorie ON Voiture(Categorie);
CREATE INDEX idx_voiture_marque ON Voiture(Marque);
CREATE INDEX idx_client_nom ON Client(Nom, Prenom);

PROMPT ✓ Index créés

PROMPT ============================================================
PROMPT Partie 1.4: Vérification des contraintes
PROMPT ============================================================

-- Vérifier toutes les contraintes
SELECT constraint_name, 
       constraint_type,
       table_name,
       status
FROM user_constraints
WHERE table_name IN ('PROPRIETAIRE', 'CLIENT', 'VOITURE', 'LOCATION')
ORDER BY table_name, constraint_type;

PROMPT ============================================================
PROMPT Test des contraintes (exemples)
PROMPT ============================================================

PROMPT Test 1: Tentative d'insertion d'un client mineur (devrait échouer)
DECLARE
    v_error VARCHAR2(500);
BEGIN
    INSERT INTO Client (CodeC, Nom, Prenom, Age, Permis, Adresse)
    VALUES (99999, 'TEST', 'Mineur', 15, 'INVALID', 'Test Adresse');
    DBMS_OUTPUT.PUT_LINE('❌ ERREUR: L''insertion a réussi alors qu''elle devrait échouer!');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Test réussi: Insertion mineur refusée');
        DBMS_OUTPUT.PUT_LINE('  Message: ' || SUBSTR(SQLERRM, 1, 100));
END;
/

PROMPT Test 2: Tentative d'insertion d'une note invalide (devrait échouer)
DECLARE
    v_error VARCHAR2(500);
BEGIN
    -- Nécessite une location existante
    UPDATE Location 
    SET note = 10 
    WHERE ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('❌ ERREUR: La mise à jour a réussi alors qu''elle devrait échouer!');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Test réussi: Note invalide refusée');
        DBMS_OUTPUT.PUT_LINE('  Message: ' || SUBSTR(SQLERRM, 1, 100));
END;
/

PROMPT Test 3: Tentative de prix négatif (devrait échouer)
DECLARE
    v_error VARCHAR2(500);
BEGIN
    UPDATE Voiture 
    SET prixJ = -50 
    WHERE ROWNUM = 1;
    DBMS_OUTPUT.PUT_LINE('❌ ERREUR: La mise à jour a réussi alors qu''elle devrait échouer!');
    ROLLBACK;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('✓ Test réussi: Prix négatif refusé');
        DBMS_OUTPUT.PUT_LINE('  Message: ' || SUBSTR(SQLERRM, 1, 100));
END;
/

PROMPT ============================================================
PROMPT Statistiques des tables
PROMPT ============================================================

SELECT 'PROPRIETAIRE' AS table_name, COUNT(*) AS nb_lignes FROM Proprietaire
UNION ALL
SELECT 'CLIENT', COUNT(*) FROM Client
UNION ALL
SELECT 'VOITURE', COUNT(*) FROM Voiture
UNION ALL
SELECT 'LOCATION', COUNT(*) FROM Location
ORDER BY table_name;

PROMPT ============================================================
PROMPT Vérification de l'intégrité référentielle
PROMPT ============================================================

-- Voitures sans propriétaire (devrait être vide)
SELECT COUNT(*) AS voitures_sans_proprio
FROM Voiture v
WHERE NOT EXISTS (SELECT 1 FROM Proprietaire p WHERE p.CodeP = v.codeP);

-- Locations sans client (devrait être vide)
SELECT COUNT(*) AS locations_sans_client
FROM Location l
WHERE NOT EXISTS (SELECT 1 FROM Client c WHERE c.CodeC = l.CodeC);

-- Locations sans voiture (devrait être vide)
SELECT COUNT(*) AS locations_sans_voiture
FROM Location l
WHERE NOT EXISTS (SELECT 1 FROM Voiture v WHERE v.Immat = l.Immat);

PROMPT ============================================================
PROMPT ✅ Script 02_constraints.sql exécuté avec succès
PROMPT ============================================================
PROMPT 
PROMPT Prochaine étape: Exécuter 03_views.sql
PROMPT 
