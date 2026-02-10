import 'package:uuid/uuid.dart';

class Store {
  final String id;
  final String userId;
  final String name;
  final String? website; // For favicon
  final DateTime createdAt;
  final DateTime updatedAt;

  const Store({
    required this.id,
    required this.userId,
    required this.name,
    this.website,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.create({
    required String userId,
    required String name,
    String? website,
  }) {
    final now = DateTime.now();
    return Store(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      website: website,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Store.fromLocal(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      website: map['website'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toLocal() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'website': website,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Store copyWith({
    String? id,
    String? userId,
    String? name,
    String? website,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      website: website ?? this.website,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
