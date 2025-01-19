import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String? parentId;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final List<String>? subCategories;

  const Category({
    required this.id,
    required this.name,
    this.parentId,
    required this.order,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.subCategories,
  });

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      name: map['name'] ?? '',
      parentId: map['parentId'],
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: map['createdBy'],
      updatedBy: map['updatedBy'],
      subCategories: (map['subCategories'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parentId': parentId,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'subCategories': subCategories,
    };
  }
} 