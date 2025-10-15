import 'package:flutter/material.dart';

/// نظام الألوان الكامل لتطبيق ReShare - مصمم بعناية للتوافق مع الهوية البصرية
class AppColors {
  // ============ الألوان الأساسية ============
  
  /// اللون الأساسي للتطبيق - أخضر ReShare
  static const MaterialColor primary = MaterialColor(
    0xFF2E7D32,
    <int, Color>{
      50: Color(0xFFE8F5E8),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  /// اللون الثانوي - أزرق
  static const MaterialColor secondary = MaterialColor(
    0xFF2196F3,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  /// اللون التكميلي - برتقالي/ذهبي
  static const MaterialColor accent = MaterialColor(
    0xFFFFC107,
    <int, Color>{
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFECB3),
      200: Color(0xFFFFE082),
      300: Color(0xFFFFD54F),
      400: Color(0xFFFFCA28),
      500: Color(0xFFFFC107),
      600: Color(0xFFFFB300),
      700: Color(0xFFFFA000),
      800: Color(0xFFFF8F00),
      900: Color(0xFFFF6F00),
    },
  );

  // ============ ألوان الحالة ============
  
  /// نجاح - أخضر
  static const MaterialColor success = MaterialColor(
    0xFF388E3C,
    <int, Color>{
      50: Color(0xFFE8F5E8),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );

  /// تحذير - برتقالي
  static const MaterialColor warning = MaterialColor(
    0xFFFFA000,
    <int, Color>{
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFECB3),
      200: Color(0xFFFFE082),
      300: Color(0xFFFFD54F),
      400: Color(0xFFFFCA28),
      500: Color(0xFFFFC107),
      600: Color(0xFFFFB300),
      700: Color(0xFFFFA000),
      800: Color(0xFFFF8F00),
      900: Color(0xFFFF6F00),
    },
  );

  /// خطأ - أحمر
  static const MaterialColor error = MaterialColor(
    0xFFD32F2F,
    <int, Color>{
      50: Color(0xFFFFEBEE),
      100: Color(0xFFFFCDD2),
      200: Color(0xFFEF9A9A),
      300: Color(0xFFE57373),
      400: Color(0xFFEF5350),
      500: Color(0xFFF44336),
      600: Color(0xFFE53935),
      700: Color(0xFFD32F2F),
      800: Color(0xFFC62828),
      900: Color(0xFFB71C1C),
    },
  );

  /// معلومات - أزرق
  static const MaterialColor info = MaterialColor(
    0xFF1976D2,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );

  // ============ الألوان المحايدة ============
  
  /// الخلفية الرئيسية
  static const Color background = Color(0xFFF5F5F5);
  
  /// سطح البطاقات والعناصر
  static const Color surface = Color(0xFFFFFFFF);
  
  /// سطح بديل
  static const Color surfaceVariant = Color(0xFFFAFAFA);
  
  /// حدود وعناصر تفصيلية
  static const Color outline = Color(0xFFE0E0E0);
  
  /// حدود بديلة
  static const Color outlineVariant = Color(0xFFEEEEEE);

  // ============ ألوان النص ============
  
  /// النص الأساسي
  static const Color textPrimary = Color(0xFF212121);
  
  /// النص الثانوي
  static const Color textSecondary = Color(0xFF757575);
  
  /// النص غير النشط
  static const Color textDisabled = Color(0xFF9E9E9E);
  
  /// النص على الخلفيات الملونة
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF212121);
  static const Color textOnError = Color(0xFFFFFFFF);
  static const Color textOnSuccess = Color(0xFFFFFFFF);
  static const Color textOnWarning = Color(0xFF212121);
  static const Color textOnInfo = Color(0xFFFFFFFF);

  // ============ ألوان الحملات ============
  
  /// حملات مفتوحة - أزرق فاتح
  static const Color campaignOpen = Color(0xFF2196F3);
  static const Color campaignOpenLight = Color(0xFFE3F2FD);
  static const Color campaignOpenDark = Color(0xFF1976D2);

  /// حملات إقليمية - برتقالي
  static const Color campaignRegional = Color(0xFFFF9800);
  static const Color campaignRegionalLight = Color(0xFFFFF3E0);
  static const Color campaignRegionalDark = Color(0xFFF57C00);

  /// حملات دقيقة - أخضر
  static const Color campaignPrecise = Color(0xFF4CAF50);
  static const Color campaignPreciseLight = Color(0xFFE8F5E8);
  static const Color campaignPreciseDark = Color(0xFF388E3C);

  // ============ ألوان الأرباح ============
  
  /// أرباح عالية - ذهبي
  static const Color earningsHigh = Color(0xFFFFC107);
  static const Color earningsHighLight = Color(0xFFFFF8E1);
  
  /// أرباح متوسطة - أخضر
  static const Color earningsMedium = Color(0xFF4CAF50);
  static const Color earningsMediumLight = Color(0xFFE8F5E8);
  
  /// أرباح منخفضة - أزرق
  static const Color earningsLow = Color(0xFF2196F3);
  static const Color earningsLowLight = Color(0xFFE3F2FD);

  // ============ ألوان الإحالة ============
  
  /// نظام الإحالة - بنفسجي
  static const Color referralPrimary = Color(0xFF9C27B0);
  static const Color referralLight = Color(0xFFF3E5F5);
  static const Color referralDark = Color(0xFF7B1FA2);

  /// مكافآت الإحالة - وردي
  static const Color referralReward = Color(0xFFE91E63);
  static const Color referralRewardLight = Color(0xFFFCE4EC);

  // ============ ألوان الحالة ============
  
  /// نشط - أخضر
  static const Color statusActive = Color(0xFF4CAF50);
  
  /// معلق - برتقالي
  static const Color statusPending = Color(0xFFFF9800);
  
  /// مكتمل - أزرق
  static const Color statusCompleted = Color(0xFF2196F3);
  
  /// مرفوض - أحمر
  static const Color statusRejected = Color(0xFFF44336);
  
  /// مجمد - رمادي
  static const Color statusFrozen = Color(0xFF9E9E9E);

  // ============ ألوان الأزرار ============
  
  /// زر أساسي
  static const Color buttonPrimary = Color(0xFF2E7D32);
  static const Color buttonPrimaryLight = Color(0xFF4CAF50);
  static const Color buttonPrimaryDark = Color(0xFF1B5E20);

  /// زر ثانوي
  static const Color buttonSecondary = Color(0xFF757575);
  static const Color buttonSecondaryLight = Color(0xFF9E9E9E);
  static const Color buttonSecondaryDark = Color(0xFF424242);

  /// زر ناجح
  static const Color buttonSuccess = Color(0xFF388E3C);
  static const Color buttonSuccessLight = Color(0xFF4CAF50);
  static const Color buttonSuccessDark = Color(0xFF1B5E20);

  /// زر تحذير
  static const Color buttonWarning = Color(0xFFFFA000);
  static const Color buttonWarningLight = Color(0xFFFFC107);
  static const Color buttonWarningDark = Color(0xFFFF6F00);

  /// زر خطأ
  static const Color buttonError = Color(0xFFD32F2F);
  static const Color buttonErrorLight = Color(0xFFF44336);
  static const Color buttonErrorDark = Color(0xFFB71C1C);

  // ============ ألوان التدرجات ============
  
  /// تدرج أساسي
  static final Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary.shade500, primary.shade700],
  );

  /// تدرج ثانوي
  static final Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary.shade500, secondary.shade700],
  );

  /// تدرج نجاح
  static final Gradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success.shade500, success.shade700],
  );

  /// تدرج تحذير
  static final Gradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning.shade500, warning.shade700],
  );

  /// تدرج خطأ
  static final Gradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error.shade500, error.shade700],
  );

  /// تدرج أرباح
  static final Gradient earningsGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [earningsHigh, earningsHigh.withOpacity(0.8)],
  );

  /// تدرج إحالة
  static final Gradient referralGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [referralPrimary, referralDark],
  );

  // ============ ألوان الظلال ============
  
  /// ظلال خفيفة
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // ============ ألوان إضافية ============
  
  /// لون التحميل والتأثيرات
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  /// لون الشفافية
  static const Color transparent = Color(0x00000000);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white50 = Color(0x80FFFFFF);
  static const Color black10 = Color(0x1A000000);
  static const Color black20 = Color(0x33000000);
  static const Color black50 = Color(0x80000000);

  /// ألوان وسائل التواصل الاجتماعي
  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color twitterBlue = Color(0xFF1DA1F2);
  static const Color whatsappGreen = Color(0xFF25D366);
  static const Color instagramPurple = Color(0xFFE4405F);
  static const Color telegramBlue = Color(0xFF0088CC);
  static const Color youtubeRed = Color(0xFFFF0000);
}