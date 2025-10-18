const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// ✅ CONFIG
const IPINFO_TOKEN = "96ed40fbcc9b03";
const HMAC_SECRET = functions.config().hmac.secret;
const RATE_LIMIT_COUNT = 10;
const RATE_LIMIT_WINDOW = 60 * 1000;

// 🌍 الدول المسموحة
const ALLOWED_COUNTRIES = ["TN"];



// ============ FONCTIONS DE BASE POUR LE DASHBOARD ============

/**
 * Récupérer les données du tableau de bord utilisateur
 */exports.getDashboardData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;

  try {
    // 🧾 Récupérer les données utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'المستخدم غير موجود');
    }

    const userData = userDoc.data();

    // 🕒 Calculer les statistiques de la semaine
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

    const weeklyClicksQuery = await db.collection('clicks')
      .where('userId', '==', userId)
      .where('clickedAt', '>=', oneWeekAgo)
      .where('status', '==', 'valid')
      .get();

    const weeklyEarnings = weeklyClicksQuery.docs.reduce((total, doc) => {
      return total + (doc.data().earnings || 0);
    }, 0);

    // 🔹 Récupérer tous les clics (sans orderBy)
    const recentClicksSnapshot = await db.collection('clicks')
      .where('userId', '==', userId)
      .get();

    // 🧠 Transformer + trier localement par clickedAt (desc)
    let recentClicks = recentClicksSnapshot.docs
      .map(doc => ({
        id: doc.id,
        ...doc.data(),
      }))
      .filter(c => c.clickedAt) // ignorer si pas de date
      .sort((a, b) => {
        const aDate = a.clickedAt?.toDate ? a.clickedAt.toDate() : new Date(0);
        const bDate = b.clickedAt?.toDate ? b.clickedAt.toDate() : new Date(0);
        return bDate - aDate; // plus récents d'abord
      })
      .slice(0, 5); // 🔽 Limiter à 5 résultats

    // 📊 Renvoyer les statistiques
    return {
      success: true,
      stats: {
        totalEarnings: userData.totalEarnings || 0,
        availableBalance: userData.availableBalance || 0,
        pendingBalance: userData.pendingBalance || 0,
        totalClicks: userData.totalClicks || 0,
        totalShares: userData.totalShares || 0,
        referralCount: userData.referralCount || 0,
        weeklyEarnings,
        weeklyClicks: weeklyClicksQuery.size,
        weeklyGrowth: 12.5 // (statistique fixe pour l’instant)
      },
      recentClicks,
    };

  } catch (error) {
    console.error('Error getting dashboard data:', error);

    // 🧩 Données de démonstration en cas d'erreur
    return {
      success: true,
      stats: {
        totalEarnings: 45.50,
        availableBalance: 25.75,
        pendingBalance: 19.75,
        totalClicks: 155,
        totalShares: 89,
        referralCount: 12,
        weeklyEarnings: 8.25,
        weeklyClicks: 32,
        weeklyGrowth: 12.5,
      },
      recentClicks: [
        {
          id: 'demo_1',
          campaignId: 'camp_1',
          campaignTitle: 'حملة تجريبية',
          earnings: 0.1,
          status: 'valid',
          clickedAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // منذ ساعتين
        }
      ],
      usingDemoData: true
    };
  }
});

async function detectFraud(req, campaignId, userId) {
  const ip = (req.ip || "").replace("::ffff:", "");
  const ua = req.get("user-agent") || "";

  if (!ua || ua.length < 10) {
    return { reason: "User-Agent vide ou invalide" };
  }

  // 🔸 رفض النقرات المتكررة بسرعة
  const recentClicks = await admin.firestore()
    .collection("clicks")
    .where("ip", "==", ip)
    .where("userId", "==", userId)
    .orderBy("clickedAt", "desc")
    .limit(1)
    .get();

  if (!recentClicks.empty) {
    const lastClick = recentClicks.docs[0].data();
    const lastTime = lastClick.clickedAt.toDate().getTime();
    if (Date.now() - lastTime < 10 * 1000) {
      return { reason: "Click répété trop vite" };
    }
  }

  // 🔸 ipinfo للتحقق من مصدر الـ IP والدولة
  try {
    const res = await fetch(`https://ipinfo.io/${ip}?token=${IPINFO_TOKEN}`);
    const info = await res.json();
    const org = (info.org || "").toLowerCase();

    // كشف VPN ومراكز البيانات
    if (/(amazon|google|facebook|microsoft|digitalocean|cloudflare|vpn|proxy)/.test(org)) {
      return { reason: "VPN ou datacenter détecté" };
    }

    // 🔥 التحقق من الدولة - تمت إضافة تونس
    if (info.country && !ALLOWED_COUNTRIES.includes(info.country)) {
      return { reason: `Pays non autorisé: ${info.country}` };
    }

  } catch (err) {
    console.warn("Erreur ipinfo", err);
  }

  // 🔸 referer check - أكثر مرونة
  const ref = req.get("referer") || "";
  if (ref && /(spam|fake|scam|malware)/i.test(ref)) {
    return { reason: "Référer suspect" };
  }

  // 🔸 détecter navigateurs headless
  if (/headless|selenium|puppeteer|phantomjs/i.test(ua)) {
    return { reason: "Navigateur automatisé détecté" };
  }

  return null;
}

// 🌐 دالة مشتركة لتحليل IP
async function getIPInfo(ip) {
  try {
    const response = await fetch(`https://ipinfo.io/${ip}?token=${IPINFO_TOKEN}`);
    return await response.json();
  } catch (error) {
    console.error("❌ Erreur ipinfo:", error);
    return null;
  }
}
/**
 * Récupérer les campagnes recommandées
 *//**
/**
* Récupérer les statistiques de parrainage - NOUVELLE FONCTION
*/
exports.getReferralStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;

  try {
    // Récupérer les données utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    // Récupérer les parrainages de l'utilisateur
    const referralsQuery = await db.collection('referrals')
      .where('referrerId', '==', userId)
      .get();

    const referrals = referralsQuery.docs.map(doc => doc.data());

    const completedReferrals = referrals.filter(ref => ref.status === 'completed');
    const pendingReferrals = referrals.filter(ref => ref.status === 'pending');
    const totalRewards = completedReferrals.reduce((sum, ref) => sum + (ref.rewardAmount || 0), 0);

    return {
      success: true,
      stats: {
        totalReferrals: referrals.length,
        completedReferrals: completedReferrals.length,
        pendingReferrals: pendingReferrals.length,
        totalRewards: totalRewards,
        referralCode: userData.referralCode || 'N/A'
      },
      referrals: referrals.slice(0, 10) // Derniers 10 parrainages
    };

  } catch (error) {
    console.error('Error getting referral stats:', error);

    // Données de démonstration
    return {
      success: true,
      stats: {
        totalReferrals: 5,
        completedReferrals: 3,
        pendingReferrals: 2,
        totalRewards: 1.8,
        referralCode: 'SHARE123'
      },
      usingDemoData: true
    };
  }
});
/**
 * Réparer les données utilisateur corrompues
 */
exports.repairUserData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const userId = context.auth.uid;

  try {
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'المستخدم غير موجود');
    }

    const userData = userDoc.data();

    // Normaliser les champs problématiques
    const repairedData = {
      ...userData,
      userType: _normalizeUserType(userData.userType),
      locationPreference: _normalizeLocationPreference(userData.locationPreference),
      totalEarnings: Number(userData.totalEarnings) || 0,
      availableBalance: Number(userData.availableBalance) || 0,
      pendingBalance: Number(userData.pendingBalance) || 0,
      totalClicks: Number(userData.totalClicks) || 0,
      totalShares: Number(userData.totalShares) || 0,
      referralCount: Number(userData.referralCount) || 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    await userDoc.ref.set(repairedData, { merge: true });

    return {
      success: true,
      message: 'تم إصلاح بيانات المستخدم بنجاح',
      repairedFields: Object.keys(repairedData)
    };

  } catch (error) {
    console.error('Error repairing user data:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إصلاح بيانات المستخدم');
  }
});

function _normalizeUserType(userType) {
  if (typeof userType === 'number') return userType;
  if (typeof userType === 'string') {
    switch (userType.toLowerCase()) {
      case 'admin': return 0;
      case 'business': return 1;
      case 'participant': return 2;
      default: return 2;
    }
  }
  return 2; // participant par défaut
}

function _normalizeLocationPreference(preference) {
  if (typeof preference === 'number') return preference;
  if (typeof preference === 'string') {
    switch (preference.toLowerCase()) {
      case 'regional': return 1;
      case 'precise': return 2;
      case 'open': return 0;
      default: return 0;
    }
  }
  return 0; // open par défaut
}
/**
 * Corriger les statuts de campagne pour qu'ils soient cohérents
 */
exports.fixCampaignStatuses = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  try {
    const campaignsSnapshot = await db.collection('campaigns').get();
    let fixedCount = 0;

    const batch = db.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();

    campaignsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const updates = {};

      // Normaliser le statut
      if (data.status === 'active') {
        updates.status = 'active'; // Garder en string pour la compatibilité
        updates.statusIndex = 2; // Ajouter un index pour les requêtes numériques
      } else if (data.status === 'pending') {
        updates.status = 'pending';
        updates.statusIndex = 0;
      } else if (data.status === 'completed') {
        updates.status = 'completed';
        updates.statusIndex = 4;
      }

      // Normaliser le type si nécessaire
      if (typeof data.type === 'string') {
        switch (data.type) {
          case 'open': updates.type = 0; break;
          case 'regional': updates.type = 1; break;
          case 'precise': updates.type = 2; break;
          default: updates.type = 0;
        }
      }

      if (Object.keys(updates).length > 0) {
        updates.fixedAt = now;
        batch.update(doc.ref, updates);
        fixedCount++;
      }
    });

    if (fixedCount > 0) {
      await batch.commit();
    }

    return {
      success: true,
      message: `تم إصلاح ${fixedCount} حملة`,
      fixedCount: fixedCount
    };

  } catch (error) {
    console.error('Error fixing campaign statuses:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إصلاح حالات الحملات');
  }
});
/**
 * Récupérer les campagnes recommandées - VERSION COMPLÈTEMENT CORRIGÉE
 */
