-- ============================================================================
-- Script 01: Création du schéma de base
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Création des tables principales de la base de données
-- Ordre d'exécution: 1er script à exécuter
-- Prérequis: Utilisateur BDA2025 créé avec les privilèges appropriés
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE

-- Nettoyage (si tables existent déjà)
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE Location CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Voiture CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Client CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE Proprietaire CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Tables n''existent pas encore - OK');
END;
/

PROMPT ============================================================
PROMPT Création de la table PROPRIETAIRE
PROMPT ============================================================

CREATE TABLE Proprietaire (
    CodeP   VARCHAR2(10) PRIMARY KEY,
    pseudo  VARCHAR2(50),
    email   VARCHAR2(100),
    Ville   VARCHAR2(60),
    anneeI  NUMBER(4)
);

COMMENT ON TABLE Proprietaire IS 'Table des propriétaires de véhicules';
COMMENT ON COLUMN Proprietaire.CodeP IS 'Code unique du propriétaire (PK)';
COMMENT ON COLUMN Proprietaire.pseudo IS 'Pseudonyme du propriétaire';
COMMENT ON COLUMN Proprietaire.email IS 'Adresse email du propriétaire';
COMMENT ON COLUMN Proprietaire.Ville IS 'Ville de résidence';
COMMENT ON COLUMN Proprietaire.anneeI IS 'Année d''inscription';

PROMPT ✓ Table PROPRIETAIRE créée

PROMPT ============================================================
PROMPT Création de la table CLIENT
PROMPT ============================================================

CREATE TABLE Client (
    CodeC   VARCHAR2(10) PRIMARY KEY,
    Nom     VARCHAR2(50),
    Prenom  VARCHAR2(50),
    Age     NUMBER(3),
    Permis  VARCHAR2(20),
    Adresse VARCHAR2(200),
    Ville   VARCHAR2(60)
);

COMMENT ON TABLE Client IS 'Table des clients (locataires)';
COMMENT ON COLUMN Client.CodeC IS 'Code unique du client (PK)';
COMMENT ON COLUMN Client.Nom IS 'Nom de famille du client';
COMMENT ON COLUMN Client.Prenom IS 'Prénom du client';
COMMENT ON COLUMN Client.Age IS 'Âge du client';
COMMENT ON COLUMN Client.Permis IS 'Numéro de permis de conduire';
COMMENT ON COLUMN Client.Adresse IS 'Adresse complète du client';
COMMENT ON COLUMN Client.Ville IS 'Ville du client';

PROMPT ✓ Table CLIENT créée

PROMPT ============================================================
PROMPT Création de la table VOITURE
PROMPT ============================================================

CREATE TABLE Voiture (
    Immat     VARCHAR2(20) PRIMARY KEY,
    Modele    VARCHAR2(60),
    Marque    VARCHAR2(60),
    Categorie VARCHAR2(30),
    Couleur   VARCHAR2(30),
    Places    NUMBER(2),
    achatA    NUMBER(4),
    compteur  NUMBER,
    prixJ     NUMBER(10,2),
    codeP     VARCHAR2(10),
    etat      VARCHAR2(20) DEFAULT 'disponible',  -- Ajouté pour partie 5.4
    CONSTRAINT fk_voiture_proprio FOREIGN KEY (codeP) 
        REFERENCES Proprietaire(CodeP)
);

COMMENT ON TABLE Voiture IS 'Table des véhicules disponibles à la location';
COMMENT ON COLUMN Voiture.Immat IS 'Immatriculation du véhicule (PK)';
COMMENT ON COLUMN Voiture.Modele IS 'Modèle du véhicule';
COMMENT ON COLUMN Voiture.Marque IS 'Marque du véhicule';
COMMENT ON COLUMN Voiture.Categorie IS 'Catégorie (citadine, berline, SUV, etc.)';
COMMENT ON COLUMN Voiture.Couleur IS 'Couleur du véhicule';
COMMENT ON COLUMN Voiture.Places IS 'Nombre de places';
COMMENT ON COLUMN Voiture.achatA IS 'Année d''achat';
COMMENT ON COLUMN Voiture.compteur IS 'Kilométrage au compteur';
COMMENT ON COLUMN Voiture.prixJ IS 'Prix journalier de location';
COMMENT ON COLUMN Voiture.codeP IS 'Code propriétaire (FK)';
COMMENT ON COLUMN Voiture.etat IS 'État actuel (disponible, en location, en réparation)';

