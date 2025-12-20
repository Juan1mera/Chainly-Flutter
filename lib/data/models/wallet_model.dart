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
  final int version; 
  final IconData? iconBank;
  final bool isSynced;

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
    this.version = 1,
    this.iconBank,
    this.isSynced = false,
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

  // Desde Supabase (snake_case)
  factory Wallet.fromSupabase(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      currency: map['currency'] as String,
      balance: (map['balance'] as num).toDouble(),
      isFavorite: map['is_favorite'] as bool? ?? false,
      isArchived: map['is_archived'] as bool? ?? false,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: map['version'] as int? ?? 1,
      iconBank: map['icon_bank'] != null
          ? IconData(map['icon_bank'] as int, fontFamily: 'MaterialIcons')
          : null,
      isSynced: true, // Viene de Supabase, está sincronizado
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
      version: map['version'] as int? ?? 1,
      iconBank: map['icon_bank'] != null
          ? IconData(map['icon_bank'] as int, fontFamily: 'MaterialIcons')
          : null,
      isSynced: (map['is_synced'] as int) == 1,
    );
  }

  // Para enviar a Supabase
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'currency': currency,
      'balance': balance,
      'is_favorite': isFavorite,
      'is_archived': isArchived,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'icon_bank': iconBank?.codePoint,
    };
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
      'version': version,
      'icon_bank': iconBank?.codePoint,
      'is_synced': isSynced ? 1 : 0,
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
    int? version,
    IconData? iconBank,
    bool? isSynced,
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
      version: version ?? this.version,
      iconBank: iconBank ?? this.iconBank,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // Marca como sincronizado
  Wallet markAsSynced() => copyWith(isSynced: true);

  // Marca como no sincronizado
  Wallet markAsUnsynced() => copyWith(isSynced: false);

  // Incrementa versión para actualizaciones
  Wallet incrementVersion() => copyWith(
        version: version + 1,
        updatedAt: DateTime.now(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Wallet{id: $id, name: $name, balance: $balance, currency: $currency, synced: $isSynced}';

  // Generador de UUID estándar
  static String _generateUuid() {
    return const Uuid().v4();
  }
}