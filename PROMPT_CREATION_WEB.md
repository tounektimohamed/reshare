# PROMPT COMPLET POUR RECRÉER ReShare EN APPLICATION WEB

> **Contexte :** Ce projet est une plateforme de *marketing par liens / "partage et gagne"*. Les participants partagent des campagnes publicitaires (liens), reçoivent de l'argent pour chaque clic valide, et il existe un système de parrainage.

---

## 1. IDENTITÉ DU PROJET

- **Nom :** ReShare (ريشير)
- **Slogan (arabe) :** « حوّل مشاركاتك إلى أرباح حقيقية » (Transforme tes partages en vrais gains)
- **Type :** Application Web (PWA) + responsive, orientée mobile-first
- **Langue principale :** Arabe (RTL) - une version FR/EN peut être prévue
- **Devise :** Dinar Tunisien (TND / "د")
- **Public cible :** Tunisie uniquement
- **Description :** Plateforme où les utilisateurs partagent des campagnes publicitaires et gagnent de l'argent par clic. Trois rôles : **Participant** (partage et gagne), **Entreprise/Business** (crée et paie des campagnes), **Admin** (supervision et modération).

---

## 2. STACK TECHNIQUE DEMANDÉE

- **Frontend :** React + Vite (ou Next.js pour le SEO) avec TypeScript
- **Styling :** Tailwind CSS + Material UI / shadcn (thème vert + violet, RTL arabe via rtlcss)
- **Backend :** Firebase (fondé sur l'architecture existante)
  - **Auth :** Firebase Authentication (email/mot de passe)
  - **Base de données :** Cloud Firestore
  - **Stockage fichiers :** Firebase Storage (images)
  - **Fonctions serveur :** Firebase Cloud Functions (Node.js 18)
  - **Notifications :** Firebase Cloud Messaging
  - **Hébergement :** Firebase Hosting
- **State management :** Context API ou Zustand

---

## 3. CONFIGURATION FIREBASE (TOKENS / CREDENTIALS)

### 3.1 Projet (les deux projets présents dans le code source)

Le code original référence **deux** projets Firebase différents. Pour la nouvelle web app, utiliser l'un des deux (de préférence celui avec Cloud Functions) :

**Projet A – `scoutapk`** (config principal dans `firebase_options.dart` / `.firebaserc`) :
```json
{
  "web": {
    "apiKey": "AIzaSyA4FP5olTC2MjpUPe8x-_6k91fjvyBs6xo",
    "appId": "1:387756086923:web:1e2241c4aa3f6e53c5268e",
    "messagingSenderId": "387756086923",
    "projectId": "scoutapk",
    "authDomain": "scoutapk.firebaseapp.com",
    "storageBucket": "scoutapk.firebasestorage.app"
  },
  "android": {
    "apiKey": "AIzaSyDtQkwJgPY-9JBpXzIdz3ugGc7qdqTp3HM",
    "appId": "1:387756086923:android:e57a2c216d67f0f3c5268e"
  },
  "ios": {
    "apiKey": "AIzaSyCnp9AijV78SIdYAcZmgfog0Zqk_dJi3D8",
    "appId": "1:387756086923:ios:f4bf418cbb3032b2c5268e",
    "iosClientId": "387756086923-m67vt1h74025a4vmqok7tph0g13vfmvl.apps.googleusercontent.com",
    "iosBundleId": "com.example.reshare"
  }
}
```

**Projet B – `reshare-d7d7e`** (utilisé dans `lib/main.dart` fallback + ancien `web/index.html`) :
```json
{
  "apiKey": "AIzaSyBoMBq-RE2Yt56Y27DgmSqiOwfuWl40DMk",
  "authDomain": "reshare-d7d7e.firebaseapp.com",
  "projectId": "reshare-d7d7e",
  "storageBucket": "reshare-d7d7e.firebasestorage.app",
  "messagingSenderId": "420886163575",
  "appId": "1:420886163575:web:235f5a62bacdde0c511672",
  "measurementId": "G-PHMK23YBSG"
}
```

### 3.2 Variables d'environnement à définir dans le backend (Cloud Functions)

Dans `firebase.json` et via `firebase functions:config:set` :
- `functions.config().hmac.secret` → **HMAC_SECRET** (secret pour signer les liens de tracking / clics)
- `IPINFO_TOKEN = "96ed40fbcc9b03"` → token du service ipinfo.io (géolocalisation des IP)
- `RATE_LIMIT_COUNT = 10` → max clics par fenêtre
- `RATE_LIMIT_WINDOW = 60 * 1000` (60 secondes)
- `ALLOWED_COUNTRIES = ["TN"]` → seuls les clics depuis la Tunisie sont valides

---

## 4. ARCHITECTURE ET STRUCTURE DES DOSSIERS

```
src/
├── components/          → composants réutilisables
│   ├── campaign/        → cartes, listes de campagnes
│   ├── common/          → boutons, champs, app bar, loader
│   ├── earnings/        → cartes de gains, grilles de stats
│   └── product/         → fiches produits, section sponsorisée
├── features/
│   ├── auth/            → login, register, PIN, sécurité, marketplace
│   ├── campaigns/       → gestion des campagnes (entreprise + participant)
│   ├── dashboard/       → accueil, admin, profil
│   ├── earnings/        → gains, transactions, retraits
│   └── referrals/       → programme de parrainage
├── data/
│   ├── models/          → modèles de données
│   ├── repositories/    → couche d'accès aux données
│   └── datasources/     → Firebase / localStorage
├── core/
│   ├── constants/       → couleurs, chaînes, constantes
│   ├── services/        → firebase, cloud functions, notifications, etc.
│   └── utils/           → formatters, validateurs
└── themes/              → palettes de couleurs, thèmes clair/sombre
```

---

## 5. MODÈLES DE DONNÉES (COLLECTIONS FIRESTORE)

### 5.1 Collection `users` — Champ du document utilisateur

- `id` (string)
- `email` (string)
- `displayName` (string)
- `phoneNumber` (string?)
- `totalEarnings` (double)
- `availableBalance` (double)
- `pendingBalance` (double)
- `totalClicks` (int)
- `totalShares` (int)
- `referralCount` (int)
- `userType` (enum stocké en int) : `0=participant`, `1=business`, `2=admin`
- `createdAt` (timestamp ISO)
- `lastLogin` (timestamp ISO?)
- `locationPreference` (enum int) : `0=open`, `1=regional`, `2=precise`
- `referralCode` (string?)
- `companyName` (string?) — pour les entreprises
- `taxNumber` (string?) — numéro fiscal entreprise
- `isVerified` (bool)
- `preferredCategories` (array<string>?)

➡️ **Règles métier :** le parser gère en toute robustesse les valeurs en string OU int. `totalEarnings`, `availableBalance`, `pendingBalance`, `totalClicks`, `totalShares`, `referralCount` doivent être incrémentés correctement.

### 5.2 Collection `campaigns` — Campagnes publicitaires

Champs complets :
- `id`, `businessId`, `advertiserId`
- `title`, `description`
- `targetUrl` (le lien que les participants partagent)
- `type` (enum int) : `0=open`, `1=regional`, `2=precise`
- `status` (enum int) : `0=pending`, `1=approved`, `2=active`, `3=paused`, `4=completed`, `5=rejected`
- `budget` (double) — budget total en TND
- `spent` (double)
- `cpc` (double) — coût par clic en TND
- `targetClicks` (int) — objectif de clics
- `achievedClicks` (int)
- `uniqueClicks` (int)
- `targetRegions` (array<string>?)
- `targetLocation` (map : `{latitude, longitude, address}`?)
- `targetRadius` (double, défaut 5.0 km)
- `createdAt`, `startDate?`, `endDate?`
- `imageUrl?`, `imageExtension?`, `imagePath?`
- `isActive` (bool)
- `maxClicksPerUser` (int, défaut 3)
- `conversionRate` (double), `conversions` (int)
- `campaignType` (string) : `'ads'` (publicité normale) ou `'marketplace'` (sous Marketplace)
- `marketplaceFee` (double), `totalDeduction` (double)

**Calculs clés :**
- `remainingClicks = targetClicks - achievedClicks`
- `remainingBudget = budget - spent`
- `participantEarnings = cpc * 0.6` (60% au participant)
- `platformEarnings = cpc * 0.4` (40% à la plateforme)
- `totalCost = cpc * targetClicks`
- `isBudgetSufficient = totalCost <= budget`
- `completionRate = (achievedClicks / targetClicks) * 100`

### 5.3 Collection `clicks` — Clics des utilisateurs

- `id`, `campaignId`, `shareId`, `userId`, `participantId`
- `campaignTitle`
- `earnings` (double), `platformEarnings` (double), `totalEarnings` (double)
- `status` (enum int) : `0=valid`, `1=pending`, `2=suspicious`, `3=invalid`, `4=fraud`
- `clickedAt` (timestamp)
- `ip`, `userAgent`, `referrer`, `deviceHash`
- `processed` (bool)

### 5.4 Collection `referrals` — Parrainage

- `id`, `referrerId`, `newUserId`, `referralCode`
- `rewardAmount` (double), `status` (enum) : `0=pending`, `1=completed`, `2=paid`, `3=expired`, `4=cancelled`
- `newUserClicks` (int), `clicksRequired` (int, défaut 10)
- `createdAt`, `completedAt?`, `paidAt?`
- Calcul : `isCompleted = newUserClicks >= clicksRequired`

### 5.5 Collection `transactions` — Historique financier

- `id`, `userId`, `type` (enum) : `0=earning`, `1=referral`, `2=withdrawal`, `3=refund`, `4=bonus`
- `amount`, `currency` (défaut `'TND'`), `status` (enum) : `0=pending`, `1=processing`, `2=completed`, `3=failed`, `4=cancelled`
- `description?`, `reference?`, `fees?`, `netAmount?`, `paymentMethod?`
- `createdAt`, `processedAt?`

### 5.6 Autres collections utilisées

- `shares` — enregistre les partages d'un participant (shareId référencé dans clicks)
- `fraud_patterns` — patterns de fraude détectés
- `notifications` — notifications utilisateur
- `payments` + `test_payments` — paiements / simulation
- `withdrawals` — demandes de retrait
- `products` / `sponsoring_orders` / `product_interactions` / `campaignShares` / `invitations` / `businesses` — fonctionnalités secondaires (Marketplace, sponsoring)

---

## 6. RÔLES UTILISATEURS ET ACCÈS

| Rôle | `userType` | Onglets | Autorisations |
|------|-----------|---------|---------------|
| **Participant** | `participant` (2) | Accueil, Campagnes, Gains, Parrainage, Profil | Partager des campagnes, gagner des clics, retirer ses gains, parrainer |
| **Entreprise** | `business` (1) | Tableau de bord entreprise, Campagnes, Gains, Profil | Créer/gérer des campagnes, définir budget + CPC, voir les stats |
| **Admin** | `admin` (0) | Admin dashboard, Gestion campagnes, Rapports, Profil | Approuver/rejeter campagnes, valider clics, gérer fraude/retraits |

**Flux d'écrans par rôle :**
- **Participant :** `HomeScreen` → `CampaignsScreen` → `EarningsScreen` → `ReferralsScreen` → `ProfileScreen`
- **Entreprise :** `CompanyDashboardScreen` → `CampaignsScreen` → `EarningsScreen` → `ProfileScreen`
- **Admin :** `AdminHomeScreen` → `CampaignsScreen` → `EarningsScreen` → `ProfileScreen`

---

## 7. FLUX UTILISATEUR (NAVIGATION COMPLÈTE)

### 7.1 Démarrage / Sécurité (critique)
1. Chargement → **SplashScreen** (logo partage, écran vert).
2. Vérification d'authentification via Firebase Auth (`checkAuthStatus`).
3. Si **non authentifié** → `LoginScreen`.
4. Si **authentifié** → vérifier si l'utilisateur a un **PIN activé** :
   - Si PIN activé → afficher `PinScreen` (saisie du code PIN) avant d'accéder au dashboard.
   - Si PIN désactivé (ou biometrie non disponible) → accès direct au dashboard.
5. Boutons déconnexion → reset de la sécurité + retour au login.

### 7.2 Authentification
- **LoginScreen :** email + mot de passe, lien "mot de passe oublié" (envoi d'email de reset), bouton création de compte.
- **RegisterScreen :** nom complet, email, mot de passe, confirmation, téléphone (optionnel), **code de parrainage** (optionnel), choix du type de compte. Possibilité de créer aussi un **compte entreprise** (nom société + numéro fiscal).
- Après inscription : envoi d'un email de vérification + notification de bienvenue.

### 7.3 Accueil Participant (`HomeScreen`)
- Salutation ("صباح الخير/مساء الخير") fonction de l'heure.
- Bannière **Marketplace** ("سوق الحملات 🛍️") → navigation vers la Marketplace.
- **Statistiques rapides :** solde disponible, montant en attente, total gains (en د).
- **Aperçu des gains :** solde disponible / en attente / total + stats hebdomadaires + grid de stats.
- **Campagnes recommandées** (carrousel horizontal).
- **Campagnes disponibles** (liste - max 3 affichées).
- **Activité récente** (5 derniers clics avec statut et gains).
- **Actions rapides :** Campagnes, Marketplace, Gains.
- Bouton flottant "سوق الحملات".

### 7.4 Marketplace (`MarketplaceScreen`)
- Catalogue de campagnes du type `campaignType = 'marketplace'`.
- Une campagne est caractérisée par : `isFeatured`, `rating` (note), `totalShares`, `advertiserName`, `advertiserLogo`, `tags`, `featuredUntil`.
- Badges dynamiques : "مميزة" (featured), "رائجة" (trending si >100 partages), "شائعة" (populaire si note ≥4.0), "جديدة" (nouvelle si <7 jours).
- FAB / bannière violette pointée vers cette section.

### 7.5 Campagnes
- **CampaignsScreen :** liste des campagnes disponibles pour le participant ; pour entreprise/admin : liste + création.
- **Création campagne (avec image)** : titre, description, URL cible, type (ouverture/régionale/précise), budget, CPC, clics cibles, image uploadée (avec `imageExtension`/`imagePath` → `imageMimeType`), `campaignType` (ads/marketplace), `marketplaceFee`.
- **CampaignDetailsScreen :** détails d'une campagne.
- **DashboardEntreprise (CompanyDashboardScreen) :** vue entreprise — statistiques de campagnes (clics, budget dépensé, conversions), création de campagnes, graphiques (syncfusion_charts).
- **AdminHomeScreen (ADHomeScreen) :** modération — approuver/rejeter les campagnes, valider/refuser les clics (`approveClick`, `rejectClick`, `updateClickStatus`), stats de fraude, gestion des retraits.

### 7.6 Gains (Earnings)
- **EarningsScreen :** récapitulatif des gains (total, disponible, en attente), graphique des gains.
- **TransactionsScreen :** historique des transactions (earning, referral, withdrawal, refund, bonus).
- **WithdrawalScreen :** demande de retrait du solde disponible (devise TND, montant minimum défini), enregistre une demande dans `withdrawals` + transaction `type=withdrawal`.

### 7.7 Parrainage (Referrals)
- **ReferralsScreen :** affiche le code de parrainage de l'utilisateur, bouton de partage (share_plus / url_launcher), liste des filleuls, progression (`newUserClicks` / `clicksRequired`), récompenses.
- Lien d'invitation : `https://<domaine>/register?ref=<code>` → redirige vers page d'inscription avec le code pré-rempli.

---

## 8. LOGIQUE BACKEND (CLOUD FUNCTIONS) — À REPRODUIRE

> Chaque fonction doit être recréée avec la même logique. Toutes les `onCall` vérifient `context.auth` (authentification) sauf indication contraire.

### 8.1 Tableau de bord & stats
- **`getDashboardData`** : renvoie `{ success, stats: { totalEarnings, availableBalance, pendingBalance, totalClicks, totalShares, referralCount, weeklyEarnings, weeklyClicks, weeklyGrowth }, recentClicks (5 derniers) }`. Calcule les stats de la semaine (7 derniers jours) à partir des clics `status=valid`.
- **`getUserStats`** : stats globales de l'utilisateur.
- **`getReferralStats`** : stats de parrainage.
- **`getPlatformEarnings`** : gains de la plateforme (part 40%).

### 8.2 Campagnes
- **`getAvailableCampaigns`** : liste des campagnes `active` pour le participant (avec tri/recommandations).
- **`getRecommendedCampaigns`** : campagnes recommandées (algorithmes de recommandation basés sur `preferredCategories`, stats, etc.).
- **`getBusinessCampaigns`** : campagnes appartenant à une entreprise (par `businessId`/`advertiserId`).
- **`getCampaignAnalytics`** : analytics détaillés d'une campagne (clics par région, par appareil, conversions via `CampaignStats`).
- **`createCampaignIntent`** : créer une intention de campagne (vérifie `isBudgetSufficient`, `remainingBudget`, `remainingClicks`).
- **`createCampaignDirect`** : création directe d'une campagne (débite le budget de l'utilisateur, crée le doc `campaigns`).
- **`fixCampaignStatuses`**, **`fixCampaignsAchievedClicks`**, **`fixCampaignData`** : fonctions de réparation des données (clics/accomplis, statuts).
- **`createTestCampaign`** / **`createTestCampaigns`** / **`createCleanTestData`** / **`resetTestCampaigns`** : création de données de test.

### 8.3 Clics & anti-fraude (cœur du système)
- **`generateTrackingLink`** (onCall) : génère un lien de tracking signé (HMAC) pour une campagne.
- **`clickHandler`** (onRequest HTTP) : **point d'entrée du clic** — le participant partage ce lien. Chaque clic :
  1. Récupère l'IP et la géolocalise via ipinfo.io (token `96ed40fbcc9b03`).
  2. **Vérifie le pays** : si IP hors `ALLOWED_COUNTRIES=["TN"]` → clic invalide/frauduleux.
  3. **Rate-limiting** : max `RATE_LIMIT_COUNT` (10) clics par `RATE_LIMIT_WINDOW` (60s) par IP.
  4. **Vérifie le deviceHash** : clics multiples depuis le même device → suspect.
  5. **Vérifie `maxClicksPerUser`** par campagne.
  6. **Vérifie la validité du HMAC** du lien de tracking.
  7. Enregistre le clic dans `clicks` avec un statut (`valid`/`pending`/`suspicious`/`invalid`/`fraud`), `ip`, `userAgent`, `referrer`, `deviceHash`.
  8. Redirige l'utilisateur vers `targetUrl`.
- **`is valid click` → crédite** : `earnings = cpc * 0.6` au participant, `platformEarnings = cpc * 0.4`, incrémente `achievedClicks`, `spent`, crée une transaction `earning`, met à jour le solde de l'utilisateur.
- **`approveClick`** / **`rejectClick`** / **`updateClickStatus`** (onCall) : un admin valide ou rejette les clics suspendus (`suspicious`).
- **`getPendingClicks`** : liste les clics en attente de validation par l'admin.
- **`cleanupSuspiciousClicks`** (pubsub, toutes les 24h) : purge des clics suspects.

### 8.4 Statistiques de fraude
- **`getFraudDetectionStats`** : stats globales de fraude.
- **`getFraudReports`** : rapports de fraude détaillés.

### 8.5 Parrainage
- **`processReferral`** (onCall) : lie un nouveau compte à son parrain via `referralCode`. Le parrainage se valide quand `newUserClicks >= clicksRequired` (10) → `rewardAmount` créditée.
- **`createWithdrawal`** (onCall) : demande de retrait — vérifie `availableBalance >= montant` + minimum, crée le retrait dans `withdrawals`, crée transaction `withdrawal`, met à jour les soldes.

### 8.6 Paiements
- **`simulatePayment`** : simulation de paiement de campagne (crédite le budget / débite l'utilisateur).
- **`paymentWebhook`** (onRequest) : webhook de confirmation de paiement — vérifie la signature, traite la transaction.
- **`updateUserBalance`** : met à jour le solde d'un utilisateur.

### 8.7 Notifications & util
- **`sendUserNotification`** : envoie une notification à un utilisateur (enregistre dans `notifications`, envoie push via FCM).
- **`deactivateExpiredCampaigns`** (pubsub, toutes les heures) : désactive les campagnes dont `endDate` est dépassé / `remainingClicks <= 0`.
- **`repairUserData`** : répare les données corrompues d'un utilisateur.
- **`testFunction`** : fonction de test.

---

## 9. RÈGLES DE CALCUL DES GAINS (IMPORTANT)

- **Participant** reçoit **60%** du CPC : `participantEarnings = cpc * 0.6`
- **Plateforme** garde **40%** : `platformEarnings = cpc * 0.4`
- Devise **TND**, souvent affichée avec 3 décimales (ex : `0.100 د`).
- **Balance utilisateur :** `availableBalance` (retirable), `pendingBalance` (en validation), `totalEarnings` (cumul).
- Objectif quotidien affiché à l'accueil : **5 clics/jour**.

---

## 10. THÈME / DESIGN SYSTEM

### 10.1 Couleurs (palette complète)
- **Primaire (vert) :** `#2E7D32` (+ teintes 50-900 : `#E8F5E8` → `#1B5E20`)
- **Secondaire (bleu) :** `#2196F3` (+ teintes `#E3F2FD` → `#0D47A1`)
- **Accent (orange/or) :** `#FFC107` (+ teintes `#FFF8E1` → `#FF6F00`)
- **Succès :** vert `#388E3C` | **Warning :** orange `#FFA000` | **Erreur :** rouge `#D32F2F` | **Info :** bleu `#1976D2`
- **Neutres :** background `#F5F5F5`, surface `#FFFFFF`, outline `#E0E0E0`, textPrimary `#212121`, textSecondary `#757575`
- **Campagnes :** open=`#2196F3`, regional=`#FF9800`, precise=`#4CAF50`
- **Gains :** haut=`#FFC107`, moyen=`#4CAF50`, bas=`#2196F3`
- **Parrainage :** primaire=`#9C27B0` (violet), récompense=`#E91E63` (rose)
- **Marketplace :** violet + bleu (gradient `#9333ea` → `#2563eb`)
- **Social :** FB=`#1877F2`, Twitter=`#1DA1F2`, WhatsApp=`#25D366`, Instagram=`#E4405F`, Telegram=`#0088CC`

### 10.2 Typographie
- Police principale : **Tajawal** (optimisée pour l'arabe)
- Tailles : headlineLarge=24pt bold, headlineMedium=20pt, bodyLarge=16pt, bodyMedium=14pt

### 10.3 Composants UI
- Boutons : coins arrondis (rayon 12), vert primaire, texte blanc, padding vertical 16px.
- Champs : bordure rayon 12, focus vert, fond `#FAFAFA`.
- Cartes : elevation 2, rayon 16, margin 8.
- **Clair + Sombre** (défaut clair).
- Les montants sont affichés avec le symbole **د** (dinar) ou format `0.100`.
- RTL (lecture droite → gauche).

---

## 11. PAGES WEB PUBLIQUES (LANDING) À CRÉER

### 11.1 Page d'accueil publique (`/`)
- Design : gradient violet (`#667eea` → `#764ba2`), glassmorphism, centré, RTL arabe.
- Logo, nom ReShare, slogan.
- Boutons : "إنشاء حساب جديد" (créer un compte) et "📱 فتح التطبيق" (ouvrir l'app).
- **Redirection intelligente** : si `?route=register` ou `?screen=register` ou `?referralCode=` / `?ref=` → rediriger vers `/register?ref=<code>`.

### 11.2 Page d'inscription publique (`/register`)
- Formulaire complet : nom, email, mot de passe, confirmation, téléphone (optionnel), **code de parrainage** (pré-rempli via `?ref=`).
- Badge de parrainage mis en avant quand un code est présent.
- Création de compte via Firebase Auth + création du document `users`.
- Traitement du parrainage si code présent (`processReferral`).

### 11.3 Règles de réécriture Firebase Hosting (`firebase.json`)
- `/click` → fonction `clickHandler`
- `/register`, `/register/**`, `/invite`, `/ref/**`, `/signup`, `/join` → `/register/index.html`
- `**` → `/index.html`
- Headers : X-Frame-Options DENY, X-Content-Type-Options nosniff ; cache no-store sur `/register/**`.

---

## 12. FONCTIONNALITÉS PWA / WEB

- Manifest avec icônes (icons: `web/manifest.json`, `favicon.png`, `icons/Icon-192.png`).
- Description meta : "ReShare - منصة التسويق بالعمولة".
- Requis pour mobile : formulaire responsive, défilement pull-to-refresh (mobile descend).
- Notifications push via Firebase Cloud Messaging.

---

## 13. LISTE DE CONTRÔLE FINALE (CHECKLIST DE LIVRAISON)

- [ ] Setup React/Vite + TypeScript + Tailwind avec support RTL arabe
- [ ] Init Firebase SDK (Auth, Firestore, Storage, Functions, Messaging)
- [ ] Auth : login (email+mot de passe), register (avec rôle + code parrainage), reset password, vérification email, logout
- [ ] Sécurité par PIN (optionnel, activate/désactiver depuis les réglages)
- [ ] 3 rôles avec navigation et accès conditionnels
- [ ] Page accueil participant (stats, gains, campagnes, activité, marketplace)
- [ ] Module Campagnes (liste, création avec image, détails, gestion entreprise, modération admin)
- [ ] Module Gains (récap, graphique via chart lib, transactions, retrait)
- [ ] Module Parrainage (code + lien partage + liste filleuls + progression)
- [ ] Module Marketplace (catalogue avec badges)
- [ ] Admin : gestion campagnes (approuver/rejeter), validation clics, stats fraude, rapports
- [ ] Cloud Functions recréées avec la logique anti-fraude (pays TN, HMAC, rate-limit, deviceHash, maxClicksPerUser)
- [ ] Système de tracking de clics signé (+ redirection vers targetUrl)
- [ ] Gambling des gains : 60% participant / 40% plateforme, soldes available/pending/total
- [ ] Système de retrait (TND) avec montant minimum
- [ ] Notifications (enregistrement + push)
- [ ] Tâches programmées (cleanup clics suspects / désactivation campagnes expirées)
- [ ] Pages publiques landing + inscription (RTL, gradient violet, redirection par code)
- [ ] firebase.json (hosting rewrites + functions) + variables de config (HMAC secret, ipinfo token)
- [ ] Thème clair/sombre vert + violet + police Tajawal
- [ ] Déploiement Firebase Hosting

---

## 14. NOTES DE SÉCURITÉ IMPORTANTES

- La logique anti-fraude côté clic est **critique** : vérifier le pays (TN uniquement), le deviceHash, le limiteur de débit, et le HMAC du lien de tracking. Ne jamais créditer un clic qui échoue à ces contrôles.
- Ne jamais exposer réellement `functions.config().hmac.secret` ni le `IPINFO_TOKEN` côté client — ils sont uniquement côté Cloud Functions.
- Le portefeuille `availableBalance`/`pendingBalance` doit être géré de façon transactionnelle (éviter les doubles crédits).
- Vérifier `context.auth` sur toutes les `onCall` sensibles.
```

---

> ⚠️ **Note importante de sécurité :** les tokens Firebase stockés dans ce document (apiKey, appId, etc.) sont publics par nature (ils sont embarqués côté client dans toute app Firebase/Flutter). En revanche, le **HMAC_SECRET**, le **IPINFO_TOKEN**, et les secrets de Cloud Functions sont confidentiels — ils ne doivent **jamais** être inclus côté client ni dans un repo public. Je vous recommande de révoquer/renouveler votre **token GitHub personnel** que vous avez partagé au début de la session.
