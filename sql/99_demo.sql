-- ============================================================================
-- Script 99: Démonstration complète
-- BDA 2025 - Projet Agence de Location
-- ============================================================================
-- Description: Script de démonstration avec exemples concrets
-- Ordre d'exécution: Dernier script (tous les autres doivent être exécutés avant)
-- ============================================================================

SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100

PROMPT ============================================================
PROMPT 🚗 DÉMONSTRATION SYSTÈME DE LOCATION DE VOITURES
PROMPT ============================================================

PROMPT ============================================================
PROMPT Vue d'ensemble du système
PROMPT ============================================================

SELECT 
    'Total Propriétaires' AS metrique,
    TO_CHAR(COUNT(*), '999,999') AS valeur
FROM Proprietaire
UNION ALL
SELECT 'Total Clients', TO_CHAR(COUNT(*), '999,999')
FROM Client
UNION ALL
SELECT 'Total Voitures', TO_CHAR(COUNT(*), '999,999')
FROM Voiture
UNION ALL
SELECT 'Total Locations', TO_CHAR(COUNT(*), '999,999')
FROM Location
UNION ALL
SELECT 'Locations avec note', TO_CHAR(COUNT(*), '999,999')
FROM Location WHERE note IS NOT NULL;

PROMPT ============================================================
PROMPT TOP 10 Clients VIP (plus gros rouleurs)
PROMPT ============================================================

SELECT 
    ROWNUM AS rang,
    CodeC,
    RPAD(Nom || ' ' || Prenom, 30) AS client,
    Age,
    TO_CHAR(distance, '999,999') || ' km' AS total_km,
    get_client_status(CodeC) AS statut
FROM V_Client
WHERE distance > 0
ORDER BY distance DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT Voitures les plus rentables
PROMPT ============================================================

SELECT 
    v.Immat,
    v.Marque || ' ' || v.Modele AS vehicule,
    v.Categorie,
    TO_CHAR(v.prixJ, '999.99') || '€' AS prix_jour,
    COUNT(l.numLoc) AS nb_locations,
    TO_CHAR(SUM(l.duree), '999,999') || ' j' AS jours_loues,
    TO_CHAR(SUM(v.prixJ * l.duree), '999,999.99') || '€' AS ca_total,
    v.etat
FROM Voiture v
LEFT JOIN Location l ON l.immat = v.immat
GROUP BY v.Immat, v.Marque, v.Modele, v.Categorie, v.prixJ, v.etat
ORDER BY SUM(v.prixJ * l.duree) DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT Distribution des notes de satisfaction
PROMPT ============================================================

SELECT 
    NVL(TO_CHAR(note), 'Non évalué') AS note,
    avis,
    COUNT(*) AS nombre,
    RPAD('█', ROUND(COUNT(*) / 10), '█') AS graphique,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) || '%' AS pourcentage
FROM Location
GROUP BY note, avis
ORDER BY note NULLS FIRST;

PROMPT ============================================================
PROMPT Analyse par catégorie de voiture
PROMPT ============================================================

SELECT 
    v.Categorie,
    COUNT(DISTINCT v.Immat) AS nb_vehicules,
    COUNT(l.numLoc) AS nb_locations,
    ROUND(AVG(l.note), 2) AS note_moyenne,
    TO_CHAR(AVG(v.prixJ), '999.99') || '€' AS prix_moyen,
    TO_CHAR(SUM(v.prixJ * NVL(l.duree, 0)), '999,999.99') || '€' AS ca_total
FROM Voiture v
LEFT JOIN Location l ON l.immat = v.immat
GROUP BY v.Categorie
ORDER BY SUM(v.prixJ * NVL(l.duree, 0)) DESC NULLS LAST;

PROMPT ============================================================
PROMPT Flux départ → arrivée (Top trajets)
PROMPT ============================================================

SELECT 
    villed AS depart,
    villea AS arrivee,
    COUNT(*) AS nb_trajets,
    ROUND(AVG(km), 0) AS km_moyen,
    ROUND(AVG(duree), 1) AS duree_moyenne_jours
FROM Location
WHERE villed IS NOT NULL AND villea IS NOT NULL
GROUP BY villed, villea
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC
FETCH FIRST 15 ROWS ONLY;

