import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class Wallet {
  final String id; 
  final String userId;
  final String name;
  final String color;
  final String currency;
  final double balance;
  final bool isFavorite;
  final bool isArchived;
  final String type; // 'bank' | 'cash'
  final DateTime createdAt;
  final DateTime updatedAt;
  final IconData? iconBank;

  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.currency,
    required this.balance,
    this.isFavorite = false,
    this.isArchived = false,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.iconBank,
  });

  factory Wallet.create({
    required String userId,
    required String name,
    required String color,
    required String currency,
    required String type,
    double balance = 0.0,
    IconData? iconBank,
  }) {
    final now = DateTime.now();
    return Wallet(
      id: _generateUuid(),
      userId: userId,
      name: name,
      color: color,
      currency: currency,
      balance: balance,
      type: type,
      createdAt: now,
      updatedAt: now,
      iconBank: iconBank,
    );
  }

  // Desde SQLite local (snake_case)
  factory Wallet.fromLocal(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      isFavorite: (map['is_favorite'] as int) == 1,
      isArchived: (map['is_archived'] as int) == 1,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      iconBank: map['icon_bank'] != null
          ? IconData(map['icon_bank'] as int, fontFamily: 'MaterialIcons')
          : null,
    );
  }

  // Para guardar en SQLite local
  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'currency': currency,
      'balance': balance,
      'is_favorite': isFavorite ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'icon_bank': iconBank?.codePoint,
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    String? color,
    String? currency,
    double? balance,
    bool? isFavorite,
    bool? isArchived,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    IconData? iconBank,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      iconBank: iconBank ?? this.iconBank,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Wallet{id: $id, name: $name, balance: $balance, currency: $currency}';

  // Generador de UUID estándar
  static String _generateUuid() {
    return const Uuid().v4();
  }
}