import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';

/// مستودع المعاملات - مسؤول عن جميع العمليات المالية في قاعدة البيانات
class TransactionRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  TransactionRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? Uuid();

  // مراجع المجموعات
  CollectionReference get _transactionsCollection => _firestore.collection('transactions');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// إنشاء معاملة جديدة
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      await _transactionsCollection.doc(transaction.id).set(transaction.toMap());
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء المعاملة: $e');
    }
  }

  /// جلب معاملات المستخدم
 Future<List<TransactionModel>> getUserTransactions({
  required String userId,
  int limit = 50,
  bool descending = true,
}) async {
  try {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Tri localement selon createdAt
    transactions.sort((a, b) => descending
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب معاملات المستخدم: $e');
  }
}

/// جلب معاملات المستخدم بنطاق زمني (بدون index)
Future<List<TransactionModel>> getUserTransactionsByDate({
  required String userId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((t) =>
            t.createdAt.isAfter(startDate) &&
            t.createdAt.isBefore(endDate))
        .toList();

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions;
  } catch (e) {
    throw Exception('فشل في جلب معاملات المستخدم بالتاريخ: $e');
  }
}

/// جلب معاملات المستخدم حسب النوع (بدون index)
Future<List<TransactionModel>> getUserTransactionsByType({
  required String userId,
  required TransactionType type,
  int limit = 50,
}) async {
  try {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.index)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب معاملات المستخدم حسب النوع: $e');
  }
}

/// جلب معاملات السحب للمستخدم (بدون index)
Future<List<TransactionModel>> getUserWithdrawals({
  required String userId,
  int limit = 20,
}) async {
  try {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: TransactionType.withdrawal.index)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب معاملات السحب: $e');
  }
}

