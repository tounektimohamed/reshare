
class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String? description;
  final String? reference;
  final DateTime createdAt;
  final DateTime? processedAt;
  final double? fees;
  final double? netAmount;
  final String? paymentMethod;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    this.currency = 'TND',
    this.status = TransactionStatus.pending,
    this.description,
    this.reference,
    required this.createdAt,
    this.processedAt,
    this.fees,
    double? netAmount,
    this.paymentMethod,
  }) : netAmount = netAmount ?? (amount - (fees ?? 0));

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: TransactionType.values[map['type'] ?? 0],
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'TND',
      status: TransactionStatus.values[map['status'] ?? 0],
      description: map['description'],
      reference: map['reference'],
      createdAt: DateTime.parse(map['createdAt']),
      processedAt: map['processedAt'] != null ? DateTime.parse(map['processedAt']) : null,
      fees: map['fees']?.toDouble(),
      netAmount: map['netAmount']?.toDouble(),
      paymentMethod: map['paymentMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.index,
      'amount': amount,
      'currency': currency,
      'status': status.index,
      'description': description,
      'reference': reference,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'fees': fees,
      'netAmount': netAmount,
      'paymentMethod': paymentMethod,
    };
  }
}

enum TransactionType { earning, referral, withdrawal, refund, bonus }
enum TransactionStatus { pending, processing, completed, failed, cancelled }