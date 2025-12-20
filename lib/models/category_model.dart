
class Category {
  final int? id;
  final String userId;
  final String name;
  final double monthlyBudget;
  final String? icon;
  final String? color;

  const Category({
    this.id,
    required this.userId,
    required this.name,
    this.monthlyBudget = 0.0,
    this.icon,
    this.color,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'monthly_budget': monthlyBudget,
      'icon': icon,
      'color': color,
    };
  }

  Category copyWith({
    int? id,
    String? userId,
    String? name,
    double? monthlyBudget,
    String? icon,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}