/// جلب معاملات الأرباح للمستخدم (بدون index)
Future<List<TransactionModel>> getUserEarnings({
  required String userId,
  int limit = 50,
}) async {
  try {
    final snapshot = await _transactionsCollection
        .where('userId', isEqualTo: userId)
        .get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((t) => [
              TransactionType.earning.index,
              TransactionType.referral.index,
              TransactionType.bonus.index,
            ].contains(t.type))
        .toList();

    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب معاملات الأرباح: $e');
  }
}

  /// جلب معاملة محددة
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final doc = await _transactionsCollection.doc(transactionId).get();
      if (doc.exists) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب المعاملة: $e');
    }
  }

  /// تحديث حالة المعاملة
  Future<void> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
    String? processorId,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status.index,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == TransactionStatus.processing || status == TransactionStatus.completed) {
        updateData['processedAt'] = FieldValue.serverTimestamp();
        if (processorId != null) {
          updateData['processorId'] = processorId;
        }
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      await _transactionsCollection.doc(transactionId).update(updateData);
    } catch (e) {
      throw Exception('فشل في تحديث حالة المعاملة: $e');
    }
  }

  /// إنشاء معاملة أرباح من النقرات
  Future<TransactionModel> createEarningTransaction({
    required String userId,
    required double amount,
    required String campaignId,
    required String clickId,
    String? description,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        type: TransactionType.earning,
        amount: amount,
        status: TransactionStatus.completed,
        description: description ?? 'أرباح من نقرة صالحة',
        reference: clickId,
        createdAt: DateTime.now(),
        fees: 0.0, // لا توجد رسوم على الأرباح من النقرات
      );

      await createTransaction(transaction);
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء معاملة الأرباح: $e');
    }
  }

  /// إنشاء معاملة مكافأة إحالة
  Future<TransactionModel> createReferralTransaction({
    required String userId,
    required double amount,
    required String referralId,
    String? description,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        type: TransactionType.referral,
        amount: amount,
        status: TransactionStatus.completed,
        description: description ?? 'مكافأة إحالة',
        reference: referralId,
        createdAt: DateTime.now(),
        fees: 0.0, // لا توجد رسوم على مكافآت الإحالة
      );

      await createTransaction(transaction);
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء معاملة الإحالة: $e');
    }
  }

  /// إنشاء معاملة سحب
  Future<TransactionModel> createWithdrawalTransaction({
    required String userId,
    required double amount,
    required String paymentMethod,
    required Map<String, dynamic> paymentDetails,
    String? description,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final fees = _calculateWithdrawalFee(amount);
      final netAmount = amount - fees;

      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        type: TransactionType.withdrawal,
        amount: amount,
        status: TransactionStatus.pending,
        description: description ?? 'طلب سحب أموال',
        paymentMethod: paymentMethod,
        fees: fees,
        netAmount: netAmount,
        createdAt: DateTime.now(),
      );

      // إضافة تفاصيل الدفع إذا كانت متوفرة
      if (paymentDetails.isNotEmpty) {
        transaction.toMap().addAll({
          'bankName': paymentDetails['bankName'],
          'accountNumber': paymentDetails['accountNumber'],
          'recipientName': paymentDetails['recipientName'],
        });
      }

      await createTransaction(transaction);
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء معاملة السحب: $e');
    }
  }

  /// إنشاء معاملة مكافأة
  Future<TransactionModel> createBonusTransaction({
    required String userId,
    required double amount,
    required String reason,
    String? reference,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        type: TransactionType.bonus,
        amount: amount,
        status: TransactionStatus.completed,
        description: 'مكافأة: $reason',
        reference: reference,
        createdAt: DateTime.now(),
        fees: 0.0, // لا توجد رسوم على المكافآت
      );

      await createTransaction(transaction);
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء معاملة المكافأة: $e');
    }
  }

  /// إنشاء معاملة استرداد
  Future<TransactionModel> createRefundTransaction({
    required String userId,
    required double amount,
    required String originalTransactionId,
    required String reason,
  }) async {
    try {
      final transactionId = _uuid.v4();
      final transaction = TransactionModel(
        id: transactionId,
        userId: userId,
        type: TransactionType.refund,
        amount: amount,
        status: TransactionStatus.completed,
        description: 'استرداد: $reason',
        reference: originalTransactionId,
        createdAt: DateTime.now(),
        fees: 0.0, // لا توجد رسوم على الاسترداد
      );

      await createTransaction(transaction);
      return transaction;
    } catch (e) {
      throw Exception('فشل في إنشاء معاملة الاسترداد: $e');
    }
  }

  /// حساب رسوم السحب
  double _calculateWithdrawalFee(double amount) {
    // رسوم ثابتة + نسبة مئوية
    const double fixedFee = 1.0; // 1 دينار رسوم ثابتة
    const double percentageFee = 0.01; // 1% رسوم نسبية
    
    return fixedFee + (amount * percentageFee);
  }

  /// جلب إحصائيات المعاملات للمستخدم
  Future<TransactionStats> getUserTransactionStats({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _transactionsCollection.where('userId', isEqualTo: userId);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      return _calculateTransactionStats(transactions);
    } catch (e) {
      throw Exception('فشل في جلب إحصائيات المعاملات: $e');
    }
  }

  /// حساب إحصائيات المعاملات
  TransactionStats _calculateTransactionStats(List<TransactionModel> transactions) {
    double totalEarnings = 0;
    double totalWithdrawals = 0;
    double totalBonuses = 0;
    double totalReferrals = 0;
    double totalRefunds = 0;

    final statusCounts = <TransactionStatus, int>{};
    final typeCounts = <TransactionType, int>{};

    for (final transaction in transactions) {
      // تحديث العدادات حسب النوع
      typeCounts[transaction.type] = (typeCounts[transaction.type] ?? 0) + 1;
      statusCounts[transaction.status] = (statusCounts[transaction.status] ?? 0) + 1;

      // تحديث المبالغ حسب النوع
      switch (transaction.type) {
        case TransactionType.earning:
          totalEarnings += transaction.netAmount ?? transaction.amount;
          break;
        case TransactionType.withdrawal:
          totalWithdrawals += transaction.amount;
          break;
        case TransactionType.bonus:
          totalBonuses += transaction.netAmount ?? transaction.amount;
          break;
        case TransactionType.referral:
          totalReferrals += transaction.netAmount ?? transaction.amount;
          break;
        case TransactionType.refund:
          totalRefunds += transaction.netAmount ?? transaction.amount;
          break;
      }
    }

    return TransactionStats(
      totalTransactions: transactions.length,
      totalEarnings: totalEarnings,
      totalWithdrawals: totalWithdrawals,
      totalBonuses: totalBonuses,
      totalReferrals: totalReferrals,
      totalRefunds: totalRefunds,
      netEarnings: totalEarnings + totalBonuses + totalReferrals + totalRefunds - totalWithdrawals,
      statusCounts: statusCounts,
      typeCounts: typeCounts,
    );
  }

  /// جلب المعاملات الأخيرة
  Future<List<TransactionModel>> getRecentTransactions({
  int limit = 10,
  TransactionType? type,
}) async {
  try {
    Query query = _transactionsCollection;

    // Filtrer localement par type si nécessaire
    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    final snapshot = await query.get();

    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Tri local par date (du plus récent au plus ancien)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limiter le nombre de résultats
    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب المعاملات الأخيرة: $e');
  }
}

  /// البحث في المعاملات
  Future<List<TransactionModel>> searchTransactions({
    required String userId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final allTransactions = await getUserTransactions(userId: userId, limit: 100);

      return allTransactions.where((transaction) =>
          transaction.description?.toLowerCase().contains(query.toLowerCase()) == true ||
          transaction.reference?.toLowerCase().contains(query.toLowerCase()) == true ||
          transaction.id.toLowerCase().contains(query.toLowerCase())
      ).take(limit).toList();
    } catch (e) {
      throw Exception('فشل في البحث في المعاملات: $e');
    }
  }

 /// جلب المعاملات التي تحتاج إلى معالجة بدون الحاجة إلى فهرس Firestore
