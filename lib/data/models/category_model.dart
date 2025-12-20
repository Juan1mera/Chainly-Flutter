import 'package:uuid/uuid.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final double monthlyBudget;
  final String? icon;
  final String? color;
  final String type; // 'income' | 'expense'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool isSynced;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    this.monthlyBudget = 0.0,
    this.icon,
    this.color,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.version = 1,
    this.isSynced = false,
  });

  factory Category.create({
    required String userId,
    required String name,
    required String type,
    double monthlyBudget = 0.0,
    String? icon,
    String? color,
  }) {
    final now = DateTime.now();
    return Category(
      id: _generateUuid(),
      userId: userId,
      name: name,
      type: type,
      monthlyBudget: monthlyBudget,
      icon: icon,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Category.fromSupabase(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      version: map['version'] as int? ?? 1,
      isSynced: true,
    );
  }

  factory Category.fromLocal(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      type: map['type'] as String,
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
      'name': name,
      'monthly_budget': monthlyBudget,
      'icon': icon,
      'color': color,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
    };
  }

  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'monthly_budget': monthlyBudget,
      'icon': icon,
      'color': color,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'version': version,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    double? monthlyBudget,
    String? icon,
    String? color,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    bool? isSynced,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Category markAsSynced() => copyWith(isSynced: true);

  Category incrementVersion() => copyWith(
        version: version + 1,
        updatedAt: DateTime.now(),
      );

  static String _generateUuid() {
    return const Uuid().v4();
  }
}