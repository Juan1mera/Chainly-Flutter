class Transaction {
  final int? id;
  final int walletId;
  final int categoryId; 
  final String type;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.walletId,
    required this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    String? type,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  get comment => null;

  get currency => null;

  @override
  String toString() =>
      'Transaction{id: $id, walletId: $walletId, categoryId: $categoryId, type: $type, amount: $amount}';
}