exports.getRecommendedCampaigns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;
  const limit = parseInt(data.limit) || 5;

  try {
    console.log(`🔍 Fetching recommended campaigns for user: ${userId}`);

    // Récupérer les campagnes actives
    const campaignsSnapshot = await db.collection('campaigns')
      .where('isActive', '==', true)
      .where('status', '==', 'active')
      .limit(limit)
      .get();

    console.log(`📊 Found ${campaignsSnapshot.size} active campaigns`);

    const campaigns = [];

    for (const doc of campaignsSnapshot.docs) {
      const rawData = doc.data();

      // ✅ Correction automatique du statut numérique vers texte
      const status = rawData.status;
      if (status === 2 && !rawData.statusText) {
        rawData.statusText = 'active';
      }

      console.log(`📝 Processing campaign: ${rawData.title}`, rawData);

      // Vérifier si l'utilisateur a déjà cliqué
      const clickQuery = await db.collection('clicks')
        .where('campaignId', '==', doc.id)
        .where('userId', '==', userId)
        .limit(1)
        .get();

      const hasClicked = !clickQuery.empty;

      if (!hasClicked) {
        // 🔥 CORRECTION: Convertir explicitement tous les types
        const safeCampaign = {
          // Identifiant
          id: String(doc.id),

          // Informations de base
          title: String(rawData.title || 'بدون عنوان'),
          description: String(rawData.description || 'لا يوجد وصف'),
          targetUrl: String(rawData.targetUrl || 'https://example.com'),

          // Types - conversion explicite
          type: _convertCampaignType(rawData.type),
          status: String(rawData.status || 'active'),

          // Données financières - conversion en nombres
          budget: Number(rawData.budget) || 0,
          spent: Number(rawData.spent) || 0,
          cpc: Number(rawData.cpc) || 0.06,

          // Statistiques - conversion en nombres
          targetClicks: Number(rawData.targetClicks) || 0,
          achievedClicks: Number(rawData.achievedClicks) || 0,
          uniqueClicks: Number(rawData.uniqueClicks) || 0,

          // Flags - conversion en booléens
          isActive: Boolean(rawData.isActive),

          // Limitations
          maxClicksPerUser: Number(rawData.maxClicksPerUser) || 3,
          conversionRate: Number(rawData.conversionRate) || 0,
          conversions: Number(rawData.conversions) || 0,

          // Champs calculés
          remainingClicks: Math.max(0, (Number(rawData.targetClicks) || 0) - (Number(rawData.achievedClicks) || 0)),
          remainingBudget: Math.max(0, (Number(rawData.budget) || 0) - (Number(rawData.spent) || 0)),
          participantEarnings: (Number(rawData.cpc) || 0) * 0.6,

          // Dates sérialisées
          createdAt: _serializeDate(rawData.createdAt),
          startDate: _serializeDate(rawData.startDate),
          endDate: _serializeDate(rawData.endDate),

          // Optionnel
          imageUrl: rawData.imageUrl || null,
          advertiserId: rawData.advertiserId || 'unknown'
        };

        console.log(`✅ Safe campaign:`, safeCampaign);
        campaigns.push(safeCampaign);
      } else {
        console.log(`⏩ User already clicked on campaign: ${rawData.title}`);
      }
    }

    console.log(`🎯 Returning ${campaigns.length} recommended campaigns`);

    return {
      success: true,
      campaigns: campaigns,
      count: campaigns.length,
      hasMore: campaigns.length === limit
    };

  } catch (error) {
    console.error('❌ Error in getRecommendedCampaigns:', error);

    // 🔥 Données de démonstration avec types corrects
    const demoCampaigns = _getDemoCampaigns(limit);

    return {
      success: true,
      campaigns: demoCampaigns,
      count: demoCampaigns.length,
      hasMore: false,
      usingDemoData: true,
      error: error.message
    };
  }
});

/**
 * Récupérer les statistiques utilisateur - VERSION CORRIGÉE
 */
exports.getUserStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;

  try {
    let startDate, endDate;

    // 🔥 CORRECTION: Gestion sécurisée des dates
    if (data.startDate && data.endDate) {
      startDate = new Date(Number(data.startDate));
      endDate = new Date(Number(data.endDate));
    } else {
      // Par défaut: dernier mois
      endDate = new Date();
      startDate = new Date();
      startDate.setDate(startDate.getDate() - 30);
    }

    console.log(`📊 Getting user stats from ${startDate} to ${endDate}`);

    // Récupérer les clics
    const clicksQuery = await db.collection('clicks')
      .where('userId', '==', userId)
      .where('clickedAt', '>=', startDate)
      .where('clickedAt', '<=', endDate)
      .get();

    const clicks = clicksQuery.docs.map(doc => {
      const click = doc.data();
      return {
        id: doc.id,
        earnings: Number(click.earnings) || 0,
        status: String(click.status || 'pending'),
        clickedAt: click.clickedAt
      };
    });

    const validClicks = clicks.filter(click => click.status === 'valid');
    const totalEarnings = validClicks.reduce((sum, click) => sum + click.earnings, 0);

    const stats = {
      totalClicks: clicks.length,
      validClicks: validClicks.length,
      invalidClicks: clicks.length - validClicks.length,
      totalEarnings: parseFloat(totalEarnings.toFixed(3)),
      avgEarningsPerClick: validClicks.length > 0 ?
        parseFloat((totalEarnings / validClicks.length).toFixed(3)) : 0,
      conversionRate: clicks.length > 0 ?
        parseFloat(((validClicks.length / clicks.length) * 100).toFixed(1)) : 0
    };

    return {
      success: true,
      stats: stats,
      period: {
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString()
      }
    };

  } catch (error) {
    console.error('❌ Error in getUserStats:', error);

    // Données de démonstration
    return {
      success: true,
      stats: {
        totalClicks: 45,
        validClicks: 42,
        invalidClicks: 3,
        totalEarnings: 4.2,
        avgEarningsPerClick: 0.1,
        conversionRate: 93.3
      },
      usingDemoData: true,
      error: error.message
    };
  }
});
/**
 * Récupérer les campagnes disponibles
 */
exports.getAvailableCampaigns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;
  const { limit = 10, page = 1 } = data;

  try {
    // Récupérer les campagnes actives
    const campaignsSnapshot = await db.collection('campaigns')
      .where('isActive', '==', true)
      .where('status', '==', 'active')
      .limit(limit)
      .get();

    const availableCampaigns = [];

    for (const doc of campaignsSnapshot.docs) {
      const campaignData = doc.data();

      // Vérifier les clics de l'utilisateur
      const userClicksQuery = await db.collection('clicks')
        .where('campaignId', '==', doc.id)
        .where('userId', '==', userId)
        .get();

      const userClickCount = userClicksQuery.size;
      const maxClicksPerUser = campaignData.maxClicksPerUser || 3;

      if (userClickCount < maxClicksPerUser) {
        availableCampaigns.push({
          id: doc.id,
          ...campaignData,
          remainingClicks: campaignData.targetClicks - (campaignData.achievedClicks || 0),
          remainingBudget: campaignData.budget - (campaignData.spent || 0),
          participantEarnings: (campaignData.cpc || 0) * 0.6,
          userRemainingClicks: maxClicksPerUser - userClickCount,
        });
      }
    }

    return {
      success: true,
      campaigns: availableCampaigns,
      count: availableCampaigns.length,
      page: page,
      hasMore: availableCampaigns.length === limit
    };

  } catch (error) {
    console.error('Error getting available campaigns:', error);

    // Données de démonstration
    return {
      success: true,
      campaigns: [],
      count: 0,
      page: page,
      hasMore: false,
      usingDemoData: true
    };
  }
});

// ============ FONCTIONS PAIEMENT ET CAMPAGNES ============

/**
 * Créer une intention de campagne et de paiement
 */
exports.createCampaignIntent = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { title, description, targetUrl, budget, cpc = 0.06 } = data;
  const advertiserId = context.auth.uid;

  try {
    // Validation des données
    if (!title || !targetUrl || !budget) {
      throw new functions.https.HttpsError('invalid-argument', 'بيانات ناقصة');
    }

    if (budget < 60) {
      throw new functions.https.HttpsError('invalid-argument', 'الحد الأدنى للميزانية 60 دينار');
    }

    // Vérifier que l'utilisateur est une entreprise
    const userDoc = await db.collection('users').doc(advertiserId).get();
    const userData = userDoc.data();

    if (userData.userType !== 'business' && userData.userType !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'ليس لديك صلاحية لإنشاء حملات');
    }

    // Calculer le nombre de clics maximum
    const maxClicks = Math.floor(budget / cpc);

    // Créer un enregistrement de paiement temporaire
    const paymentRef = await db.collection('payments').add({
      advertiserId,
      title,
      description,
      targetUrl,
      budget,
      cpc,
      maxClicks,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Simuler la réponse de la passerelle de paiement
    const paymentResponse = {
      payment_url: `https://reshare.tn/payment-simulator?order=${paymentRef.id}`,
      payment_id: `pay_${Date.now()}`,
      status: 'PENDING'
    };

    // Mettre à jour l'enregistrement de paiement
    await paymentRef.update({
      paymentUrl: paymentResponse.payment_url,
      paymentId: paymentResponse.payment_id,
      providerData: paymentResponse
    });

    return {
      success: true,
      paymentUrl: paymentResponse.payment_url,
      paymentId: paymentRef.id,
      orderId: paymentResponse.payment_id
    };

  } catch (error) {
    console.error('Error creating campaign intent:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء الحملة');
  }
});
/**
 * Fonction de test pour créer une campagne sans paiement réel
 */
