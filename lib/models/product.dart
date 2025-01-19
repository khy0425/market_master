import 'package:cloud_firestore/cloud_firestore.dart';

/// 상품 정보를 나타내는 클래스
class Product {
  /// 상품 번호 (고유 식별자)
  final String id;
  
  /// 상품 코드 (외부 노출용)
  final String productCode;
  
  /// 상품명
  final String name;
  
  /// 상품 설명
  final String description;
  
  /// 정가
  final int originalPrice;
  
  /// 판매가
  final int sellingPrice;
  
  /// 할인율 (%)
  final int discountRate;
  
  /// 메인 카테고리
  final String mainCategory;
  
  /// 서브 카테고리
  final String subCategory;
  
  /// 대표 이미지 URL
  final String productImageUrl;
  
  /// 상세 이미지 URL
  final String productDetailImage;
  
  /// 재고 수량
  final int stockQuantity;
  
  /// 판매 상태 (true: 판매중, false: 판매중지)
  final bool isActive;
  
  /// 등록일시
  final DateTime createdAt;
  
  /// 수정일시
  final DateTime? updatedAt;
  
  /// 수정자 ID
  final String? updatedBy;

  const Product({
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
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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