PROMPT ============================================================
PROMPT Chiffre d'affaires par mois (derniers 12 mois)
PROMPT ============================================================

SELECT 
    Annee,
    Mois,
    TO_CHAR(TO_DATE(Mois || '/01/' || Annee, 'MM/DD/YYYY'), 'Month YYYY') AS periode,
    COUNT(*) AS nb_locations,
    TO_CHAR(SUM(duree), '999,999') AS jours_total,
    TO_CHAR(pkg_location.ca_periode(Annee, Mois), '999,999.99') || '€' AS ca
FROM Location
WHERE Annee IS NOT NULL AND Mois IS NOT NULL
GROUP BY Annee, Mois
ORDER BY Annee DESC, Mois DESC
FETCH FIRST 12 ROWS ONLY;

PROMPT ============================================================
PROMPT État du parc automobile
PROMPT ============================================================

SELECT 
    etat,
    COUNT(*) AS nombre,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) || '%' AS pourcentage,
    TO_CHAR(AVG(compteur), '999,999') AS km_moyen,
    TO_CHAR(AVG(prixJ), '999.99') || '€' AS prix_jour_moyen
FROM Voiture
GROUP BY etat
ORDER BY COUNT(*) DESC;

PROMPT ============================================================
PROMPT Propriétaires les plus actifs
PROMPT ============================================================

SELECT 
    p.CodeP,
    p.pseudo,
    p.Ville,
    COUNT(DISTINCT v.Immat) AS nb_voitures,
    COUNT(l.numLoc) AS nb_locations,
    TO_CHAR(SUM(v.prixJ * NVL(l.duree, 0)), '999,999.99') || '€' AS ca_genere
FROM Proprietaire p
LEFT JOIN Voiture v ON v.codeP = p.CodeP
LEFT JOIN Location l ON l.immat = v.immat
GROUP BY p.CodeP, p.pseudo, p.Ville
ORDER BY SUM(v.prixJ * NVL(l.duree, 0)) DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT Clients par tranche d'âge
PROMPT ============================================================

SELECT 
    CASE 
        WHEN Age < 25 THEN '18-24 ans'
        WHEN Age < 35 THEN '25-34 ans'
        WHEN Age < 45 THEN '35-44 ans'
        WHEN Age < 55 THEN '45-54 ans'
        WHEN Age < 65 THEN '55-64 ans'
        ELSE '65+ ans'
    END AS tranche_age,
    COUNT(*) AS nb_clients,
    COUNT(DISTINCT l.immat) AS nb_voitures_louees,
    ROUND(AVG(NVL(total_km.km, 0)), 0) AS km_moyen
FROM Client c
LEFT JOIN Location l ON l.codeC = c.codeC
LEFT JOIN (
    SELECT codeC, SUM(km) AS km
    FROM Location
    GROUP BY codeC
) total_km ON total_km.codeC = c.codeC
GROUP BY CASE 
    WHEN Age < 25 THEN '18-24 ans'
    WHEN Age < 35 THEN '25-34 ans'
    WHEN Age < 45 THEN '35-44 ans'
    WHEN Age < 55 THEN '45-54 ans'
    WHEN Age < 65 THEN '55-64 ans'
    ELSE '65+ ans'
END
ORDER BY MIN(Age);

PROMPT ============================================================
PROMPT Test d'une synthèse client complète
PROMPT ============================================================

DECLARE
    v_codeC NUMBER;
    v_nom VARCHAR2(50);
    v_prenom VARCHAR2(50);
    v_duree NUMBER;
    v_nbveh NUMBER;
    v_moy NUMBER;
