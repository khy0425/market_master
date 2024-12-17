class Product {
  final String id;
  final int discountRate;
  final String mainCategory;
  final int originalPrice;
  final int price;
  final String productDetailImage;
  final String productDetails;
  final String productImageUrl;
  final String productName;
  final int productNo;
  final String subCategory;

  Product({
    required this.id,
    required this.discountRate,
    required this.mainCategory,
    required this.originalPrice,
    required this.price,
    required this.productDetailImage,
    required this.productDetails,
    required this.productImageUrl,
    required this.productName,
    required this.productNo,
    required this.subCategory,
  });

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      discountRate: map['discountRate'] ?? 0,
      mainCategory: map['mainCategory'] ?? '',
      originalPrice: map['originalPrice'] ?? 0,
      price: map['price'] ?? 0,
      productDetailImage: map['productDetailImage'] ?? '',
      productDetails: map['productDetails'] ?? '',
      productImageUrl: map['productImageUrl'] ?? '',
      productName: map['productName'] ?? '',
      productNo: map['productNo'] ?? 0,
      subCategory: map['subCategory'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'discountRate': discountRate,
      'mainCategory': mainCategory,
      'originalPrice': originalPrice,
      'price': price,
      'productDetailImage': productDetailImage,
      'productDetails': productDetails,
      'productImageUrl': productImageUrl,
      'productName': productName,
      'productNo': productNo,
      'subCategory': subCategory,
    };
  }
} 