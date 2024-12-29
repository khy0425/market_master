import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String productCode;    // productNo를 string으로 변환하여 사용
  final String name;          // productName
  final String description;   // productDetails
  final int originalPrice;    // originalPrice
  final int sellingPrice;    // price
  final int discountRate;    // discountRate
  final String mainCategory; // mainCategory
  final String subCategory;  // subCategory
  final String productImageUrl;     // 대표 이미지
  final String productDetailImage;  // 상세 이미지
  final int stockQuantity;   // 재고수량 (신규 추가 필드)
  final bool isActive;       // 판매 상태
  final DateTime createdAt;  // 등록일
  final DateTime? updatedAt; // 수정일
  final String? updatedBy;   // 수정자

  Product({
    required this.id,
    required this.productCode,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.sellingPrice,
    required this.discountRate,
    required this.mainCategory,
    required this.subCategory,
    required this.productImageUrl,
    required this.productDetailImage,
    required this.stockQuantity,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      productCode: map['productNo']?.toString() ?? '',
      name: map['productName'] ?? '',
      description: map['productDetails'] ?? '',
      originalPrice: map['originalPrice'] ?? 0,
      sellingPrice: map['price'] ?? 0,
      discountRate: map['discountRate'] ?? 0,
      mainCategory: map['mainCategory'] ?? '',
      subCategory: map['subCategory'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productDetailImage: map['productDetailImage'] ?? '',
      stockQuantity: map['stockQuantity'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productNo': int.tryParse(productCode) ?? 0,
      'productName': name,
      'productDetails': description,
      'originalPrice': originalPrice,
      'price': sellingPrice,
      'discountRate': discountRate,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
      'productImageUrl': productImageUrl,
      'productDetailImage': productDetailImage,
      'stockQuantity': stockQuantity,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  Product copyWith({
    String? id,
    String? productCode,
    String? name,
    String? description,
    int? originalPrice,
    int? sellingPrice,
    int? discountRate,
    String? mainCategory,
    String? subCategory,
    String? productImageUrl,
    String? productDetailImage,
    int? stockQuantity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return Product(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      name: name ?? this.name,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountRate: discountRate ?? this.discountRate,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productDetailImage: productDetailImage ?? this.productDetailImage,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
} 