Future<List<TransactionModel>> getPendingTransactions({
  TransactionType? type,
  int limit = 50,
}) async {
  try {
    Query query = _transactionsCollection
        .where('status', isEqualTo: TransactionStatus.pending.index);

    // Si le type est précisé, on filtre aussi dessus
    if (type != null) {
      query = query.where('type', isEqualTo: type.index);
    }

    final snapshot = await query.get();

    // Conversion des documents Firestore en objets TransactionModel
    final transactions = snapshot.docs
        .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Tri local (du plus récent au plus ancien)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Limiter le nombre de résultats
    return transactions.take(limit).toList();
  } catch (e) {
    throw Exception('فشل في جلب المعاملات المعلقة: $e');
  }
}


 /// جلب إجمالي الأرباح الشهرية
Future<double> getMonthlyEarnings(String userId) async {
  try {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final transactions = await getUserTransactionsByDate(
      userId: userId,
      startDate: monthStart,
      endDate: monthEnd,
    );

    double totalEarnings = 0.0; // ✅ Déclarer explicitement comme double
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.earning && 
          transaction.status == TransactionStatus.completed) {
        totalEarnings += transaction.netAmount ?? transaction.amount; // ✅ Maintenant ça fonctionne
      }
    }
    
    return totalEarnings;
  } catch (e) {
    throw Exception('فشل في جلب الأرباح الشهرية: $e');
  }
}