exports.createTestCampaign = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { title, description, targetUrl, budget, cpc = 0.06 } = data;
  const advertiserId = context.auth.uid;

  try {
    // Validation des données
    if (!title || !targetUrl || !budget) {
      throw new functions.https.HttpsError('invalid-argument', 'بيانات ناقصة');
    }

    if (budget < 60) {
      throw new functions.https.HttpsError('invalid-argument', 'الحد الأدنى للميزانية 60 دينار');
    }

    // Vérifier que l'utilisateur est une entreprise
    const userDoc = await db.collection('users').doc(advertiserId).get();
    const userData = userDoc.data();

    if (userData.userType !== 'business' && userData.userType !== 'admin') {
      // Auto-upgrade to business for testing
      await db.collection('users').doc(advertiserId).update({
        userType: 'business',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Calculer le nombre de clics maximum
    const maxClicks = Math.floor(budget / cpc);

    // Créer la campagne directement (sans paiement)
    const campaignRef = db.collection('campaigns').doc();
    const campaignId = campaignRef.id;

    const campaignData = {
      id: campaignId,
      advertiserId: advertiserId,
      title: title,
      description: description,
      targetUrl: targetUrl,
      cpc: cpc,
      budget: budget,
      spent: 0,
      targetClicks: maxClicks,
      achievedClicks: 0,
      uniqueClicks: 0,
      isActive: true,
      status: 'active',
      maxClicksPerUser: 3,
      type: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 jours
    };

    await campaignRef.set(campaignData);

    // Envoyer une notification
    await db.collection('notifications').add({
      userId: advertiserId,
      title: 'تم إنشاء حملة تجريبية 🎉',
      message: `حملة "${title}" تم إنشاؤها بنجاح للاختبار`,
      type: 'campaign_created',
      data: {
        campaignId: campaignId,
        campaignTitle: title
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Test campaign created: ${campaignId} for user: ${advertiserId}`);

    return {
      success: true,
      campaignId: campaignId,
      message: 'تم إنشاء الحملة التجريبية بنجاح',
      campaignData: campaignData
    };

  } catch (error) {
    console.error('Error creating test campaign:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء الحملة التجريبية: ' + error.message);
  }
});
/**
 * Simulateur de paiement pour le développement
 */
exports.simulatePayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { amount, campaignData } = data;
  const userId = context.auth.uid;

  try {
    // Simuler un délai de paiement
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Simuler une réponse de paiement réussie
    const paymentResponse = {
      success: true,
      paymentId: `pay_test_${Date.now()}`,
      transactionId: `txn_${Math.random().toString(36).substr(2, 9)}`,
      amount: amount,
      status: 'completed',
      message: 'تمت عملية الدفع بنجاح'
    };

    // Si des données de campagne sont fournies, créer la campagne
    if (campaignData) {
      const campaignRef = db.collection('campaigns').doc();
      const campaignId = campaignRef.id;

      const fullCampaignData = {
        id: campaignId,
        advertiserId: userId,
        ...campaignData,
        spent: 0,
        achievedClicks: 0,
        uniqueClicks: 0,
        isActive: true,
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      };

      await campaignRef.set(fullCampaignData);

      paymentResponse.campaignId = campaignId;
      paymentResponse.campaignData = fullCampaignData;
    }

    // Enregistrer la transaction de test
    await db.collection('test_payments').add({
      userId: userId,
      amount: amount,
      status: 'completed',
      paymentId: paymentResponse.paymentId,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return paymentResponse;

  } catch (error) {
    console.error('Error in payment simulation:', error);
    throw new functions.https.HttpsError('internal', 'فشل في محاكاة الدفع');
  }
});
/**
 * Récupérer les campagnes d'une entreprise
 */exports.getBusinessCampaigns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const userId = context.auth.uid;

  try {
    // 🟢 Récupérer les campagnes de l'entreprise (sans orderBy pour éviter l'index)
    const campaignsSnapshot = await db.collection('campaigns')
      .where('advertiserId', '==', userId)
      .get();

    // 🧠 Transformer les documents en objets
    let campaigns = campaignsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      remainingClicks: doc.data().targetClicks - (doc.data().achievedClicks || 0),
      remainingBudget: doc.data().budget - (doc.data().spent || 0),
      ctr: calculateCTR(doc.data().achievedClicks, doc.data().targetClicks)
    }));

    // 🔽 Tri local par date de création décroissante
    campaigns.sort((a, b) => {
      const aDate = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(0);
      const bDate = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(0);
      return bDate - aDate;
    });

    // 📊 Calculer les statistiques
    const stats = calculateBusinessStats(campaigns);

    return {
      success: true,
      campaigns,
      stats,
      count: campaigns.length
    };

  } catch (error) {
    console.error('Error getting business campaigns:', error);

    // 🔹 Données de démonstration
    const demoCampaigns = [
      {
        id: 'demo_business_1',
        title: 'حملة تجريبية للشركة',
        description: 'هذه حملة تجريبية لاختبار لوحة التحكم',
        budget: 1000.0,
        spent: 245.0,
        targetClicks: 1000,
        achievedClicks: 245,
        cpc: 0.1,
        isActive: true,
        status: 'active',
        ctr: 24.5,
        remainingClicks: 755,
        remainingBudget: 755.0,
        createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000), // قبل 5 أيام
        endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000)   // بعد 25 يوم
      }
    ];

    return {
      success: true,
      campaigns: demoCampaigns,
      stats: {
        totalCampaigns: 1,
        activeCampaigns: 1,
        totalSpent: 245.0,
        totalBudget: 1000.0,
        totalClicks: 245,
        averageCTR: 24.5
      },
      count: 1,
      usingDemoData: true
    };
  }
});

/**
 * Obtenir les statistiques détaillées d'une campagne
 */
exports.getCampaignAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول أولاً');
  }

  const { campaignId } = data;
  const userId = context.auth.uid;

  try {
    // Vérifier que l'utilisateur possède la campagne
    const campaignDoc = await db.collection('campaigns').doc(campaignId).get();

    if (!campaignDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'الحملة غير موجودة');
    }

    const campaign = campaignDoc.data();

    if (campaign.advertiserId !== userId) {
      throw new functions.https.HttpsError('permission-denied', 'ليس لديك صلاحية للوصول إلى هذه الحملة');
    }

    // Récupérer les clics de la campagne
    const clicksQuery = await db.collection('clicks')
      .where('campaignId', '==', campaignId)
      .get();

    const clicks = clicksQuery.docs.map(doc => doc.data());
    const validClicks = clicks.filter(click => click.status === 'valid');
    const uniqueClicks = [...new Set(clicks.map(click => click.deviceHash))].length;

    // Calculer les analytics
    const analytics = {
      basic: {
        totalClicks: clicks.length,
        validClicks: validClicks.length,
        invalidClicks: clicks.length - validClicks.length,
        uniqueClicks: uniqueClicks,
        totalEarnings: validClicks.reduce((sum, click) => sum + (click.earnings || 0), 0)
      },
      performance: {
        ctr: calculateCTR(clicks.length, campaign.targetClicks),
        conversionRate: (validClicks.length / clicks.length) * 100 || 0,
        fraudRate: ((clicks.length - validClicks.length) / clicks.length) * 100 || 0,
        avgEarningsPerClick: validClicks.length > 0 ?
          validClicks.reduce((sum, click) => sum + (click.earnings || 0), 0) / validClicks.length : 0
      },
      budget: {
        spent: campaign.spent || 0,
        remaining: campaign.budget - (campaign.spent || 0),
        utilization: ((campaign.spent || 0) / campaign.budget) * 100
      }
    };

    return {
      success: true,
      analytics: analytics,
      campaign: campaign
    };

  } catch (error) {
    console.error('Error getting campaign analytics:', error);
    throw new functions.https.HttpsError('internal', 'فشل في تحميل إحصائيات الحملة');
  }
});
// ============ FONCTIONS UTILITAIRES ============

/**
 * Calculer le CTR
 */
function calculateCTR(achievedClicks, targetClicks) {
  if (!targetClicks || targetClicks === 0) return 0;
  return (achievedClicks / targetClicks) * 100;
}

/**
 * Calculer les statistiques entreprise
 */
function calculateBusinessStats(campaigns) {
  const totalCampaigns = campaigns.length;
  const activeCampaigns = campaigns.filter(c => c.isActive).length;
  const totalSpent = campaigns.reduce((sum, c) => sum + (c.spent || 0), 0);
  const totalBudget = campaigns.reduce((sum, c) => sum + (c.budget || 0), 0);
  const totalClicks = campaigns.reduce((sum, c) => sum + (c.achievedClicks || 0), 0);
  const averageCTR = campaigns.length > 0 ?
    campaigns.reduce((sum, c) => sum + (c.ctr || 0), 0) / campaigns.length : 0;

  return {
    totalCampaigns,
    activeCampaigns,
    totalSpent,
    totalBudget,
    totalClicks,
    averageCTR,
    budgetUtilization: totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0
  };
}
/**
 * Webhook pour recevoir les confirmations de paiement
 */
exports.paymentWebhook = functions.https.onRequest(async (req, res) => {
  // Configurer CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { payment_id, status, order_id, amount } = req.body;

    if (status !== 'PAID' && status !== 'COMPLETED') {
      return res.status(400).json({ error: 'الدفع غير مكتمل' });
    }

    // Rechercher l'enregistrement de paiement
    const paymentDoc = await db.collection('payments').doc(order_id).get();

    if (!paymentDoc.exists) {
      return res.status(404).json({ error: 'لم يتم العثور على سجل الدفع' });
    }

    const paymentData = paymentDoc.data();

    // Mettre à jour le statut du paiement
    await paymentDoc.ref.update({
      status: 'succeeded',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      providerPaymentId: payment_id,
      providerData: req.body
    });

    // Créer la campagne active
    const campaignRef = db.collection('campaigns').doc();
    const campaignId = campaignRef.id;

    const campaignData = {
      id: campaignId,
      advertiserId: paymentData.advertiserId,
      title: paymentData.title,
      description: paymentData.description,
      targetUrl: paymentData.targetUrl,
      cpc: paymentData.cpc,
      budget: paymentData.budget,
      spent: 0,
      targetClicks: paymentData.maxClicks,
      achievedClicks: 0,
      uniqueClicks: 0,
      isActive: true,
      status: 'active',
      maxClicksPerUser: 3,
      type: 'open',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 jours
    };

    await campaignRef.set(campaignData);

    // Envoyer une notification à l'annonceur
    await db.collection('notifications').add({
      userId: paymentData.advertiserId,
      title: 'تم تفعيل حملتك الإعلانية 🎉',
      message: `حملة "${paymentData.title}" أصبحت نشطة ويمكن المشاركة بها`,
      type: 'campaign_activated',
      data: {
        campaignId: campaignId,
        campaignTitle: paymentData.title
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Campaign activated: ${campaignId} for advertiser: ${paymentData.advertiserId}`);

    return res.status(200).json({
      success: true,
      campaignId: campaignId,
      message: 'تم تفعيل الحملة بنجاح'
    });

  } catch (error) {
    console.error('Webhook error:', error);
    return res.status(500).json({ error: 'خطأ في معالجة الدفع' });
  }
});

// ============ FONCTIONS DE SUIVI ET CLICS ============

/**
 * Générer un lien de suivi signé
 */
exports.generateTrackingLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { campaignId } = data;
  const participantId = context.auth.uid;

  try {
    // Vérifier l'existence et l'activité de la campagne
    const campaignDoc = await db.collection('campaigns').doc(campaignId).get();

    if (!campaignDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'الحملة غير موجودة');
    }

    const campaign = campaignDoc.data();

    if (!campaign.isActive) {
      throw new functions.https.HttpsError('failed-precondition', 'الحملة غير نشطة');
    }

    // Vérifier le nombre de clics de l'utilisateur
    const userClicksQuery = await db.collection('clicks')
      .where('campaignId', '==', campaignId)
      .where('userId', '==', participantId)
      .get();

    if (userClicksQuery.size >= (campaign.maxClicksPerUser || 3)) {
      throw new functions.https.HttpsError('resource-exhausted', 'لقد تجاوزت الحد المسموح من النقرات لهذه الحملة');
    }

    // Créer un enregistrement de partage
    const shareRef = await db.collection('shares').add({
      campaignId,
      participantId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      clickCount: 0,
      earned: 0,
      status: 'active'
    });

    // Générer le lien de suivi (version simplifiée sans signature)
    const trackingLink = `https://scoutapk.web.app/click?c=${campaignId}&s=${shareRef.id}`;

    return {
      success: true,
      trackingLink,
      shareId: shareRef.id,
      campaignTitle: campaign.title,
      participantEarnings: campaign.cpc * 0.6
    };

  } catch (error) {
    console.error('Error generating tracking link:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء رابط التتبع');
  }
});

