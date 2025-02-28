# ZeroInteret0.1

## 1. 🚀 Introduction
*ZeroInteret0.1* est une solution bancaire numérique intégrant des fonctionnalités de gestion de comptes, de transactions et de cartes NFC. Ce document décrit son fonctionnement global et son architecture technique.

## 2. 🌍 Présentation Générale de l'Application

*ZeroInteret0.1* permet aux utilisateurs 👥 de gérer leurs finances personnelles de manière dématérialisée. L'application offre :

- **Authentification sécurisée** : Connexion via e-mail ✉️ et mot de passe 🔑 avec Supabase.
- **Gestion de compte** : Suivi du solde et des informations du compte bancaire.
- **Utilisation des cartes NFC** : Association et activation/désactivation de cartes NFC pour les paiements.
- **Historique des transactions** : Consultation des paiements et virements effectués.
- **Virements bancaires** : Envoi d’argent à d’autres utilisateurs avec validation via NFC.

## 3. 🏗️ Architecture de l'Application
L'application est conçue autour de plusieurs modules interconnectés :

### a. 👥 Gestion des Utilisateurs
- Un utilisateur possède un **profil** (`Profile.swift`) contenant son identité 🆔 et son e-mail ✉️.
- Il dispose d’un ou plusieurs **comptes bancaires** (`Account.swift`) associés à son identifiant.
- La connexion et l’authentification 🔑 sont gérées via **Supabase** (`Supabase.swift`).

### b. 💳 Gestion des Comptes et Transactions
- Chaque compte a un **solde et une devise** (`Account.swift`).
- L’utilisateur peut consulter son historique de **transactions** (`Transaction.swift`).
- Une transaction est liée à un **compte émetteur** et un **compte récepteur** (`UserTransaction.swift`).

### c. 📡 Interaction avec les Cartes NFC
- L’utilisateur peut **enregistrer et gérer ses cartes NFC** (`NFCCard.swift`).
- L’état des cartes est affiché dans une **interface dédiée** (`NFCCardView.swift`).
- L’UID des cartes est **masqué** 🔒 pour des raisons de sécurité (`String+Extensions.swift`).

### d. 🎨 Expérience Utilisateur et Interface
- **Écran de connexion** (`LoginView.swift`) permettant l’accès sécurisé 🔑 à l’application.
- **Tableau de bord utilisateur** (`ProfileView.swift`) affichant les informations du compte et les cartes NFC associées.
- **Interface de transactions** (`TransactionRow.swift`) mettant en forme les paiements et virements via un algorithme de chiffrement niveau backend et déchiffrement au niveau de la BDD.

### e. 🔐 Mécanisme de Virement Sécurisé
Le virement sécurisé dans *ZeroInteret0.1* repose sur un processus en plusieurs étapes garantissant la **confidentialité 🔏 et l'intégrité 🔍** des données.

#### 1. 🔒 Chiffrement et Envoi des Données
- Avant d’être envoyées au serveur, les informations du virement (comptes, montant, statut, carte NFC) sont **transformées en JSON**.
- Ce JSON est **chiffré en AES-256-CBC 🔑** avec une clé dérivée via SHA-256.
- Un **vecteur d’initialisation (IV)** est généré pour renforcer la sécurité 🛡️.
- Les **données chiffrées (`ciphertext`) et l’IV** sont envoyées au serveur.

#### 2. 📥 Déchiffrement et Validation sur le Serveur
- Une **fonction SQL dans Supabase** reçoit les données et utilise une **clé de déchiffrement** 🔑 pour retrouver les informations.
- La **validité des données** est vérifiée ✅ : en cas d’erreur, l’opération est stoppée ❌.
- Les **identifiants des comptes** sont convertis en UUID et les **montants** en valeurs numériques.

#### 3. 📌 Création et Enregistrement de la Transaction
- Une fois validée, la **transaction est enregistrée** avec un identifiant unique.
- Les **détails de la transaction** (expéditeur, bénéficiaire, montant) sont stockés 💾.
- Les données restent **sécurisées 🔏 et accessibles** uniquement par l’utilisateur concerné.

## 4. 🎯 Conclusion
*ZeroInteret0.1* est une **application bancaire numérique moderne** intégrant des fonctionnalités avancées comme la gestion des cartes NFC et le **chiffrement des transactions** 🔐. 

L’interconnexion entre les **comptes, transactions et authentification** garantit une **expérience fluide et sécurisée** pour l’utilisateur. Son **architecture modulaire** repose sur **SwiftUI** et **Supabase** pour offrir une **gestion optimisée des données financières**.

