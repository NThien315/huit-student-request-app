// ─── Model danh mục yêu cầu ──────────────────────────────────────────────────
// Supabase table: request_categories
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive; 
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  // ── Từ Supabase Row (Map) → CategoryModel ──────────────────────────────────
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'].toString(), // Supabase trả về ID thẳng trong map
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // ── CategoryModel → Map để lưu lên Supabase ───────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? name, 
    String? description, 
    bool? isActive
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  // Fix lỗi màn hình đỏ Dropdown
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}