PROMPT ✓ Table VOITURE créée

PROMPT ============================================================
PROMPT Création de la table LOCATION
PROMPT ============================================================

CREATE TABLE Location (
    CodeC  VARCHAR2(10),
    Immat  VARCHAR2(20),
    Annee  NUMBER(4),
    Mois   NUMBER(2),
    numLoc VARCHAR2(10),
    km     NUMBER,
    duree  NUMBER,
    villed VARCHAR2(60),
    villea VARCHAR2(60),
    dated  DATE,
    datef  DATE,
    note   NUMBER,
    avis   VARCHAR2(50),
    CONSTRAINT pk_location PRIMARY KEY (CodeC, Immat, Annee, Mois, numLoc),
    CONSTRAINT fk_location_client FOREIGN KEY (CodeC) 
        REFERENCES Client(CodeC),
    CONSTRAINT fk_location_voiture FOREIGN KEY (Immat) 
        REFERENCES Voiture(Immat)
);

COMMENT ON TABLE Location IS 'Table des locations (historique)';
COMMENT ON COLUMN Location.CodeC IS 'Code client (FK, partie de la PK)';
COMMENT ON COLUMN Location.Immat IS 'Immatriculation véhicule (FK, partie de la PK)';
COMMENT ON COLUMN Location.Annee IS 'Année de la location (partie de la PK)';
COMMENT ON COLUMN Location.Mois IS 'Mois de la location (partie de la PK)';
COMMENT ON COLUMN Location.numLoc IS 'Numéro de location dans le mois (partie de la PK)';
COMMENT ON COLUMN Location.km IS 'Kilométrage parcouru';
COMMENT ON COLUMN Location.duree IS 'Durée en jours';
COMMENT ON COLUMN Location.villed IS 'Ville de départ';
COMMENT ON COLUMN Location.villea IS 'Ville d''arrivée';
COMMENT ON COLUMN Location.dated IS 'Date de début';
COMMENT ON COLUMN Location.datef IS 'Date de fin';
COMMENT ON COLUMN Location.note IS 'Note de satisfaction (1-5)';
COMMENT ON COLUMN Location.avis IS 'Avis textuel';

PROMPT ✓ Table LOCATION créée

PROMPT ============================================================
PROMPT Création de la table VOITURE_ETAT_HISTO (partie 5.5)
PROMPT ============================================================

CREATE TABLE Voiture_Etat_Histo (
    histo_id   NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    immat      VARCHAR2(20) NOT NULL,
    etat_avant VARCHAR2(20),
    etat_apres VARCHAR2(20),
    changed_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    changed_by VARCHAR2(100) DEFAULT USER,
    CONSTRAINT fk_histo_voiture FOREIGN KEY (immat) 
        REFERENCES Voiture(Immat)
);

COMMENT ON TABLE Voiture_Etat_Histo IS 'Historique des changements d''état des véhicules';
COMMENT ON COLUMN Voiture_Etat_Histo.histo_id IS 'ID auto-incrémenté';
COMMENT ON COLUMN Voiture_Etat_Histo.immat IS 'Immatriculation du véhicule';
COMMENT ON COLUMN Voiture_Etat_Histo.etat_avant IS 'État avant modification';
COMMENT ON COLUMN Voiture_Etat_Histo.etat_apres IS 'État après modification';
COMMENT ON COLUMN Voiture_Etat_Histo.changed_at IS 'Date/heure du changement';
COMMENT ON COLUMN Voiture_Etat_Histo.changed_by IS 'Utilisateur ayant fait la modification';

PROMPT ✓ Table VOITURE_ETAT_HISTO créée

PROMPT ============================================================
PROMPT Récapitulatif des tables créées
PROMPT ============================================================

SELECT table_name, 
       TO_CHAR(created, 'DD/MM/YYYY HH24:MI:SS') AS created
FROM user_tables
ORDER BY created DESC;

PROMPT ============================================================
PROMPT ✅ Script 01_schema.sql exécuté avec succès
PROMPT ============================================================
PROMPT 
PROMPT Prochaine étape: Importer les données CSV puis exécuter 02_constraints.sql
PROMPT 
