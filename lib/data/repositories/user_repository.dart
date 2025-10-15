
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 🔥 CRÉATION D'UTILISATEUR AVEC GESTION ROBUSTE
  Future<void> createUser(UserModel user) async {
    try {
      print('🔄 Creating user: ${user.id}');
      
      // S'assurer que toutes les valeurs sont valides
      final userData = user.toMap();
      
      // Valider les données avant sauvegarde
      _validateUserData(userData);
      
      await _usersCollection.doc(user.id).set(userData);
      
      print('✅ User created successfully: ${user.id}');
    } catch (e) {
      print('❌ Error creating user: $e');
      throw Exception('فشل في إنشاء المستخدم: $e');
    }
  }

  /// 🔥 RÉCUPÉRATION D'UTILISATEUR AVEC GESTION D'ERREUR AMÉLIORÉE
  Future<UserModel?> getUserById(String userId) async {
    try {
      print('🔄 Fetching user: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('📊 User data retrieved: ${data.keys}');
        
        final user = UserModel.fromMap({
          ...data,
          'id': doc.id, // S'assurer que l'ID est inclus
        });
        
        print('✅ User loaded: ${user.displayName} (${user.userType})');
        return user;
      } else {
        print('⚠️ User not found: $userId');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching user $userId: $e');
      throw Exception('فشل في جلب بيانات المستخدم: $e');
    }
  }

  /// 🔥 MISE À JOUR D'UTILISATEUR
  Future<void> updateUser(UserModel user) async {
    try {
      print('🔄 Updating user: ${user.id}');
      
      final userData = user.toMap();
      _validateUserData(userData);
      
      await _usersCollection.doc(user.id).update(userData);
      
      print('✅ User updated successfully: ${user.id}');
    } catch (e) {
      print('❌ Error updating user: $e');
      throw Exception('فشل في تحديث بيانات المستخدم: $e');
    }
  }

  /// MISE À JOUR DU DERNIER LOGIN
  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLogin': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Last login updated for: $userId');
    } catch (e) {
      print('❌ Error updating last login: $e');
      throw Exception('فشل في تحديث آخر تسجيل دخول: $e');
    }
  }

  /// MISE À JOUR DU COMPTEUR DE RÉFÉRENCES
  Future<void> updateUserReferralCount({
    required String userId,
    required int newCount,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'referralCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Referral count updated to $newCount for: $userId');
    } catch (e) {
      print('❌ Error updating referral count: $e');
      throw Exception('Failed to update referral count: $e');
    }
  }

  /// 🔥 MISE À JOUR DU SOLDE UTILISATEUR
  Future<void> updateUserBalance({
    required String userId,
    required double amount,
    required bool isEarning,
    String? description,
  }) async {
    try {
      final user = await getUserById(userId);
      if (user != null) {
        final newBalance = isEarning
            ? user.availableBalance + amount
            : user.availableBalance - amount;

        final updateData = {
          'availableBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (isEarning) {
          updateData['totalEarnings'] = user.totalEarnings + amount;
        }

        await _usersCollection.doc(userId).update(updateData);

        // Enregistrer la transaction
        await _recordTransaction(
          userId: userId,
          amount: amount,
          type: isEarning ? 'earning' : 'withdrawal',
          description: description ?? (isEarning ? 'أرباح من النقرات' : 'سحب رصيد'),
        );

        print('✅ Balance updated for $userId: ${isEarning ? '+' : '-'}$amount');
      }
    } catch (e) {
      print('❌ Error updating balance: $e');
      throw Exception('فشل في تحديث الرصيد: $e');
    }
  }

  /// AUGMENTER LE COMPTEUR DE CLICS
  Future<void> incrementUserClicks(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'totalClicks': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Click count incremented for: $userId');
    } catch (e) {
      print('❌ Error incrementing clicks: $e');
      throw Exception('فشل في تحديث عداد النقرات: $e');
    }
  }

  /// AUGMENTER LE COMPTEUR DE RÉFÉRENCES
  Future<void> incrementUserReferrals(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'referralCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Referral count incremented for: $userId');
    } catch (e) {
      print('❌ Error incrementing referrals: $e');
      throw Exception('فشل في تحديث عداد الإحالات: $e');
    }
  }

  /// VÉRIFIER SI UN CODE DE RÉFÉRENCE EXISTE
  Future<bool> checkReferralCodeExists(String referralCode) async {
    try {
      final query = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();
      
      final exists = query.docs.isNotEmpty;
      print('🔍 Referral code $referralCode exists: $exists');
      return exists;
    } catch (e) {
      print('❌ Error checking referral code: $e');
      throw Exception('فشل في التحقق من كود الإحالة: $e');
    }
  }

  /// OBTENIR L'UTILISATEUR PAR CODE DE RÉFÉRENCE
  Future<UserModel?> getUserByReferralCode(String referralCode) async {
    try {
      final query = await _usersCollection
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final user = UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
        print('✅ User found by referral code: ${user.displayName}');
        return user;
      }
      
      print('⚠️ No user found with referral code: $referralCode');
      return null;
    } catch (e) {
      print('❌ Error getting user by referral code: $e');
      throw Exception('فشل في جلب المستخدم بواسطة كود الإحالة: $e');
    }
  }

  /// 🔥 GÉNÉRER UN CODE DE RÉFÉRENCE UNIQUE
  Future<String> generateUniqueReferralCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    String code;
    bool exists;
    int attempts = 0;
    
    do {
      code = '';
      for (int i = 0; i < 6; i++) {
        code += chars[random.nextInt(chars.length)];
      }
      exists = await checkReferralCodeExists(code);
      attempts++;
      
      if (attempts > 10) {
        // Fallback: utiliser un timestamp
        code = 'RS${DateTime.now().millisecondsSinceEpoch % 1000000}';
        exists = await checkReferralCodeExists(code);
        if (!exists) break;
      }
    } while (exists);
    
    print('🎯 Generated unique referral code: $code');
    return code;
  }

  /// MISE À JOUR DES PRÉFÉRENCES DE LOCALISATION
  Future<void> updateLocationPreference({
    required String userId,
    required LocationPreference preference,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'locationPreference': preference.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Location preference updated to ${preference.name} for: $userId');
    } catch (e) {
      print('❌ Error updating location preference: $e');
      throw Exception('فشل في تحديث تفضيلات الموقع: $e');
    }
  }

  /// MISE À JOUR DE L'IMAGE DE PROFIL
  Future<void> updateProfileImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Profile image updated for: $userId');
    } catch (e) {
      print('❌ Error updating profile image: $e');
      throw Exception('فشل في تحديث صورة الملف الشخصي: $e');
    }
  }

  /// MISE À JOUR DU STATUT DE VÉRIFICATION
  Future<void> updateVerificationStatus({
    required String userId,
    required bool isVerified,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Verification status updated to $isVerified for: $userId');
    } catch (e) {
      print('❌ Error updating verification status: $e');
      throw Exception('فشل في تحديث حالة التحقق: $e');
    }
  }

  /// 🔥 MISE À JOUR DU TYPE D'UTILISATEUR
  Future<void> updateUserType({
    required String userId,
    required UserType userType,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'userType': userType.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User type updated to ${userType.name} for: $userId');
    } catch (e) {
      print('❌ Error updating user type: $e');
      throw Exception('فشل في تحديث نوع المستخدم: $e');
    }
  }

  /// SUPPRIMER UN UTILISATEUR (ADMIN SEULEMENT)
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
      print('✅ User deleted: $userId');
    } catch (e) {
      print('❌ Error deleting user: $e');
      throw Exception('فشل في حذف المستخدم: $e');
    }
  }

  /// 🔥 RÉPARER LES DONNÉES UTILISATEUR CORROMPUES
  Future<void> repairUserData(String userId) async {
    try {
      print('🔧 Repairing user data for: $userId');
      
      final user = await getUserById(userId);
      if (user != null) {
        // Recréer l'utilisateur avec des données propres
        await _usersCollection.doc(userId).set(user.toMap(), SetOptions(merge: true));
        print('✅ User data repaired successfully: $userId');
      } else {
        print('⚠️ User not found for repair: $userId');
      }
    } catch (e) {
      print('❌ Error repairing user data: $e');
      throw Exception('فشل في إصلاح بيانات المستخدم: $e');
    }
  }

  /// 🔥 CRÉER UN PROFIL UTILISATEUR PAR DÉFAUT
  Future<UserModel> createDefaultUserProfile({
    required String userId,
    required String email,
    String? displayName,
    UserType userType = UserType.participant,
  }) async {
    try {
      final referralCode = await generateUniqueReferralCode();
      
      final defaultUser = UserModel(
        id: userId,
        email: email,
        displayName: displayName ?? 'مستخدم جديد',
        userType: userType,
        referralCode: referralCode,
        createdAt: DateTime.now(),
        // Tous les autres champs utiliseront les valeurs par défaut
      );

      await createUser(defaultUser);
      print('✅ Default user profile created: $userId');
      
      return defaultUser;
    } catch (e) {
      print('❌ Error creating default user profile: $e');
      throw Exception('فشل في إنشاء الملف الشخصي الافتراضي: $e');
    }
  }

  /// 🔥 ENREGISTRER UNE TRANSACTION
  Future<void> _recordTransaction({
    required String userId,
    required double amount,
    required String type,
    required String description,
  }) async {
    try {
      await _firestore.collection('transactions').add({
        'userId': userId,
        'amount': amount,
        'type': type,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
      print('✅ Transaction recorded: $type - $amount');
    } catch (e) {
      print('❌ Error recording transaction: $e');
      // Ne pas propager l'erreur pour ne pas bloquer l'opération principale
    }
  }

  /// 🔥 VALIDATION DES DONNÉES UTILISATEUR
  void _validateUserData(Map<String, dynamic> data) {
    // Valider les champs numériques
    final numericFields = [
      'totalEarnings', 'availableBalance', 'pendingBalance',
      'totalClicks', 'totalShares', 'referralCount'
    ];
    
    for (final field in numericFields) {
      if (data[field] != null && data[field] is! num) {
        throw Exception('حقل $field يجب أن يكون رقماً');
      }
    }

    // Valider les champs requis
    final requiredFields = ['id', 'email', 'displayName', 'createdAt'];
    for (final field in requiredFields) {
      if (data[field] == null) {
        throw Exception('حقل $field مطلوب');
      }
    }

    // Valider l'email
    final email = data['email']?.toString();
    if (email == null || !email.contains('@')) {
      throw Exception('البريد الإلكتروني غير صالح');
    }
  }

  /// 🔥 RECHERCHER DES UTILISATEURS (ADMIN)
  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 10,
  }) async {
    try {
      // Recherche basique par nom ou email
      final snapshot = await _usersCollection
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: query + 'z')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return UserModel.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      print('❌ Error searching users: $e');
      throw Exception('فشل في البحث عن المستخدمين: $e');
    }
  }

  /// 🔥 OBTENIR LES STATISTIQUES UTILISATEUR
  Future<Map<String, dynamic>> getUserStats(String userId) async {
  try {
    final user = await getUserById(userId);
    if (user == null) {
      throw Exception('المستخدم غير موجود');
    }

    // 🔹 Charger les transactions sans orderBy pour éviter l’index requis
    final transactionsSnapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    // 🔹 Trier localement (par createdAt descendant)
    final recentTransactions = transactionsSnapshot.docs
        .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'amount': data['amount'],
            'type': data['type'],
            'description': data['description'],
            'createdAt': data['createdAt'],
          };
        })
        .where((t) => t['createdAt'] != null)
        .toList()
      ..sort((a, b) {
        final aDate = (a['createdAt'] as Timestamp).toDate();
        final bDate = (b['createdAt'] as Timestamp).toDate();
        return bDate.compareTo(aDate);
      });

    // 🔹 Garder seulement les 5 plus récentes
    final limitedTransactions = recentTransactions.take(5).toList();

    return {
      'user': user,
      'recentTransactions': limitedTransactions,
      'stats': {
        'totalEarnings': user.totalEarnings,
        'availableBalance': user.availableBalance,
        'totalClicks': user.totalClicks,
        'referralCount': user.referralCount,
      },
    };
  } catch (e) {
    print('❌ Error getting user stats: $e');
    throw Exception('فشل في جلب إحصائيات المستخدم: $e');
  }
}

}