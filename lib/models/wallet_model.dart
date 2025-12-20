
import 'package:flutter/widgets.dart';

class Wallet {
  final int? id;
  final String userId;
  final String name;
  final String color;
  final String currency;
  final double balance;
  final bool isFavorite;
  final bool isArchived;
  final String type; // 'bank' | 'cash'
  final DateTime createdAt;
  final IconData? iconBank;

  const Wallet({
    this.id,
    required this.userId,
    required this.name,
    required this.color,
    required this.currency,
    required this.balance,
    required this.isFavorite,
    required this.isArchived,
    required this.type,
    required this.createdAt,
    this.iconBank,
  });

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      isFavorite: (map['is_favorite'] as int) == 1,
      isArchived: (map['is_archived'] as int) == 1,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      iconBank: map['icon_bank'] != null
          ? IconData(int.parse(map['icon_bank'] as String), fontFamily: 'MaterialIcons')
          : null,
    );
  }

  Map<String, dynamic> toMap() {
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
      'icon_bank': iconBank?.codePoint,
    };
  }

  Wallet copyWith({
    int? id,
    String? userId,
    String? name,
    String? color,
    String? currency,
    double? balance,
    bool? isFavorite,
    bool? isArchived,
    String? type,
    DateTime? createdAt,
    String? iconBank,
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
      iconBank: this.iconBank,
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
}
