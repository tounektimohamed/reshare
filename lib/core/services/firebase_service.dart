import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// خدمة Firebase الأساسية - تجمع جميع خدمات Firebase في مكان واحد
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // حالات خدمات Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Getters للوصول إلى الخدمات
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;

  /// الحصول على المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// التحقق من اتصال Firebase
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// إنشاء حساب جديد
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// إرسال بريد إلكتروني للتحقق
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// تحديث ملف تعريف المستخدم في Firebase Auth
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }
        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }
      }
    } catch (e) {
      throw Exception('فشل في تحديث ملف التعريف: $e');
    }
  }

  /// تحديث كلمة المرور
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  /// إعادة المصادقة
  Future<void> reauthenticateWithCredential(AuthCredential credential) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reauthenticateWithCredential(credential);
    }
  }

  /// حذف المستخدم
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// رفع صورة إلى Storage
  Future<String> uploadImage({
    required String path,
    required Uint8List fileBytes,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref.putData(fileBytes);
      return await task.ref.getDownloadURL();
    } catch (e) {
      throw Exception('فشل في رفع الصورة: $e');
    }
  }

  /// حذف صورة من Storage
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('فشل في حذف الصورة: $e');
    }
  }

  /// الحصول على token الإشعارات
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('فشل في الحصول على FCM token: $e');
      return null;
    }
  }

  /// الاشتراك في مواضيع الإشعارات
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('فشل في الاشتراك في الموضوع: $e');
    }
  }

  /// إلغاء الاشتراك من مواضيع الإشعارات
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('فشل في إلغاء الاشتراك من الموضوع: $e');
    }
  }

  /// تهيئة الإشعارات
  Future<void> initializeNotifications() async {
    // طلب الأذونات
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // الحصول على token
    final token = await getFCMToken();
    if (token != null) {
      print('FCM Token: $token');
      // حفظ token في قاعدة البيانات
      await _saveFCMToken(token);
    }

    // التعامل مع الإشعارات في الخلفية
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  /// حفظ FCM token في قاعدة البيانات
  Future<void> _saveFCMToken(String token) async {
    final user = currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// معالجة الإشعارات في الواجهة
  void _handleForegroundMessage(RemoteMessage message) {
    print('إشعار في الواجهة: ${message.notification?.title}');
    // يمكن إضافة منطق لعرض الإشعار في التطبيق
  }

  /// معالجة الإشعارات عند فتح التطبيق
  void _handleBackgroundMessage(RemoteMessage message) {
    print('إشعار عند فتح التطبيق: ${message.notification?.title}');
    // يمكن إضافة منطق للتنقل إلى شاشة محددة
  }

  /// التحقق من حالة البريد الإلكتروني
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// إعادة تحميل بيانات المستخدم
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// الحصول على بيانات المستخدم المحدثة
  User? get refreshedUser {
    _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  /// إنشاء AuthCredential من البريد الإلكتروني وكلمة المرور
  AuthCredential createEmailCredential({
    required String email,
    required String password,
  }) {
    return EmailAuthProvider.credential(email: email, password: password);
  }

  /// التحقق من صحة كلمة المرور الحالية
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// إرسال رابط التحقق للبريد الإلكتروني
  Future<void> sendEmailVerificationLink() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// تحديث البريد الإلكتروني
  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.verifyBeforeUpdateEmail(newEmail);
    }
  }

  /// الحصول على معلومات الجلسة
  Future<Map<String, dynamic>> getSessionInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'isAnonymous': user.isAnonymous,
        'metadata': {
          'creationTime': user.metadata.creationTime?.millisecondsSinceEpoch,
          'lastSignInTime': user.metadata.lastSignInTime?.millisecondsSinceEpoch,
        },
        'providerData': user.providerData.map((info) => {
          'providerId': info.providerId,
          'uid': info.uid,
          'displayName': info.displayName,
          'email': info.email,
          'photoURL': info.photoURL,
        }).toList(),
      };
    }
    return {};
  }
}