/// جلب إجمالي السحوبات الشهرية
Future<double> getMonthlyWithdrawals(String userId) async {
  try {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final transactions = await getUserTransactionsByDate(
      userId: userId,
      startDate: monthStart,
      endDate: monthEnd,
    );

    double totalWithdrawals = 0.0; // ✅ Déclarer explicitement comme double
    for (final transaction in transactions) {
      if (transaction.type == TransactionType.withdrawal && 
          transaction.status == TransactionStatus.completed) {
        totalWithdrawals += transaction.amount; // ✅ Maintenant ça fonctionne
      }
    }
    
    return totalWithdrawals;
  } catch (e) {
    throw Exception('فشل في جلب السحوبات الشهرية: $e');
  }
}
  /// إنشاء معرف فريد للمعاملة
  String generateTransactionId() {
    return _uuid.v4();
  }

  /// حذف المعاملة (لأغراض التطوير فقط)
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _transactionsCollection.doc(transactionId).delete();
    } catch (e) {
      throw Exception('فشل في حذف المعاملة: $e');
    }
  }

  /// تحديث ملاحظات المعاملة
  Future<void> updateTransactionNotes({
    required String transactionId,
    required String notes,
  }) async {
    try {
      await _transactionsCollection.doc(transactionId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث ملاحظات المعاملة: $e');
    }
  }

  /// جلب تاريخ المعاملات للمخطط البياني
  Future<List<TransactionHistory>> getTransactionHistory({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    TransactionType? type,
  }) async {
    try {
      final transactions = await getUserTransactionsByDate(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final filteredTransactions = type != null
          ? transactions.where((t) => t.type == type).toList()
          : transactions;

      // تجميع المعاملات حسب التاريخ
      final dailyTransactions = <DateTime, List<TransactionModel>>{};
      
      for (final transaction in filteredTransactions) {
        final date = DateTime(
          transaction.createdAt.year,
          transaction.createdAt.month,
          transaction.createdAt.day,
        );
        
        if (!dailyTransactions.containsKey(date)) {
          dailyTransactions[date] = [];
        }
        dailyTransactions[date]!.add(transaction);
      }

      return dailyTransactions.entries.map((entry) {
        final date = entry.key;
        final dailyTransactions = entry.value;
        
        final dailyEarnings = dailyTransactions
            .where((t) => t.type == TransactionType.earning)
            .fold(0.0, (sum, t) => sum + (t.netAmount ?? t.amount));
            
        final dailyWithdrawals = dailyTransactions
            .where((t) => t.type == TransactionType.withdrawal)
            .fold(0.0, (sum, t) => sum + t.amount);

        return TransactionHistory(
          date: date,
          earnings: dailyEarnings,
          withdrawals: dailyWithdrawals,
          transactionCount: dailyTransactions.length,
        );
      }).toList();
    } catch (e) {
      throw Exception('فشل في جلب تاريخ المعاملات: $e');
    }
  }
}


// ============ MODÈLES DE STATISTIQUES ============

/// إحصائيات المعاملات
class TransactionStats {
  final int totalTransactions;
  final double totalEarnings;
  final double totalWithdrawals;
  final double totalBonuses;
  final double totalReferrals;
  final double totalRefunds;
  final double netEarnings;
  final Map<TransactionStatus, int> statusCounts;
  final Map<TransactionType, int> typeCounts;

  TransactionStats({
    required this.totalTransactions,
    required this.totalEarnings,
    required this.totalWithdrawals,
    required this.totalBonuses,
    required this.totalReferrals,
    required this.totalRefunds,
    required this.netEarnings,
    required this.statusCounts,
    required this.typeCounts,
  });

  /// إجمالي الدخل (أرباح + مكافآت + إحالات)
  double get totalIncome => totalEarnings + totalBonuses + totalReferrals + totalRefunds;

  /// نسبة النجاح (المعاملات المكتملة)
  double get successRate {
    return totalTransactions > 0 
        ? (statusCounts[TransactionStatus.completed] ?? 0) / totalTransactions * 100
        : 0.0;
  }

  /// متوسط قيمة المعاملة
  double get averageTransactionValue {
    return totalTransactions > 0 ? totalIncome / totalTransactions : 0.0;
  }
}

/// تاريخ المعاملات للمخطط البياني
class TransactionHistory {
  final DateTime date;
  final double earnings;
  final double withdrawals;
  final int transactionCount;

  TransactionHistory({
    required this.date,
    required this.earnings,
    required this.withdrawals,
    required this.transactionCount,
  });

  /// صافي الدخل لهذا اليوم
  double get netIncome => earnings - withdrawals;
}