/**
 * Gestionnaire de clics principal (version simplifiée)
 */// ============ FONCTION CLICKHANDLER ============
// ============ FONCTION CLICKHANDLER COMPLÈTE ============

// ======================================================================
// 💥 3️⃣ الدالة الرئيسية clickHandler (مع تأخير 15 دقيقة فقط)
// ======================================================================
// =====================================================
// ✅ دالة clickHandler (تسجيل النقرة + تحويل مباشر)
// =====================================================
exports.clickHandler = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  const { c: campaignId, s: shareId, t: token } = req.query;
  if (!campaignId || !shareId) {
    return res.status(400).send("⚠️ Paramètres manquants");
  }

  try {
    const ip = (req.ip || "").replace("::ffff:", "");
    const ua = req.get("user-agent") || "";

    // 1️⃣ الكشف عن البوتات عبر UA
    const botUA = /(facebookexternalhit|twitterbot|whatsapp|telegram|googlebot|bot|curl|wget)/i;
    if (botUA.test(ua)) {
      await db.collection("bot_logs").add({
        ip, ua, reason: "user-agent",
        at: admin.firestore.Timestamp.now()
      });
      return res.status(204).send("");
    }

    // 2️⃣ rate limit
    const since = Date.now() - RATE_LIMIT_WINDOW;
    const snap = await db.collection("rate_limits")
      .where("ip", "==", ip)
      .where("ts", ">", admin.firestore.Timestamp.fromMillis(since))
      .get();
    if (snap.size >= RATE_LIMIT_COUNT) {
      await db.collection("bot_logs").add({
        ip, ua, reason: "rate-limit",
        at: admin.firestore.Timestamp.now()
      });
      return res.status(429).send("Too many requests");
    }
    await db.collection("rate_limits").add({
      ip, ts: admin.firestore.Timestamp.now()
    });

    // 3️⃣ تحليل IP مرة واحدة فقط
    let ipinfo = await getIPInfo(ip);

    // فحص الدولة والمزود
    const org = (ipinfo?.org || "").toLowerCase();
    const host = (ipinfo?.hostname || "").toLowerCase();
    const country = ipinfo?.country || "";

    // فحص مراكز البيانات
    if (/(google|facebook|amazon|aws|microsoft|digitalocean|cloudflare|linode|ovh|hetzner)/.test(org + host)) {
      await db.collection("bot_logs").add({
        ip, ua, reason: "ipinfo-datacenter",
        ipinfo, at: admin.firestore.Timestamp.now()
      });
      return res.status(204).send("");
    }

    // فحص الدولة
    if (country && !ALLOWED_COUNTRIES.includes(country)) {
      await db.collection("bot_logs").add({
        ip, ua, reason: `country-not-allowed-${country}`,
        ipinfo, at: admin.firestore.Timestamp.now()
      });
      return res.status(204).send("");
    }

    // 4️⃣ إذا ما فماش token → صفحة interstitial
    if (!token) {
      const exp = Math.floor(Date.now() / 1000) + 90;
      const payload = `${campaignId}|${shareId}|${exp}`;
      const sig = crypto.createHmac("sha256", HMAC_SECRET).update(payload).digest("hex");
      const t = Buffer.from(`${payload}|${sig}`).toString("base64url");

      // 🔥 الحصول على بيانات الحملة لمعرفة targetUrl
      const campaignDoc = await db.collection("campaigns").doc(campaignId).get();
      if (!campaignDoc.exists) {
        return res.status(404).send("⚠️ Campagne introuvable");
      }
      const campaign = campaignDoc.data();

      // 🔥 التصحيح: استخدام رابط الـ hosting لطلب POST ثم التوجيه إلى targetUrl
      const hostingUrl = `https://scoutapk.web.app/click?c=${campaignId}&s=${shareId}&t=${t}`;
      const targetUrl = campaign.targetUrl || "https://www.mytek.tn";

      const html = `
<!doctype html>
<html lang="ar">
<head>
  <meta charset="utf-8"/>
  <title>جاري التوجيه…</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; text-align: center; margin-top: 30vh; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;">
  <div style="background: rgba(255,255,255,0.1); padding: 2rem; border-radius: 15px; backdrop-filter: blur(10px); display: inline-block;">
    <h3 style="margin-bottom: 1rem;">🚀 جاري التوجيه...</h3>
    <p style="margin-bottom: 1.5rem;">الرجاء الانتظار لحظة</p>
    <div style="width: 50px; height: 50px; border: 3px solid rgba(255,255,255,0.3); border-top: 3px solid white; border-radius: 50%; margin: 0 auto; animation: spin 1s linear infinite;"></div>
  </div>
  <style>
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
  <script>
    (async () => {
      try {
        // 🔥 إرسال طلب POST لتسجيل النقرة
        await fetch('${hostingUrl}', { 
          method: 'POST',
          headers: { 'Content-Type': 'application/json' }
        });
      } catch (e) {
        console.log('Erreur fetch, redirection continue...');
      } finally {
        setTimeout(() => {
          // 🔥 🔥 🔥 التصحيح: التوجيه إلى الرابط المستهدف (targetUrl)
          window.location.href = '${targetUrl}';
        }, 1500);
      }
    })();
  </script>
</body>
</html>`;
      return res.status(200).send(html);
    }

    // 5️⃣ تحقق من التوكن (إذا كان موجوداً - هذا يعني الطلب الثاني)
    const decoded = Buffer.from(token, "base64url").toString("utf8").split("|");
    if (decoded.length !== 4) return res.status(401).send("token invalide");
    const [c, s, expStr, sig] = decoded;
    const exp = parseInt(expStr, 10);
    const expected = crypto.createHmac("sha256", HMAC_SECRET).update(`${c}|${s}|${exp}`).digest("hex");
    if (sig !== expected || Date.now() / 1000 > exp) {
      return res.status(401).send("token expiré ou invalide");
    }

    // 6️⃣ استرجاع البيانات
    const [campaignDoc, shareDoc] = await Promise.all([
      db.collection("campaigns").doc(campaignId).get(),
      db.collection("shares").doc(shareId).get(),
    ]);
    if (!campaignDoc.exists || !shareDoc.exists) {
      return res.status(404).send("⚠️ Campagne ou partage introuvable");
    }

    const campaign = campaignDoc.data();
    const share = shareDoc.data();

    // 7️⃣ detectFraud
    const fraudCheck = await detectFraud(req, campaignId, share.participantId);
    if (fraudCheck) {
      await db.collection("clicks").add({
        campaignId, shareId, userId: share.participantId,
        status: "fraud_suspect", reason: fraudCheck.reason,
        clickedAt: admin.firestore.Timestamp.now(),
        ip, ua, ipinfo, country,
        campaignTitle: campaign.title || "حملة غير معروفة"
      });
      console.log("🚫 Click rejeté:", fraudCheck.reason);

      // حتى في حالة الاحتيال، التوجيه إلى targetUrl
      return res.redirect(302, campaign.targetUrl);
    }

    // 8️⃣ حساب الأرباح وتسجيل النقرة
    const releaseDelayHours = 0.25;
    const now = admin.firestore.Timestamp.now();
    const releaseEligibleAt = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + releaseDelayHours * 60 * 60 * 1000
    );

    const participantEarnings = (campaign.cpc || 0.06) * 0.6;
    const platformEarnings = (campaign.cpc || 0.06) * 0.4;

    await db.collection("clicks").add({
      campaignId, shareId, userId: share.participantId,
      status: "valid", ip, ua, ipinfo, country,
      earnings: participantEarnings, platformEarnings,
      clickedAt: now, releaseStatus: "pending",
      releaseDelayHours, releaseEligibleAt,
      campaignTitle: campaign.title || "حملة نشطة",
      participantName: share.participantName || "مستخدم مجهول",
      fraudScore: 0
    });

    await db.collection("campaigns").doc(campaignId).update({
      achievedClicks: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.collection("users").doc(share.participantId).update({
      pendingBalance: admin.firestore.FieldValue.increment(participantEarnings),
      totalClicks: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Click enregistré pour: ${campaign.title} - Pays: ${country}`);

    // 🔥 في الطلب الثاني (مع التوكن)، التوجيه إلى targetUrl
    return res.redirect(302, campaign.targetUrl);

  } catch (err) {
    console.error("❌ Erreur:", err);
    res.status(500).send("Erreur interne du serveur");
  }
});

/**
 * 🔄 CORRIGER LES ACHIEVEDCLICKS POUR TOUTES LES CAMPAGNES
 */
exports.fixCampaignsAchievedClicks = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  try {
    console.log('🔄 Correction des achievedClicks pour toutes les campagnes...');

    // Récupérer toutes les campagnes
    const campaignsSnapshot = await db.collection('campaigns').get();
    let fixedCount = 0;

    for (const campaignDoc of campaignsSnapshot.docs) {
      const campaignId = campaignDoc.id;

      // Compter les clics valides pour cette campagne
      const validClicksQuery = await db.collection('clicks')
        .where('campaignId', '==', campaignId)
        .where('status', '==', 'valid')
        .get();

      const actualClicksCount = validClicksQuery.size;
      const currentAchievedClicks = campaignDoc.data().achievedClicks || 0;

      // Si les chiffres sont différents, corriger
      if (actualClicksCount !== currentAchievedClicks) {
        await campaignDoc.ref.update({
          achievedClicks: actualClicksCount,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          fixedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`🛠️ Campagne ${campaignId}: ${currentAchievedClicks} → ${actualClicksCount} clics`);
        fixedCount++;
      }
    }

    return {
      success: true,
      message: `تم تصحيح ${fixedCount} حملة`,
      fixedCount: fixedCount,
      timestamp: new Date().toISOString()
    };

  } catch (error) {
    console.error('❌ Error fixing achievedClicks:', error);
    throw new functions.https.HttpsError('internal', 'فشل في تصحيح عدد النقرات');
  }
});

/**
 * 📊 VERIFIER LES STATISTIQUES D'UNE CAMPAGNE
 */
exports.getCampaignStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { campaignId } = data;

  try {
    const campaignDoc = await db.collection('campaigns').doc(campaignId).get();

    if (!campaignDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'الحملة غير موجودة');
    }

    const campaign = campaignDoc.data();

    // Compter les clics réels
    const validClicksQuery = await db.collection('clicks')
      .where('campaignId', '==', campaignId)
      .where('status', '==', 'valid')
      .get();

    const actualValidClicks = validClicksQuery.size;
    const storedAchievedClicks = campaign.achievedClicks || 0;

    return {
      success: true,
      stats: {
        campaignId: campaignId,
        campaignTitle: campaign.title,
        storedAchievedClicks: storedAchievedClicks,
        actualValidClicks: actualValidClicks,
        discrepancy: storedAchievedClicks - actualValidClicks,
        needsFix: storedAchievedClicks !== actualValidClicks
      }
    };

  } catch (error) {
    console.error('Error getting campaign stats:', error);
    throw new functions.https.HttpsError('internal', 'فشل في تحميل إحصائيات الحملة');
  }
});

/**
 * Récupérer les clics en attente de révision - NOUVELLE FONCTION
 */
exports.getPendingClicks = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { limit = 50, page = 1, campaignId } = data;

  try {
    const db = admin.firestore();
    let query = db.collection('clicks')
      .where('requiresManualReview', '==', true)
      .where('status', 'in', ['pending', 'suspicious', 'pending_review'])
      .limit(limit);

    if (campaignId) {
      query = query.where('campaignId', '==', campaignId);
    }

    const snapshot = await query.get();
    const pendingClicks = [];

    for (const doc of snapshot.docs) {
      const click = doc.data();

      // Récupérer les données de la campagne
      const campaignDoc = await db.collection('campaigns').doc(click.campaignId).get();
      const campaign = campaignDoc.exists ? campaignDoc.data() : null;

      // Récupérer les données utilisateur
      const userDoc = await db.collection('users').doc(click.participantId || click.userId).get();
      const user = userDoc.exists ? userDoc.data() : null;

      pendingClicks.push({
        id: doc.id,
        ...click,
        campaignTitle: campaign?.title || 'غير معروف',
        participantName: user?.displayName || user?.email || 'مستخدم مجهول',
        participantRiskLevel: user?.riskLevel || 'unknown',
        fraudFlags: click.fraudFlags || [],
        clickedAt: click.clickedAt?.toDate?.() || new Date()
      });
    }

    return {
      success: true,
      clicks: pendingClicks,
      count: pendingClicks.length,
      total: snapshot.size
    };

  } catch (error) {
    console.error('Error getting pending clicks:', error);

    // Données de démonstration en cas d'erreur
    return {
      success: true,
      clicks: [],
      count: 0,
      total: 0,
      usingDemoData: true
    };
  }
});

/**
 * Récupérer les statistiques de détection de fraude - NOUVELLE FONCTION
 */
exports.getFraudDetectionStats = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  try {
    const db = admin.firestore();
    const now = new Date();
    const twentyFourHoursAgo = new Date(now.getTime() - (24 * 60 * 60 * 1000));

    // Récupérer les clics des dernières 24h
    const clicksQuery = await db.collection('clicks')
      .where('clickedAt', '>=', twentyFourHoursAgo)
      .get();

    const clicks = clicksQuery.docs.map(doc => doc.data());

    const stats = {
      totalClicks: clicks.length,
      validClicks: clicks.filter(c => c.status === 'valid').length,
      suspiciousClicks: clicks.filter(c =>
        c.status === 'suspicious' || c.requiresManualReview === true
      ).length,
      fraudulentClicks: clicks.filter(c =>
        c.status === 'fraud' || c.status === 'rejected' || c.status === 'invalid'
      ).length,
      manualReviews: clicks.filter(c => c.requiresManualReview === true).length,
      avgRiskScore: 0,
      fraudRate: 0
    };

    // Calculer le score de risque moyen
    const riskScores = clicks.map(c => c.riskScore || 0).filter(score => score > 0);
    stats.avgRiskScore = riskScores.length > 0 ?
      riskScores.reduce((a, b) => a + b, 0) / riskScores.length : 0;

    // Calculer le taux de fraude
    stats.fraudRate = stats.totalClicks > 0 ?
      (stats.fraudulentClicks / stats.totalClicks) * 100 : 0;

    return {
      success: true,
      stats: stats
    };

  } catch (error) {
    console.error('Error getting fraud stats:', error);

    // Données de démonstration
    return {
      success: true,
      stats: {
        totalClicks: 150,
        validClicks: 120,
        suspiciousClicks: 20,
        fraudulentClicks: 10,
        manualReviews: 15,
        avgRiskScore: 0.3,
        fraudRate: 6.7
      },
      usingDemoData: true
    };
  }
});
// ============ FONCTIONS DE PARRAINAGE ============

/**
 * Traiter un parrainage
 */
exports.processReferral = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { referrerId, newUserId, referralCode } = data;

  try {
    // Vérifier que le code de parrainage existe
    const referrerQuery = await db.collection('users')
      .where('referralCode', '==', referralCode)
      .limit(1)
      .get();

    if (referrerQuery.empty) {
      throw new functions.https.HttpsError('not-found', 'كود الإحالة غير صحيح');
    }

    const referrerDoc = referrerQuery.docs[0];
    if (referrerDoc.id !== referrerId) {
      throw new functions.https.HttpsError('invalid-argument', 'كود الإحالة لا يتطابق مع المستخدم');
    }

    // Créer l'enregistrement de parrainage
    const referralRef = await db.collection('referrals').add({
      referrerId,
      newUserId,
      referralCode,
      rewardAmount: 0.6,
      status: 'pending',
      newUserClicks: 0,
      clicksRequired: 10,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Mettre à jour le compteur de parrainages
    await db.collection('users').doc(referrerId).update({
      referralCount: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      referralId: referralRef.id,
      message: 'تمت معالجة الإحالة بنجاح'
    };

  } catch (error) {
    console.error('Error processing referral:', error);
    throw new functions.https.HttpsError('internal', 'فشل في معالجة الإحالة');
  }
});

// ============ FONCTIONS FINANCIÈRES ============

/**
 * Créer une demande de retrait
 */
exports.createWithdrawal = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { amount, paymentMethod, paymentDetails } = data;
  const userId = context.auth.uid;

  try {
    // Récupérer les données utilisateur
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'المستخدم غير موجود');
    }

    const userData = userDoc.data();

    // Vérifier le solde disponible
    if (userData.availableBalance < amount) {
      throw new functions.https.HttpsError('failed-precondition', 'الرصيد غير كافي');
    }

    // Vérifier le montant minimum
    if (amount < 10) {
      throw new functions.https.HttpsError('invalid-argument', 'الحد الأدنى للسحب هو 10 دينار');
    }

    // Créer la demande de retrait
    const withdrawalRef = await db.collection('withdrawals').add({
      userId,
      amount,
      paymentMethod,
      paymentDetails,
      status: 'pending',
      currency: 'TND',
      fees: 1.0, // Frais fixes pour simplifier
      netAmount: amount - 1.0,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Mettre à jour le solde de l'utilisateur
    await db.collection('users').doc(userId).update({
      availableBalance: admin.firestore.FieldValue.increment(-amount),
      pendingBalance: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      withdrawalId: withdrawalRef.id,
      message: 'تم إنشاء طلب السحب بنجاح'
    };

  } catch (error) {
    console.error('Error creating withdrawal:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء طلب السحب');
  }
});


// ============ FONCTIONS UTILITAIRES POUR LA CONVERSION ============

/**
 * Convertir le type de campagne de manière sécurisée
 */
function _convertCampaignType(type) {
  if (typeof type === 'number') {
    // Si c'est un nombre, convertir en string
    const types = ['open', 'regional', 'precise'];
    return types[type] || 'open';
  }

  // Si c'est déjà une string, vérifier qu'elle est valide
  const validTypes = ['open', 'regional', 'precise'];
  if (validTypes.includes(String(type))) {
    return String(type);
  }

  // Par défaut
  return 'open';
}

/**
 * Sérialiser une date de manière sécurisée
 */
function _serializeDate(dateField) {
  if (!dateField) {
    return new Date().toISOString();
  }

  if (dateField.toDate && typeof dateField.toDate === 'function') {
    // Firestore Timestamp
    return dateField.toDate().toISOString();
  }

  if (dateField instanceof Date) {
    // Objet Date
    return dateField.toISOString();
  }

  if (typeof dateField === 'string') {
    // String ISO
    return dateField;
  }

  if (typeof dateField === 'number') {
    // Timestamp
    return new Date(dateField).toISOString();
  }

  // Par défaut
  return new Date().toISOString();
}

/**
 * Déterminer le délai de libération en heures pour un utilisateur
 */
function _computeReleaseDelayHours(userData) {
  const defaultDelay = 24;
  const extendedDelay = 48;

  if (!userData) {
    return extendedDelay;
  }

  const accountAgeHours = _computeAccountAgeHours(userData);
  const riskLevel = String(userData.riskLevel || '').toLowerCase();
  const flags = userData.flags || {};
  const status = String(userData.accountStatus || '').toLowerCase();

  const isNewUser = accountAgeHours !== null && accountAgeHours < 72;
  const hasRiskFlag = flags.suspiciousActivity === true || flags.manualReview === true;
  const isHighRisk = ['high', 'suspicious', 'under_review'].includes(riskLevel) || status === 'under_review';

  if (isNewUser || hasRiskFlag || isHighRisk) {
    return extendedDelay;
  }

  return defaultDelay;
}

/**
 * Construire le contexte de libération pour suivi
 */
function _buildReleaseContext(userData) {
  if (!userData) {
    return {
      reason: 'no-user-record',
      evaluatedAt: new Date().toISOString()
    };
  }

  const accountAgeHours = _computeAccountAgeHours(userData);
  const riskLevel = String(userData.riskLevel || 'unknown').toLowerCase();
  const flags = userData.flags || {};
  const status = String(userData.accountStatus || 'active').toLowerCase();

  let reason = 'standard';
  if (accountAgeHours !== null && accountAgeHours < 72) {
    reason = 'new-user';
  }
  if (flags.suspiciousActivity === true || flags.manualReview === true) {
    reason = 'risk-flag';
  }
  if (['high', 'suspicious'].includes(riskLevel) || status === 'under_review') {
    reason = 'risk-level';
  }

  return {
    reason,
    accountAgeHours,
    riskLevel,
    status,
    flags: Object.keys(flags || {}).filter(key => flags[key] === true),
    evaluatedAt: new Date().toISOString()
  };
}

/**
 * Calculer l'âge du compte en heures
 */
function _computeAccountAgeHours(userData) {
  if (!userData || !userData.createdAt) {
    return null;
  }

  const createdAtDate = _toDate(userData.createdAt);
  if (!createdAtDate) {
    return null;
  }

  const diffMs = Date.now() - createdAtDate.getTime();
  return diffMs >= 0 ? diffMs / (60 * 60 * 1000) : 0;
}

/**
 * Conversion sécurisée vers Date
 */
function _toDate(value) {
  try {
    if (!value) {
      return null;
    }

    if (value.toDate && typeof value.toDate === 'function') {
      return value.toDate();
    }

    if (value instanceof Date) {
      return value;
    }

    if (typeof value === 'number') {
      return new Date(value);
    }

    if (typeof value === 'string') {
      const parsed = Date.parse(value);
      if (!isNaN(parsed)) {
        return new Date(parsed);
      }
      return null;
    }

    return null;
  } catch (error) {
    console.error('Error converting to date:', error);
    return null;
  }
}

/**
 * Générer des campagnes de démonstration
 */
function _getDemoCampaigns(limit) {
  const demoCampaigns = [
    {
      id: 'demo_1',
      title: 'حملة تجريبية 🔥',
      description: 'هذه حملة موصى بها خصيصاً لك',
      targetUrl: 'https://example.com',
      type: 'open', // 🔥 TYPE CORRECT
      status: 'active',
      budget: 1000.0,
      spent: 250.0,
      cpc: 0.1,
      targetClicks: 1000,
      achievedClicks: 250,
      uniqueClicks: 240,
      isActive: true,
      maxClicksPerUser: 3,
      conversionRate: 2.5,
      conversions: 25,
      remainingClicks: 750,
      remainingBudget: 750.0,
      participantEarnings: 0.06,
      createdAt: new Date().toISOString(),
      startDate: new Date().toISOString(),
      endDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000).toISOString(),
      imageUrl: null,
      advertiserId: 'demo_business'
    },
    {
      id: 'demo_2',
      title: 'عرض خاص ⏰',
      description: 'احصل على مكافآت مضاعفة في هذه الحملة المميزة',
      targetUrl: 'https://example.com',
      type: 'regional', // 🔥 TYPE CORRECT
      status: 'active',
      budget: 500.0,
      spent: 150.0,
      cpc: 0.15,
      targetClicks: 2000,
      achievedClicks: 750,
      uniqueClicks: 700,
      isActive: true,
      maxClicksPerUser: 2,
      conversionRate: 3.0,
      conversions: 15,
      remainingClicks: 1250,
      remainingBudget: 350.0,
      participantEarnings: 0.09,
      createdAt: new Date().toISOString(),
      startDate: new Date().toISOString(),
      endDate: new Date(Date.now() + 8 * 24 * 60 * 60 * 1000).toISOString(),
      imageUrl: null,
      advertiserId: 'demo_business'
    }
  ];

  return demoCampaigns.slice(0, limit);
}
/**
 * Réparer les données de campagne existantes
 */
exports.fixCampaignData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  try {
    console.log('🔧 Fixing campaign data...');

    // Récupérer toutes les campagnes
    const campaignsSnapshot = await db.collection('campaigns').get();

    let fixedCount = 0;
    const batch = db.batch();

    campaignsSnapshot.docs.forEach(doc => {
      const data = doc.data();

      // Vérifier et corriger le type
      if (typeof data.type === 'number') {
        console.log(`🛠️ Fixing campaign ${doc.id}: type ${data.type} -> ${_convertCampaignType(data.type)}`);

        batch.update(doc.ref, {
          type: _convertCampaignType(data.type),
          fixedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        fixedCount++;
      }
    });

    if (fixedCount > 0) {
      await batch.commit();
      console.log(`✅ Fixed ${fixedCount} campaigns`);
    }

    return {
      success: true,
      fixedCount: fixedCount,
      message: `تم إصلاح ${fixedCount} حملة`
    };

  } catch (error) {
    console.error('❌ Error fixing campaign data:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إصلاح البيانات');
  }
});
// ============ FONCTIONS PLANIFIÉES ============

/**
 * Nettoyer les clics suspects (version simplifiée)
 */
exports.cleanupSuspiciousClicks = functions.pubsub.schedule('every 24 hours').onRun(async (context) => {
  try {
    console.log('Cleanup function executed successfully');
    return null;
  } catch (error) {
    console.error('Cleanup error:', error);
    return null;
  }
});
// ======================================================================
// 💸 4️⃣ دالة تحويل الأرباح المعلقة إلى الرصيد المتاح transferPendingBalances()
// ======================================================================
exports.transferPendingBalances = functions.pubsub
  // ⏱️ فحص كل 5 دقائق أثناء التطوير (يمكنك تعديلها إلى every 1 hours لاحقًا)
  .schedule("every 5 minutes")
  .onRun(async () => {
    console.log("🔄 Vérification des soldes en attente...");

    const now = admin.firestore.Timestamp.now();
    const clicksSnapshot = await db
      .collection("clicks")
      .where("status", "==", "valid")
      .where("releaseStatus", "==", "pending")
      .where("releaseEligibleAt", "<=", now)
      .get();

    if (clicksSnapshot.empty) {
      console.log("✅ Aucun clic éligible au transfert.");
      return null;
    }

    const batch = db.batch();
    const userEarnings = {}; // تجميع الأرباح لكل مستخدم

    clicksSnapshot.forEach((doc) => {
      const data = doc.data();
      const amount = data.earnings || 0;

      // ⏩ تجاهل النقرة إذا تم اكتشافها كاحتيالية لاحقًا
      if (data.status === "fraud_detected" || amount <= 0) return;

      const userId = data.userId;
      if (!userEarnings[userId]) userEarnings[userId] = 0;
      userEarnings[userId] += amount;

      // تحديث حالة النقرة نفسها
      batch.update(doc.ref, {
        releaseStatus: "released",
        releasedAt: now,
        releaseNote: "Auto-release après 15 minutes (développement)",
      });
    });

    // 💰 تحديث أرصدة المستخدمين
    for (const [userId, amount] of Object.entries(userEarnings)) {
      const userRef = db.collection("users").doc(userId);
      batch.update(userRef, {
        pendingBalance: admin.firestore.FieldValue.increment(-amount),
        availableBalance: admin.firestore.FieldValue.increment(amount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    console.log(
      `💸 Transfert terminé : ${Object.keys(userEarnings).length} utilisateurs mis à jour.`
    );
    return null;
  });


// ======================================================================
// 🧠 1️⃣ دالة كشف الاحتيال الفوري detectFraud()
// ======================================================================
/**
 * 🛡️ Détection de fraude simple et rapide
 * Vérifie : IP, User-Agent, délai entre clics, et device hash
 */
async function detectFraud(req, campaignId, userId) {
  try {
    const ip = req.headers["x-forwarded-for"] || req.ip || "0.0.0.0";
    const userAgent = req.get("user-agent") || "unknown";
    const now = admin.firestore.Timestamp.now();

    // 🔹 Récupérer les clics récents de ce user pour cette campagne
    const recentClicksSnap = await db
      .collection("clicks")
      .where("userId", "==", userId)
      .where("campaignId", "==", campaignId)
      .orderBy("clickedAt", "desc")
      .limit(3)
      .get();

    if (!recentClicksSnap.empty) {
      const lastClick = recentClicksSnap.docs[0].data();
      const diffSeconds =
        (now.toMillis() - lastClick.clickedAt.toMillis()) / 1000;

      // ⚠️ Trop rapide (moins de 10 secondes entre deux clics)
      if (diffSeconds < 10) {
        return { reason: "Trop de clics rapprochés (bot suspect)" };
      }

      // ⚠️ Même IP + même User-Agent répété trop souvent
      const similarClicks = recentClicksSnap.docs.filter((doc) => {
        const d = doc.data();
        return d.ip === ip && d.userAgent === userAgent;
      });
      if (similarClicks.length >= 3) {
        return { reason: "Trop de clics identiques depuis même appareil" };
      }
    }

    // ✅ Aucun problème détecté
    return null;
  } catch (err) {
    console.error("❌ Erreur dans detectFraud:", err);
    // En cas d’erreur interne, considérer la requête comme sûre (pas de blocage)
    return null;
  }
}

// ======================================================================
// 🔁 2️⃣ دالة المراجعة الآلية checkFraudulentClicks()
// ======================================================================
exports.checkFraudulentClicks = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    console.log("🕵️ Vérification automatique des clics suspects...");

    const now = admin.firestore.Timestamp.now();
    const clicksSnapshot = await db
      .collection("clicks")
      .where("status", "==", "valid")
      .where("releaseStatus", "==", "pending")
      .get();

    const fraudUpdates = [];
    const groupedByUser = {};

    clicksSnapshot.forEach((doc) => {
      const data = doc.data();
      if (!groupedByUser[data.userId]) groupedByUser[data.userId] = [];
      groupedByUser[data.userId].push({ id: doc.id, ...data });
    });

    for (const [userId, clicks] of Object.entries(groupedByUser)) {
      const byDevice = {};
      const byIp = {};

      for (const c of clicks) {
        byDevice[c.deviceHash] = (byDevice[c.deviceHash] || 0) + 1;
        byIp[c.ip] = (byIp[c.ip] || 0) + 1;
      }

      // 🚫 أكثر من 5 نقرات بنفس الجهاز أو IP → اشتباه
      const deviceFraud = Object.values(byDevice).some((n) => n > 5);
      const ipFraud = Object.values(byIp).some((n) => n > 5);

      if (deviceFraud || ipFraud) {
        clicks.forEach((c) => {
          fraudUpdates.push({
            id: c.id,
            reason: deviceFraud
              ? "Trop de clics depuis le même appareil"
              : "Trop de clics depuis la même IP",
          });
        });
      }
    }

    // 🧾 تحديث الحالات الاحتيالية
    const batch = db.batch();
    fraudUpdates.forEach((f) => {
      const ref = db.collection("clicks").doc(f.id);
      batch.update(ref, {
        status: "fraud_detected",
        reviewedAt: now,
        fraudReason: f.reason,
      });
    });

    await batch.commit();
    console.log(`✅ ${fraudUpdates.length} clics marqués comme frauduleux.`);
  });
/**
 * Désactiver les campagnes expirées
 */
exports.deactivateExpiredCampaigns = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const db = admin.firestore();
  const now = new Date();

  try {
    const expiredCampaigns = await db.collection('campaigns')
      .where('isActive', '==', true)
      .where('endDate', '<', now)
      .get();

    const batch = db.batch();
    let processed = 0;

    expiredCampaigns.docs.forEach(doc => {
      batch.update(doc.ref, {
        isActive: false,
        status: 'completed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      processed++;
    });

    if (processed > 0) {
      await batch.commit();
      console.log(`Deactivated ${processed} expired campaigns`);
    }

    return null;
  } catch (error) {
    console.error('Deactivation error:', error);
    return null;
  }
});
/**
 * Calculer les statistiques quotidiennes - VERSION CORRIGÉE
 */
function calculateDailyStats(clicks, startDate, endDate) {
  const dailyStats = {};
  const currentDate = new Date(startDate);

  // Initialiser tous les jours dans la période
  while (currentDate <= endDate) {
    const dateKey = currentDate.toISOString().split('T')[0];
    dailyStats[dateKey] = {
      date: dateKey,
      clicks: 0,
      validClicks: 0,
      earnings: 0
    };
    currentDate.setDate(currentDate.getDate() + 1);
  }

  // Compter les clics par jour
  clicks.forEach(click => {
    let clickDate;

    if (click.clickedAt && click.clickedAt.toDate) {
      clickDate = click.clickedAt.toDate();
    } else if (click.clickedAt instanceof Date) {
      clickDate = click.clickedAt;
    } else if (typeof click.clickedAt === 'string') {
      clickDate = new Date(click.clickedAt);
    } else {
      clickDate = new Date();
    }

    const dateKey = clickDate.toISOString().split('T')[0];

    if (dailyStats[dateKey]) {
      dailyStats[dateKey].clicks++;

      if (click.status === 'valid') {
        dailyStats[dateKey].validClicks++;
        dailyStats[dateKey].earnings += Number(click.earnings || 0);
      }
    }
  });

  // Convertir en tableau et formater
  return Object.values(dailyStats).map(day => ({
    ...day,
    earnings: parseFloat(day.earnings.toFixed(3))
  }));
}
/**
 * Créer des données de test propres
 */
exports.createCleanTestData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const userId = context.auth.uid;

  try {
    // Créer une campagne de test avec des types corrects
    const campaignRef = await db.collection('campaigns').add({
      title: 'حملة تجريبية نظيفة',
      description: 'هذه حملة تجريبية ببيانات نظيفة',
      targetUrl: 'https://example.com',
      type: 'open',
      status: 'active',
      budget: 1000.0,
      spent: 0.0,
      cpc: 0.1,
      targetClicks: 1000,
      achievedClicks: 0,
      uniqueClicks: 0,
      isActive: true,
      maxClicksPerUser: 3,
      conversionRate: 0.0,
      conversions: 0,
      advertiserId: 'test_business',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
    });

    // Créer des clics de test avec des types corrects
    const batch = db.batch();

    for (let i = 0; i < 10; i++) {
      const clickRef = db.collection('clicks').doc();
      batch.set(clickRef, {
        campaignId: campaignRef.id,
        userId: userId,
        earnings: 0.06,
        status: 'valid',
        clickedAt: admin.firestore.FieldValue.serverTimestamp(),
        ip: `192.168.1.${i + 1}`,
        userAgent: 'Mozilla/5.0 (Test)',
        deviceHash: `device_${i}`,
        fraudScore: 0.1
      });
    }

    await batch.commit();

    return {
      success: true,
      message: 'تم إنشاء بيانات تجريبية نظيفة بنجاح',
      campaignId: campaignRef.id
    };

  } catch (error) {
    console.error('Error creating clean test data:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء البيانات التجريبية');
  }
});
// ============ FONCTIONS DE TEST ET UTILITAIRES ============

/**
 * Fonction de test pour vérifier le déploiement
 */
exports.testFunction = functions.https.onCall(async (data, context) => {
  return {
    success: true,
    message: 'Cloud Functions are working correctly! 🚀',
    timestamp: new Date().toISOString(),
    userId: context.auth ? context.auth.uid : 'not-authenticated',
    environment: process.env.NODE_ENV || 'development'
  };
});

/**
 * Envoyer une notification utilisateur
 */
exports.sendUserNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { userId, title, body, type, data: notificationData } = data;

  try {
    const notificationRef = await db.collection('notifications').add({
      userId,
      title,
      body,
      type,
      data: notificationData,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      notificationId: notificationRef.id,
      message: 'تم إرسال الإشعار بنجاح'
    };

  } catch (error) {
    console.error('Error sending notification:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إرسال الإشعار');
  }
});

/**
 * Mettre à jour le solde utilisateur
 */
exports.updateUserBalance = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const { userId, amount, transactionType, description } = data;

  try {
    await db.collection('users').doc(userId).update({
      availableBalance: admin.firestore.FieldValue.increment(amount),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Enregistrer la transaction
    await db.collection('transactions').add({
      userId,
      amount,
      type: transactionType,
      description,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: 'تم تحديث الرصيد بنجاح'
    };

  } catch (error) {
    console.error('Error updating user balance:', error);
    throw new functions.https.HttpsError('internal', 'فشل في تحديث الرصيد');
  }
});

/**
 * Créer une campagne directement sans processus de paiement
 */
exports.createCampaignDirect = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const {
    title,
    description,
    targetUrl,
    budget = 100,
    cpc = 0.06,
    type = 'open',
    maxClicksPerUser = 3
  } = data;

  const advertiserId = context.auth.uid;

  try {
    // Validation des données
    if (!title || !targetUrl) {
      throw new functions.https.HttpsError('invalid-argument', 'العنوان ورابط الوجهة مطلوبان');
    }

    if (budget < 10) {
      throw new functions.https.HttpsError('invalid-argument', 'الحد الأدنى للميزانية 10 دينار');
    }

    // Vérifier/Mettre à jour le type d'utilisateur
    const userDoc = await db.collection('users').doc(advertiserId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'المستخدم غير موجود');
    }

    const userData = userDoc.data();

    // Auto-upgrade to business si nécessaire
    if (userData.userType !== 'business' && userData.userType !== 'admin') {
      await db.collection('users').doc(advertiserId).update({
        userType: 'business',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    // Calculer le nombre de clics maximum
    const targetClicks = Math.floor(budget / cpc);

    // Dates
    const now = new Date();
    const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000); // 30 jours

    // Créer la campagne directement
    const campaignRef = db.collection('campaigns').doc();
    const campaignId = campaignRef.id;

    const campaignData = {
      id: campaignId,
      advertiserId: advertiserId,
      title: title,
      description: description || 'لا يوجد وصف',
      targetUrl: targetUrl,
      type: type,
      status: 'active',
      budget: Number(budget),
      spent: 0,
      cpc: Number(cpc),
      targetClicks: targetClicks,
      achievedClicks: 0,
      uniqueClicks: 0,
      isActive: true,
      maxClicksPerUser: Number(maxClicksPerUser),
      conversionRate: 0,
      conversions: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      startDate: admin.firestore.FieldValue.serverTimestamp(),
      endDate: endDate,
      // Champs optionnels
      imageUrl: data.imageUrl || null,
      targetRegions: data.targetRegions || null,
      targetLocation: data.targetLocation || null,
      targetRadius: data.targetRadius || 5.0,
      categories: data.categories || []
    };

    await campaignRef.set(campaignData);

    // Envoyer une notification
    await db.collection('notifications').add({
      userId: advertiserId,
      title: 'تم إنشاء حملة جديدة 🎉',
      message: `حملة "${title}" تم إنشاؤها بنجاح وتم تفعيلها`,
      type: 'campaign_created',
      data: {
        campaignId: campaignId,
        campaignTitle: title
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`✅ Campaign created directly: ${campaignId} for user: ${advertiserId}`);

    return {
      success: true,
      campaignId: campaignId,
      message: 'تم إنشاء الحملة بنجاح وتم تفعيلها',
      campaignData: {
        ...campaignData,
        remainingClicks: targetClicks,
        remainingBudget: budget,
        participantEarnings: (cpc * 0.6)
      }
    };

  } catch (error) {
    console.error('❌ Error creating campaign directly:', error);
    throw new functions.https.HttpsError('internal', `فشل في إنشاء الحملة: ${error.message}`);
  }
});
/**
 * Créer des campagnes de test pour le développement
 */
exports.createTestCampaigns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const advertiserId = context.auth.uid;
  const count = data.count || 3;

  try {
    const testCampaigns = [];

    for (let i = 1; i <= count; i++) {
      const campaignRef = db.collection('campaigns').doc();
      const campaignId = campaignRef.id;

      const now = new Date();
      const endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

      const campaignData = {
        id: campaignId,
        advertiserId: advertiserId,
        title: `حملة تجريبية ${i} 🔥`,
        description: `هذه حملة تجريبية رقم ${i} للاختبار والتطوير`,
        targetUrl: 'https://example.com',
        type: i % 3 === 0 ? 'precise' : i % 2 === 0 ? 'regional' : 'open',
        status: 'active',
        budget: [100, 200, 300][i % 3],
        spent: 0,
        cpc: 0.05,
        targetClicks: [2000, 4000, 6000][i % 3],
        achievedClicks: 0,
        uniqueClicks: 0,
        isActive: true,
        maxClicksPerUser: 3,
        conversionRate: 0,
        conversions: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: endDate,
        imageUrl: null
      };

      await campaignRef.set(campaignData);
      testCampaigns.push(campaignData);
    }

    // Mettre à jour le type d'utilisateur
    await db.collection('users').doc(advertiserId).update({
      userType: 'business',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: `تم إنشاء ${count} حملة تجريبية بنجاح`,
      campaigns: testCampaigns
    };

  } catch (error) {
    console.error('Error creating test campaigns:', error);
    throw new functions.https.HttpsError('internal', 'فشل في إنشاء الحملات التجريبية');
  }
});
/**
 * Réinitialiser les campagnes de test
 */
exports.resetTestCampaigns = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }

  const advertiserId = context.auth.uid;

  try {
    // Récupérer toutes les campagnes de test de l'utilisateur
    const campaignsSnapshot = await db.collection('campaigns')
      .where('advertiserId', '==', advertiserId)
      .get();

    const batch = db.batch();
    let deletedCount = 0;

    campaignsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
      deletedCount++;
    });

    await batch.commit();

    return {
      success: true,
      message: `تم حذف ${deletedCount} حملة تجريبية`,
      deletedCount: deletedCount
    };

  } catch (error) {
    console.error('Error resetting test campaigns:', error);
    throw new functions.https.HttpsError('internal', 'فشل في حذف الحملات التجريبية');
  }
});
exports.approveClick = functions.https.onCall(async (data, context) => {
  try {
    const { clickId, adminId, adjustedEarnings, notes } = data;

    const clickRef = db.collection("clicks").doc(clickId);
    const clickSnap = await clickRef.get();
    if (!clickSnap.exists) {
      return { success: false, error: "النقرة غير موجودة" };
    }

    const click = clickSnap.data();
    if (click.releaseStatus === "released") {
      return { success: false, error: "تمت الموافقة سابقاً" };
    }

    const userRef = db.collection("users").doc(click.userId);

    await db.runTransaction(async (t) => {
      t.update(clickRef, {
        releaseStatus: "released",
        status: "valid",
        earnings: adjustedEarnings ?? click.earnings,
        approvedBy: adminId,
        approvedAt: admin.firestore.Timestamp.now(),
        notes: notes ?? "تمت الموافقة من لوحة التحكم",
      });

      t.update(userRef, {
        availableBalance: admin.firestore.FieldValue.increment(adjustedEarnings ?? click.earnings),
        pendingBalance: admin.firestore.FieldValue.increment(-(click.earnings)),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`✅ Click ${clickId} approved by ${adminId}`);
    return { success: true };
  } catch (err) {
    console.error("❌ Error approving click:", err);
    return { success: false, error: err.message };
  }
});
exports.rejectClick = functions.https.onCall(async (data, context) => {
  try {
    const { clickId, adminId, reason, evidence } = data;

    const clickRef = db.collection("clicks").doc(clickId);
    const clickSnap = await clickRef.get();
    if (!clickSnap.exists) {
      return { success: false, error: "النقرة غير موجودة" };
    }

    const click = clickSnap.data();
    const userRef = db.collection("users").doc(click.userId);

    await db.runTransaction(async (t) => {
      t.update(clickRef, {
        releaseStatus: "rejected",
        status: "invalid",
        rejectedBy: adminId,
        rejectedAt: admin.firestore.Timestamp.now(),
        rejectionReason: reason,
        rejectionEvidence: evidence || null,
      });

      // تعويض الرصيد المعلق
      t.update(userRef, {
        pendingBalance: admin.firestore.FieldValue.increment(-click.earnings),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    console.log(`🚫 Click ${clickId} rejected by ${adminId}`);
    return { success: true };
  } catch (err) {
    console.error("❌ Error rejecting click:", err);
    return { success: false, error: err.message };
  }
});
exports.getPlatformEarnings = functions.https.onCall(async (data, context) => {
  try {
    const clicksSnap = await db.collection("clicks")
      .where("status", "==", "valid")
      .get();

    let totalEarnings = 0;
    clicksSnap.forEach(doc => {
      const c = doc.data();
      totalEarnings += c.earnings || 0;
    });

    // نفترض أن المنصة تأخذ 40%
    const platformShare = totalEarnings * 0.4;

    return {
      success: true,
      totalEarnings: totalEarnings.toFixed(3),
      platformEarnings: platformShare.toFixed(3),
    };
  } catch (err) {
    console.error("❌ Error calculating platform earnings:", err);
    return { success: false, error: err.message };
  }
});
/**
 * Récupérer les clics en attente de révision - VERSION CORRIGÉE
 */exports.getPendingClicks = functions.https.onCall(async (data, context) => {
  try {
    const limit = data.limit || 50;

    const pendingSnap = await db
      .collection("clicks")
      .where("releaseStatus", "==", "pending")
      .orderBy("clickedAt", "desc")
      .limit(limit)
      .get();

    const clicks = [];

    for (const doc of pendingSnap.docs) {
      const c = doc.data();
      clicks.push({
        id: doc.id,
        campaignTitle: c.campaignTitle || "حملة غير معروفة",
        participantName: c.userName || "مستخدم مجهول",
        participantRiskLevel: c.riskLevel || "low",
        fraudFlags: c.fraudFlags || [],
        earnings: c.earnings,
        clickedAt: c.clickedAt?.toDate() || null,
        status: c.status,
      });
    }

    return { success: true, clicks };
  } catch (err) {
    console.error("❌ Error getting pending clicks:", err);
    return { success: false, error: err.message };
  }
});
exports.updateClickStatus = functions.https.onCall(async (data, context) => {
  try {
    const { clickId, newStatus, reason, adjustedEarnings } = data;
    const clickRef = db.collection("clicks").doc(clickId);

    await clickRef.update({
      status: newStatus,
      updatedAt: admin.firestore.Timestamp.now(),
      reason: reason ?? "",
      earnings: adjustedEarnings ?? admin.firestore.FieldValue.delete(),
    });

    console.log(`🔄 Click ${clickId} updated to ${newStatus}`);
    return { success: true };
  } catch (err) {
    console.error("❌ Error updating click status:", err);
    return { success: false, error: err.message };
  }
});
/**
 * Récupérer les statistiques de détection de fraude - VERSION CORRIGÉE
 */
exports.getFraudDetectionStats = functions.https.onCall(async (data, context) => {
  try {
    const totalClicksSnap = await db.collection("clicks").get();
    const validClicksSnap = await db.collection("clicks").where("status", "==", "valid").get();
    const suspiciousClicksSnap = await db.collection("clicks").where("status", "==", "suspicious").get();
    const fraudClicksSnap = await db.collection("clicks").where("status", "==", "fraud").get();

    const total = totalClicksSnap.size || 1;
    const fraudRate = ((fraudClicksSnap.size / total) * 100).toFixed(2);

    return {
      success: true,
      stats: {
        totalClicks: total,
        validClicks: validClicksSnap.size,
        suspiciousClicks: suspiciousClicksSnap.size,
        fraudulentClicks: fraudClicksSnap.size,
        fraudRate,
        avgRiskScore: 0.4, // يمكنك لاحقاً حسابه من riskLevel
        manualReviews: suspiciousClicksSnap.size,
      },
    };
  } catch (err) {
    console.error("❌ Error fetching fraud stats:", err);
    return { success: false, error: err.message };
  }
});

/**
 * Récupérer les rapports de fraude détaillés - NOUVELLE FONCTION
 */
exports.getFraudReports = functions.https.onCall(async (data, context) => {
  try {
    const now = new Date();
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(now.getDate() - 7);

    const fraudClicksSnap = await db
      .collection("clicks")
      .where("status", "in", ["fraud", "suspicious"])
      .where("clickedAt", ">=", sevenDaysAgo)
      .get();

    return {
      success: true,
      period: "آخر 7 أيام",
      totalClicks: fraudClicksSnap.size,
      fraudRate: (fraudClicksSnap.size / 100).toFixed(2),
    };
  } catch (err) {
    console.error("❌ Error generating fraud report:", err);
    return { success: false, error: err.message };
  }
});

// Mettre à jour le solde utilisateur
async function _updateUserBalance(userId, amount) {
  const db = admin.firestore();
  const userRef = db.collection('users').doc(userId);

  await userRef.update({
    availableBalance: admin.firestore.FieldValue.increment(amount),
    totalEarnings: admin.firestore.FieldValue.increment(amount),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

// Mettre à jour les stats de campagne
async function _updateCampaignStats(campaignId, status, earnings) {
  const db = admin.firestore();
  const campaignRef = db.collection('campaigns').doc(campaignId);

  const updates = {
    achievedClicks: admin.firestore.FieldValue.increment(1)
  };

  if (status === 'valid') {
    updates.spent = admin.firestore.FieldValue.increment(earnings / 0.6);
    updates.uniqueClicks = admin.firestore.FieldValue.increment(1);
  }

  await campaignRef.update(updates);
}

// Calculer le temps de libération
function _computeReleaseTime() {
  const releaseTime = new Date();
  releaseTime.setHours(releaseTime.getHours() + 24); // 24 heures
  return releaseTime;
}

// Enregistrer le pattern de fraude
async function _recordFraudPattern(clickData, reason) {
  const db = admin.firestore();

  await db.collection('fraud_patterns').add({
    ip: clickData.ipAddress,
    deviceHash: clickData.deviceHash,
    reason: reason,
    participantId: clickData.participantId,
    detectedAt: admin.firestore.FieldValue.serverTimestamp(),
    clickData: {
      campaignId: clickData.campaignId,
      riskScore: clickData.riskScore,
      fraudFlags: clickData.fraudFlags
    }
  });
}