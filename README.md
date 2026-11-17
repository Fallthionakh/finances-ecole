# Finances – École de Formation

Application web de gestion financière d'une école de formation (FCFA), multi-établissements,
avec base de données en ligne (Supabase) et comptes utilisateurs.

## Fonctionnalités
- Plusieurs établissements (logo, en-tête, pied de page, couleur, sigle des reçus)
- Formations : inscription + mensualité × nombre de mois ; apprenants avec échéancier
- Encaissements avec reçus numérotés (PDF en double exemplaire), dépenses par catégorie
- Tableau de bord, rapports financiers, journal de caisse, exports PDF / CSV / JSON
- Comptes utilisateurs et rôles : Administrateur, Caissier, Lecteur

## Fichiers
- `index.html` : l'application
- `config.js` : adresse et clé publique de la base Supabase
- `lib/` : jsPDF, jsPDF-AutoTable, supabase-js
- `supabase.sql` : structure de la base (déjà appliquée au projet), pour référence

## Premier démarrage
1. Ouvrir l'adresse GitHub Pages, cliquer « Créer un compte ».
2. Le **premier compte** créé devient automatiquement **Administrateur**.
3. Les comptes suivants sont « En attente » : l'administrateur leur attribue un rôle
   dans Paramètres → Utilisateurs.
4. Pour reprendre des données existantes : Paramètres → Importer une sauvegarde (JSON).

## Sécurité
Les règles d'accès sont dans la base (Row Level Security) :
lecture réservée aux rôles admin/caissier/lecteur, écriture aux admin/caissier,
établissements et utilisateurs gérés par les administrateurs uniquement.
