import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'dart:developer' as developer;

/// 상품 관련 서비스를 제공하는 클래스
class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 상품 목록을 스트림으로 제공
  Stream<List<Product>> getProducts() {
    return _firestore
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// 상품 검색
  Stream<List<Product>> searchProducts(String query) {
    query = query.toLowerCase().trim();
    return getProducts().map((products) => products
        .where((product) =>
            product.name.toLowerCase().contains(query) ||
            product.productCode.toLowerCase().contains(query))
        .toList());
  }

  /// 새 상품 추가
  Future<void> addProduct(Product product) async {
    try {
      await _firestore.collection('products').add(product.toMap());
    } catch (e) {
      developer.log(
        'Error adding product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  /// 상품 정보 업데이트
  Future<void> updateProduct(Product product) async {
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      developer.log(
        'Error updating product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  /// 상품 삭제
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      developer.log(
        'Error deleting product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }
}