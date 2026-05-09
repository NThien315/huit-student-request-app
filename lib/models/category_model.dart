// lib/models/category_model.dart
// TV2 — Thiết kế cấu trúc dữ liệu danh mục yêu cầu (Task 2.2)

import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Model danh mục yêu cầu ──────────────────────────────────────────────────
// Firestore path: /requestCategories/{categoryId}
// Ví dụ: Xin bảng điểm, Xác nhận sinh viên, Phúc khảo...
class CategoryModel {
  final String id;
  final String name;
  final String description;
  final bool isActive; // Admin có thể ẩn danh mục mà không cần xóa
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.createdAt,
  });

  // ── Từ Firestore Document → CategoryModel ──────────────────────────────────
  factory CategoryModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    return CategoryModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── CategoryModel → Map để lưu lên Firestore ───────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CategoryModel copyWith({String? name, String? description, bool? isActive}) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
