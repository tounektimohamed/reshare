import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../../data/models/campaign_model.dart';

/// خدمة المشاركة - تدير جميع عمليات مشاركة المحتوى على المنصات المختلفة
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// مشاركة حملة إعلانية
  Future<bool> shareCampaign({
    required CampaignModel campaign,
    required String shareLink,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generateCampaignShareMessage(campaign, shareLink);
      
      await Share.share(
        message,
        subject: 'شارك واربح مع ReShare 🚀',
      );

      return true;
    } catch (e) {
      print('فشل في مشاركة الحملة: $e');
      return false;
    }
  }

  /// إنشاء رسالة مشاركة الحملة
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

  /// إنشاء رسالة مشاركة الإحالة
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
      final referralLink = 'https://reshare.tn/register?ref=$referralCode';
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

  /// إنشاء رسالة الدعوة
  String _generateInvitationMessage(String referralCode, String referralLink) {
    return '''
مرحباً! 👋

أود دعوتك للانضمام إلى ReShare، منصة رائعة لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.

🎯 لماذا ReShare؟
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

  /// المشاركة عبر واتساب
  Future<bool> _shareViaWhatsApp(String phoneNumber, String message) async {
    try {
      // تنظيف رقم الهاتف
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

  /// المشاركة عبر الرسائل النصية
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

  /// المشاركة عبر البريد الإلكتروني
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

  /// المشاركة عبر تليجرام
  Future<bool> _shareViaTelegram(String username, String message) async {
    try {
      final url = 'https://t.me/share/url?url=${Uri.encodeComponent('https://reshare.tn')}&text=${Uri.encodeComponent(message)}';
      
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

  /// المشاركة عبر فيسبوك
  Future<bool> _shareViaFacebook(String message) async {
    try {
      final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('https://reshare.tn')}&quote=${Uri.encodeComponent(message)}';
      
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

  /// المشاركة عبر تويتر
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

  /// المشاركة عبر إنستجرام
  Future<bool> _shareViaInstagram(String message) async {
    try {
      // Note: Instagram doesn't support direct sharing via URL scheme for text
      // This will open the app and user can manually share
      final url = 'instagram://share?text=${Uri.encodeComponent(message)}';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      
      // Fallback to Instagram web
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

  /// نسخ إلى الحافظة
  Future<bool> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      print('فشل في النسخ إلى الحافظة: $e');
      return false;
    }
  }

  /// مشاركة إنجازات الأرباح
  Future<bool> shareEarningsAchievement({
    required double earnings,
    required int totalClicks,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generateEarningsAchievementMessage(earnings, totalClicks);

      await Share.share(
        message,
        subject: 'إنجاز رائع على ReShare! 🎉',
      );

      return true;
    } catch (e) {
      print('فشل في مشاركة الإنجاز: $e');
      return false;
    }
  }

  /// إنشاء رسالة إنجاز الأرباح
  String _generateEarningsAchievementMessage(double earnings, int totalClicks) {
    return '''
🎉 إنجاز رائع على ReShare!

لقد حققت ${earnings.toStringAsFixed(3)} دينار من خلال $totalClicks نقرة ناجحة! 💰

ReShare تطبيق رائع لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.

✨ جربها بنفسك:
https://reshare.tn

✅ أرباح حقيقية
✅ سحب أموال سهل
✅ حملات متنوعة

#ReShare #أرباح_إضافية #إنجاز
''';
  }

  /// مشاركة إحصائيات الأداء
  Future<bool> sharePerformanceStats({
    required int totalClicks,
    required double totalEarnings,
    required int referralCount,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generatePerformanceStatsMessage(
        totalClicks, 
        totalEarnings, 
        referralCount
      );

      await Share.share(
        message,
        subject: 'إحصائيات أدائي على ReShare 📊',
      );

      return true;
    } catch (e) {
      print('فشل في مشاركة الإحصائيات: $e');
      return false;
    }
  }

  /// إنشاء رسالة إحصائيات الأداء
  String _generatePerformanceStatsMessage(int totalClicks, double totalEarnings, int referralCount) {
    return '''
📊 إحصائيات أدائي على ReShare:

✅ $totalClicks نقرة ناجحة
💰 ${totalEarnings.toStringAsFixed(3)} دينار أرباح
👥 $referralCount صديق مدعو
🎯 متوسط الربح: ${(totalEarnings / totalClicks).toStringAsFixed(3)} دينار/نقرة

ReShare منصة رائعة لتحقيق دخل إضافي من خلال مشاركة الحملات الإعلانية.

🔗 انضم الآن وابدأ رحلتك:
https://reshare.tn

#ReShare #إحصائيات_الأداء #ربح_من_الإنترنت
''';
  }

  /// مشاركة مكافأة الإحالة
  Future<bool> shareReferralReward({
    required String friendName,
    required double rewardAmount,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? _generateReferralRewardMessage(friendName, rewardAmount);

      await Share.share(
        message,
        subject: 'مكافأة إحالة جديدة! 🎁',
      );

      return true;
    } catch (e) {
      print('فشل في مشاركة مكافأة الإحالة: $e');
      return false;
    }
  }

  /// إنشاء رسالة مكافأة الإحالة
  String _generateReferralRewardMessage(String friendName, double rewardAmount) {
    return '''
🎁 مكافأة إحالة جديدة!

لقد أكمل صديقي $friendName النقرات المطلوبة، وتم إضافة $rewardAmount دينار إلى رصيدي! 🎉

ReShare تطبيق رائع لا يمكنك من تحقيق أرباح من مشاركتك فقط، بل أيضاً من خلال إحالة الأصدقاء!

✨ المميزات:
• أرباح من مشاركتك
• مكافآت من إحالة الأصدقاء
• سحب أموال بسهولة
• حملات متنوعة يومياً

🔗 انضم الآن:
https://reshare.tn

#ReShare #مكافأة_الإحالة #ربح_مع_الأصدقاء
''';
  }

  /// مشاركة حملة محددة مع تصميم مخصص
  Future<bool> shareCustomCampaign({
    required CampaignModel campaign,
    required String shareLink,
    required String templateType,
    Map<String, dynamic>? customData,
  }) async {
    try {
      String message;
      
      switch (templateType) {
        case 'urgent':
          message = _generateUrgentCampaignMessage(campaign, shareLink);
          break;
        case 'limited':
          message = _generateLimitedCampaignMessage(campaign, shareLink);
          break;
        case 'high_reward':
          message = _generateHighRewardCampaignMessage(campaign, shareLink);
          break;
        case 'simple':
          message = _generateSimpleCampaignMessage(campaign, shareLink);
          break;
        default:
          message = _generateCampaignShareMessage(campaign, shareLink);
      }

      // إضافة البيانات المخصصة إذا وجدت
      if (customData != null) {
        message += '\n\n${customData['additionalText'] ?? ''}';
      }

      await Share.share(message);
      return true;
    } catch (e) {
      print('فشل في المشاركة المخصصة: $e');
      return false;
    }
  }

  /// رسالة حملة عاجلة
  String _generateUrgentCampaignMessage(CampaignModel campaign, String shareLink) {
    return '''
🚨 حملة عاجلة على ReShare!

${campaign.title}

⏰ محدودة الوقت - إنتهز الفرصة الآن!

${campaign.description}

🎯 أرباح: ${campaign.participantEarnings.toStringAsFixed(3)} دينار/نقرة
🔗 ${_shortenUrl(shareLink)}

#ReShare #عاجل #فرصة
''';
  }

  /// رسالة حملة محدودة
  String _generateLimitedCampaignMessage(CampaignModel campaign, String shareLink) {
    return '''
🎯 حملة محدودة على ReShare!

${campaign.title}

${campaign.description}

💰 ${campaign.remainingClicks} نقرة متبقية فقط!
🎁 أرباح: ${campaign.participantEarnings.toStringAsFixed(3)} دينار/نقرة

🔗 شارك الآن:
${_shortenUrl(shareLink)}

#ReShare #محدود #إنتهاز_الفرصة
''';
  }

  /// رسالة حملة بمكافآت عالية
  String _generateHighRewardCampaignMessage(CampaignModel campaign, String shareLink) {
    return '''
💰 حملة بمكافآت عالية على ReShare!

${campaign.title}

${campaign.description}

🎁 أرباح مميزة: ${campaign.participantEarnings.toStringAsFixed(3)} دينار/نقرة!
⭐ فرصة لا تعوض!

🔗 ${_shortenUrl(shareLink)}

#ReShare #مكافآت_عالية #فرصة_ذهبية
''';
  }

  /// رسالة حملة مبسطة
  String _generateSimpleCampaignMessage(CampaignModel campaign, String shareLink) {
    return '''
📱 ReShare

${campaign.title}

${campaign.description}

🎯 اربح ${campaign.participantEarnings.toStringAsFixed(3)} دينار لكل نقرة

${_shortenUrl(shareLink)}

#ReShare
''';
  }

  // ============ METHODS HELPERS ============

  /// تقصير الرابط (يمكن استبداله بخدمة تقصير روابط حقيقية)
  String _shortenUrl(String url) {
    // في الإصدار الحالي نعود الرابط كما هو
    // يمكن إضافة خدمة تقصير رواق مثل bit.ly أو rebrand.ly
    return url;
  }

  /// الحصول على نص نوع الحملة
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

  /// الحصول على الوقت المتبقي
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

  /// إنشاء هاشتاقات من عنوان الحملة
  String _generateHashtags(String title) {
    final words = title.split(' ');
    final hashtags = words.take(3).map((word) => word.replaceAll(RegExp(r'[^\w]'), ''));
    return hashtags.join('_');
  }

  /// فتح رابط خارجي
  Future<bool> launchExternalUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return true;
      }
      return false;
    } catch (e) {
      print('فشل في فتح الرابط: $e');
      return false;
    }
  }

  /// مشاركة تطبيق ReShare
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

🔗 حمل التطبيق الآن:
https://reshare.tn/download

#ReShare #دخل_إضافي #تطبيق_ربح
''';

      await Share.share(message);
      return true;
    } catch (e) {
      print('فشل في مشاركة التطبيق: $e');
      return false;
    }
  }

  /// مشاركة نجاح السحب
  Future<bool> shareWithdrawalSuccess({
    required double amount,
    required String method,
    String? customMessage,
  }) async {
    try {
      final message = customMessage ?? '''
✅ تم سحب ${amount.toStringAsFixed(3)} دينار بنجاح!

طريقة السحب: $method

ReShare تطبيق موثوق لتحقيق دخل إضافي وسحب الأموال بسهولة.

🔗 جرب التطبيق:
https://reshare.tn

#ReShare #سحب_ناجح #ربح_حقيقي
''';

      await Share.share(message);
      return true;
    } catch (e) {
      print('فشل في مشاركة نجاح السحب: $e');
      return false;
    }
  }
}