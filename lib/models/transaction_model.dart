class Transaction {
  final int? id;
  final int walletId;
  final String? comment;
  final String type; // 'expense' | 'income' | 'transfer'
  final double amount;
  final DateTime date;
  final int? categoryId;
  final String currency;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.walletId,
    this.comment,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    required this.currency,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      comment: map['comment'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int?,
      currency: map['currency'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'comment': comment,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'currency': currency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? walletId,
    String? comment,
    String? type,
    double? amount,
    DateTime? date,
    int? categoryId,
    String? currency,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      comment: comment ?? this.comment,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction{id: $id, walletId: $walletId, type: $type, amount: $amount}';
}