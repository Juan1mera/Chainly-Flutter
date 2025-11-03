class Category {
  final int? id;
  final String name;
  final double monthlyBudget;
  final String? icon;
  final String? color;

  const Category({
    this.id,
    required this.name,
    this.monthlyBudget = 0.0,
    this.icon,
    this.color,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int?,
      name: map['name'] as String,
      monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'monthly_budget': monthlyBudget,
      'icon': icon,
      'color': color,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    double? monthlyBudget,
    String? icon,
    String? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category{id: $id, name: $name}';
}