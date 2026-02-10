import 'package:uuid/uuid.dart';

class Subscription {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final String? favicon;
  final DateTime createdAt;
  final DateTime billingDate;
  final String walletId;
  final String? categoryId;
  final String? storeId; // Nuevo campo
  final String currency;

  const Subscription({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    this.favicon,
    required this.createdAt,
    required this.billingDate,
    required this.walletId,
    this.categoryId,
    this.storeId,
    required this.currency,
  });

  factory Subscription.create({
    required String userId,
    required String title,
    String? description,
    required double amount,
    String? favicon,
    required DateTime billingDate,
    required String walletId,
    String? categoryId,
    String? storeId,
    required String currency,
  }) {
    return Subscription(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      amount: amount,
      favicon: favicon,
      createdAt: DateTime.now(),
      billingDate: billingDate,
      walletId: walletId,
      categoryId: categoryId,
      storeId: storeId,
      currency: currency,
    );
  }

  factory Subscription.fromLocal(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      favicon: map['favicon'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      billingDate: DateTime.parse(map['billing_date'] as String),
      walletId: map['wallet_id'] as String,
      categoryId: map['category_id'] as String?,
      storeId: map['store_id'] as String?,
      currency: map['currency'] as String,
    );
  }

  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'favicon': favicon,
      'created_at': createdAt.toIso8601String(),
      'billing_date': billingDate.toIso8601String(),
      'wallet_id': walletId,
      'category_id': categoryId,
      'store_id': storeId,
      'currency': currency,
    };
  }

  Subscription copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? amount,
    String? favicon,
    DateTime? createdAt,
    DateTime? billingDate,
    String? walletId,
    String? categoryId,
    String? storeId,
    String? currency,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      favicon: favicon ?? this.favicon,
      createdAt: createdAt ?? this.createdAt,
      billingDate: billingDate ?? this.billingDate,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      storeId: storeId ?? this.storeId,
      currency: currency ?? this.currency,
    );
  }
}
