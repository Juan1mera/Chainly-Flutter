import 'package:uuid/uuid.dart';

class Transaction {
  final String id;
  final String userId;
  final String walletId;
  final String? categoryId;
  final String type; // 'income' | 'expense' | 'transfer'
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isSynced;

  const Transaction({
    required this.id,
    required this.userId,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isSynced = false,
  });

  factory Transaction.create({
    required String userId,
    required String walletId,
    String? categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: _generateUuid(),
      userId: userId,
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Transaction.custom({
    required String id,
    required String userId,
    required String walletId,
    String? categoryId,
    required String type,
    required double amount,
    String? note,
    required DateTime date,
    required DateTime createdAt,
    required DateTime updatedAt,
    int version = 1,
    bool isSynced = false,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      walletId: walletId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      note: note,
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      version: version,
      isSynced: isSynced,
    );
  }

  factory Transaction.fromSupabase(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: map['version'] as int? ?? 1,
      isSynced: true,
    );
  }

  factory Transaction.fromLocal(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? 'local_user', // Fallback for migration
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: map['version'] as int? ?? 1,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? categoryId,
    String? type,
    double? amount,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Transaction markAsSynced() => copyWith(isSynced: true);

  Transaction incrementVersion() => copyWith(
        version: version + 1,
        updatedAt: DateTime.now(),
      );

  static String _generateUuid() {
    return const Uuid().v4();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction{id: $id, walletId: $walletId, categoryId: $categoryId, type: $type, amount: $amount}';
}