BEGIN
    -- Sélectionner le client avec le plus de locations
    SELECT c.codeC, c.nom, c.prenom
    INTO v_codeC, v_nom, v_prenom
    FROM Client c
    JOIN Location l ON l.codeC = c.codeC
    GROUP BY c.codeC, c.nom, c.prenom
    ORDER BY COUNT(*) DESC
    FETCH FIRST 1 ROW ONLY;
    
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('FICHE CLIENT DÉTAILLÉE');
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    DBMS_OUTPUT.PUT_LINE('Client: ' || v_nom || ' ' || v_prenom || ' (Code: ' || v_codeC || ')');
    
    -- Appeler la synthèse
    synthese_client(v_codeC, v_duree, v_nbveh, v_moy);
    
    DBMS_OUTPUT.PUT_LINE('Durée totale de location: ' || v_duree || ' jours');
    DBMS_OUTPUT.PUT_LINE('Nombre de véhicules différents loués: ' || v_nbveh);
    DBMS_OUTPUT.PUT_LINE('Note moyenne: ' || NVL(TO_CHAR(v_moy, '9.99'), 'N/A'));
    DBMS_OUTPUT.PUT_LINE('Statut: ' || get_client_status(v_codeC));
    
    -- Historique des locations
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Historique des 5 dernières locations:');
    DBMS_OUTPUT.PUT_LINE('───────────────────────────────────────────────────');
    
    FOR r IN (
        SELECT l.*, v.marque, v.modele
        FROM Location l
        JOIN Voiture v ON v.immat = l.immat
        WHERE l.codeC = v_codeC
        ORDER BY l.dated DESC
        FETCH FIRST 5 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(
            '• ' || r.marque || ' ' || r.modele ||
            ' | ' || TO_CHAR(r.dated, 'DD/MM/YYYY') ||
            ' | ' || NVL(TO_CHAR(r.duree), '?') || 'j' ||
            ' | ' || NVL(TO_CHAR(r.km), '?') || 'km' ||
            ' | Note: ' || NVL(TO_CHAR(r.note), 'N/A')
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('═══════════════════════════════════════════════════');
    
END;
/

PROMPT ============================================================
PROMPT Historique récent des changements d'état
PROMPT ============================================================

SELECT 
    immat,
    etat_avant || ' → ' || etat_apres AS changement,
    TO_CHAR(changed_at, 'DD/MM/YYYY HH24:MI:SS') AS quand,
    changed_by
FROM Voiture_Etat_Histo
ORDER BY changed_at DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT ============================================================
PROMPT Voitures nécessitant une maintenance (>100000 km)
PROMPT ============================================================

SELECT 
    Immat,
    Marque || ' ' || Modele AS vehicule,
    TO_CHAR(compteur, '999,999') || ' km' AS kilometrage,
    etat,
    CASE 
        WHEN compteur > 200000 THEN '🔴 Urgent'
        WHEN compteur > 150000 THEN '🟠 Bientôt'
        ELSE '🟡 À surveiller'
    END AS priorite
FROM Voiture
WHERE compteur > 100000
ORDER BY compteur DESC;

PROMPT ============================================================
PROMPT Statistiques générales de la base
PROMPT ============================================================

SELECT 
    'Tables' AS type,
    COUNT(*) AS nombre
FROM user_tables
UNION ALL
SELECT 'Vues', COUNT(*)
FROM user_views
UNION ALL
SELECT 'Procédures', COUNT(*)
FROM user_objects WHERE object_type = 'PROCEDURE'
UNION ALL
SELECT 'Fonctions', COUNT(*)
FROM user_objects WHERE object_type = 'FUNCTION'
UNION ALL
SELECT 'Triggers', COUNT(*)
FROM user_triggers
UNION ALL
SELECT 'Packages', COUNT(*)
FROM user_objects WHERE object_type = 'PACKAGE'
UNION ALL
SELECT 'Contraintes', COUNT(*)
FROM user_constraints
UNION ALL
SELECT 'Index', COUNT(*)
FROM user_indexes;

PROMPT ============================================================
PROMPT ✅ Démonstration terminée!
PROMPT ============================================================
PROMPT 
PROMPT Le système de location est opérationnel avec:
PROMPT  ✓ Schéma complet et contraintes d'intégrité
PROMPT  ✓ Vues avec WITH CHECK OPTION
PROMPT  ✓ Gestion des droits d'accès
PROMPT  ✓ Procédures PL/SQL de notation et d'analyse
PROMPT  ✓ Triggers pour l'historique et la validation
PROMPT  ✓ Gestion de la concurrence avec SELECT FOR UPDATE
PROMPT 
PROMPT Pour l'application Python: consultez le dossier app/
PROMPT Pour les visualisations: exécutez python app/visualizations.py
PROMPT 
