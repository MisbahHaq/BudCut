class CategoryModel {
  final String id;
  String name;
  String color;
  num? monthlyCap;
  bool isFixed;
  bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.monthlyCap,
    this.isFixed = false,
    this.isDefault = false,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? color,
    num? monthlyCap,
    bool? isFixed,
    bool? isDefault,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      monthlyCap: monthlyCap ?? this.monthlyCap,
      isFixed: isFixed ?? this.isFixed,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'monthlyCap': monthlyCap,
      'isFixed': isFixed,
      'isDefault': isDefault,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      monthlyCap: (json['monthlyCap'] as num?),
      isFixed: (json['isFixed'] as bool?) ?? false,
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }
}
