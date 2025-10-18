import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../data/models/campaign_model.dart';

/// خدمة المشاركة - تدير جميع عمليات مشاركة المحتوى على المنصات المختلفة
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  // 🔥 CONSTANTE POUR LE DOMAINE UNIFORMISÉ
  static const String APP_BASE_URL = "https://scoutapk.web.app";

  /// مشاركة حملة إعلانية - VERSION COMPATIBLE AVEC VOTRE PROVIDER
  Future<bool> shareCampaign({
    required CampaignModel campaign,
    required String shareLink, // 🔥 Garder le même paramètre
    String? customMessage,
  }) async {
    try {
      print('🔄 Partage de campagne: ${campaign.title}');
      print('🔗 Lien fourni: $shareLink');

      final message = customMessage ?? _generateCampaignShareMessage(campaign, shareLink);
      
      await Share.share(
        message,
        subject: 'شارك واربح مع ReShare 🚀',
      );

      print('✅ Campagne partagée avec succès');
      return true;
    } catch (e) {
      print('❌ فشل في مشاركة الحملة: $e');
      return false;
    }
  }

  /// مشاركة رابط الإحالة
  Future<bool> shareReferralLink({
    required String referralLink,
    required String referralCode,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generateReferralShareMessage(referralLink, referralCode);

      await Share.share(
        message,
        subject: 'انضم إلى ReShare واربح معي! 🎁',
      );

      return true;
    } catch (e) {
      print('فشل في مشاركة رابط الإحالة: $e');
      return false;
    }
  }

  /// Create campaign share message
  String _generateCampaignShareMessage(CampaignModel campaign, String shareLink) {
    return '''
🚀 حملة جديدة على ReShare!

${campaign.title}

${campaign.description}

🎯 شارك الآن واربح ${campaign.participantEarnings.toStringAsFixed(3)} دينار لكل نقرة صالحة!

🔗 ${_shortenUrl(shareLink)}

💰 ${_getCampaignTypeText(campaign.type)}
⏰ ${_getTimeRemaining(campaign.endDate)}

#ReShare #ربح_من_التسويق #${_generateHashtags(campaign.title)}
''';
  }

  /// Create referral share message
  String _generateReferralShareMessage(String referralLink, String referralCode) {
    return '''
🎁 انضم إلى ReShare واربح معي!

تطبيق رائع يمكنك من تحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.

✨ المميزات:
✅ أرباح حقيقية من المشاركة
✅ حملات متنوعة يومياً
✅ سحب أموال بسهولة
✅ نظام إحالة بمكافآت مميزة

🎯 استخدم كود الإحالة الخاص بي: $referralCode

🔗 سجل الآن من خلال الرابط:
${_shortenUrl(referralLink)}

🎊 ستحصل على مكافأة ترحيب عند التسجيل!

#ReShare #دخل_إضافي #ربح_من_الإنترنت
''';
  }

  /// إرسال دعوة إحالة عبر منصات محددة
  Future<bool> sendInvitation({
    required String platform,
    required String contactInfo,
    required String referralCode,
    String? customMessage,
  }) async {
    try {
      final referralLink = '$APP_BASE_URL/register?ref=$referralCode';
      final message = customMessage ?? _generateInvitationMessage(referralCode, referralLink);

      switch (platform.toLowerCase()) {
        case 'whatsapp':
          return await _shareViaWhatsApp(contactInfo, message);
        case 'sms':
          return await _shareViaSMS(contactInfo, message);
        case 'email':
          return await _shareViaEmail(contactInfo, message);
        case 'telegram':
          return await _shareViaTelegram(contactInfo, message);
        case 'facebook':
          return await _shareViaFacebook(message);
        case 'twitter':
          return await _shareViaTwitter(message);
        case 'instagram':
          return await _shareViaInstagram(message);
        case 'copy':
          return await _copyToClipboard(message);
        default:
          return false;
      }
    } catch (e) {
      print('فشل في إرسال الدعوة: $e');
      return false;
    }
  }

  /// Create invitation message
  String _generateInvitationMessage(String referralCode, String referralLink) {
    return '''
مرحباً! 👋

أود دعوتك للانضمام إلى ReShare، منصة رائعة لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.

🎯 لماذا ReShare?
• أرباح حقيقية من كل نقرة
• حملات متنوعة يومياً
• سحب أموال سهل وآمن
• نظام إحالة بمكافآت مميزة

🎁 استخدم كود الإحالة الخاص بي: $referralCode

🔗 سجل من خلال هذا الرابط:
$referralLink

💰 ستحصل على مكافأة ترحيب عند التسجيل!

أنتظرك هناك! 🚀

#ReShare #دخل_إضافي
''';
  }

  // ============ MÉTHODES DE PARTAGE ============

  Future<bool> _shareViaWhatsApp(String phoneNumber, String message) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      final url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر واتساب: $e');
      return false;
    }
  }

  Future<bool> _shareViaSMS(String phoneNumber, String message) async {
    try {
      final url = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر الرسائل: $e');
      return false;
    }
  }

  Future<bool> _shareViaEmail(String email, String message) async {
    try {
      final url = 'mailto:$email?subject=دعوة للانضمام إلى ReShare&body=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر البريد: $e');
      return false;
    }
  }

  Future<bool> _shareViaTelegram(String username, String message) async {
    try {
      final url = 'https://t.me/share/url?url=${Uri.encodeComponent('$APP_BASE_URL/register')}&text=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر تليجرام: $e');
      return false;
    }
  }

  Future<bool> _shareViaFacebook(String message) async {
    try {
      final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('$APP_BASE_URL/register')}&quote=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر فيسبوك: $e');
      return false;
    }
  }

  Future<bool> _shareViaTwitter(String message) async {
    try {
      final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر تويتر: $e');
      return false;
    }
  }

  Future<bool> _shareViaInstagram(String message) async {
    try {
      final url = 'instagram://share?text=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      
      final webUrl = 'https://www.instagram.com/';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
        return true;
      }
      
      return false;
    } catch (e) {
      print('فشل في المشاركة عبر إنستجرام: $e');
      return false;
    }
  }

  Future<bool> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      print('فشل في النسخ إلى الحافظة: $e');
      return false;
    }
  }

  // ============ MÉTHODES UTILITAIRES ============

  String _shortenUrl(String url) {
    return url;
  }

  String _getCampaignTypeText(CampaignType type) {
    switch (type) {
      case CampaignType.open:
        return '🌍 حملة مفتوحة لجميع المناطق';
      case CampaignType.regional:
        return '📍 حملة إقليمية';
      case CampaignType.precise:
        return '🎯 حملة دقيقة';
    }
  }

  String _getTimeRemaining(DateTime? endDate) {
    if (endDate == null) return 'مفتوحة';
    
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} يوم متبقي';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ساعة متبقية';
    } else {
      return 'تنتهي قريباً';
    }
  }

  String _generateHashtags(String title) {
    final words = title.split(' ');
    final hashtags = words.take(3).map((word) => word.replaceAll(RegExp(r'[^\w]'), ''));
    return hashtags.join('_');
  }

  // ============ AUTRES MÉTHODES DE PARTAGE ============

  Future<bool> shareEarningsAchievement({
    required double earnings,
    required int totalClicks,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generateEarningsAchievementMessage(earnings, totalClicks);
      await Share.share(message, subject: 'إنجاز رائع على ReShare! 🎉');
      return true;
    } catch (e) {
      print('فشل في مشاركة الإنجاز: $e');
      return false;
    }
  }

  String _generateEarningsAchievementMessage(double earnings, int totalClicks) {
    return '''
🎉 إنجاز رائع على ReShare!
لقد حققت ${earnings.toStringAsFixed(3)} دينار من خلال $totalClicks نقرة ناجحة! 💰
ReShare تطبيق رائع لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.
✨ جربها بنفسك: $APP_BASE_URL
✅ أرباح حقيقية | ✅ سحب أموال سهل | ✅ حملات متنوعة
#ReShare #أرباح_إضافية #إنجاز
''';
  }

  Future<bool> sharePerformanceStats({
    required int totalClicks,
    required double totalEarnings,
    required int referralCount,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generatePerformanceStatsMessage(totalClicks, totalEarnings, referralCount);
      await Share.share(message, subject: 'إحصائيات أدائي على ReShare 📊');
      return true;
    } catch (e) {
      print('فشل في مشاركة الإحصائيات: $e');
      return false;
    }
  }

  String _generatePerformanceStatsMessage(int totalClicks, double totalEarnings, int referralCount) {
    return '''
📊 إحصائيات أدائي على ReShare:
✅ $totalClicks نقرة ناجحة
💰 ${totalEarnings.toStringAsFixed(3)} دينار أرباح
👥 $referralCount صديق مدعو
🎯 متوسط الربح: ${(totalEarnings / totalClicks).toStringAsFixed(3)} دينار/نقرة
ReShare منصة رائعة لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.
🔗 انضم الآن وابدأ رحلتك: $APP_BASE_URL
#ReShare #إحصائيات_الأداء #ربح_من_الإنترنت
''';
  }

  Future<bool> shareApp() async {
    try {
      const message = '''
📱 حمل تطبيق ReShare الآن!
تطبيق رائع لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.
✨ المميزات:
✅ أرباح حقيقية من المشاركة
✅ حملات متنوعة يومياً
✅ سحب أموال بسهولة
✅ نظام إحالة بمكافآت
🔗 حمل التطبيق الآن: $APP_BASE_URL
#ReShare #دخل_إضافي #تطبيق_ربح
''';
      await Share.share(message);
      return true;
    } catch (e) {
      print('فشل في مشاركة التطبيق: $e');
      return false;
    }
  }
}