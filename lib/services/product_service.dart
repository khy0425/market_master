import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/product_modification.dart';
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

  /// 상품 정보 업데이트와 수정 이력 기록
  Future<void> updateProductWithHistory(
    Product oldProduct,
    Product newProduct,
    String modifiedBy,
    String modificationType, {
    String? comment,
  }) async {
    try {
      // 변경된 필드 찾기
      final changes = <String, dynamic>{};
      
      if (oldProduct.name != newProduct.name) {
        changes['name'] = {
          'old': oldProduct.name,
          'new': newProduct.name,
        };
      }
      
      if (oldProduct.description != newProduct.description) {
        changes['description'] = {
          'old': oldProduct.description,
          'new': newProduct.description,
        };
      }
      
      if (oldProduct.originalPrice != newProduct.originalPrice) {
        changes['originalPrice'] = {
          'old': oldProduct.originalPrice,
          'new': newProduct.originalPrice,
        };
      }
      
      if (oldProduct.sellingPrice != newProduct.sellingPrice) {
        changes['sellingPrice'] = {
          'old': oldProduct.sellingPrice,
          'new': newProduct.sellingPrice,
        };
      }
      
      if (oldProduct.stockQuantity != newProduct.stockQuantity) {
        changes['stockQuantity'] = {
          'old': oldProduct.stockQuantity,
          'new': newProduct.stockQuantity,
        };
      }

      // 트랜잭션으로 상품 업데이트와 이력 기록을 동시에 처리
      await _firestore.runTransaction((transaction) async {
        // 상품 정보 업데이트
        final productRef = _firestore.collection('products').doc(newProduct.id);
        transaction.update(productRef, newProduct.toMap());

        // 수정 이력 추가
        final historyRef = productRef.collection('modifications').doc();
        transaction.set(historyRef, {
          'productId': newProduct.id,
          'modifiedBy': modifiedBy,
          'modifiedAt': FieldValue.serverTimestamp(),
          'modificationType': modificationType,
          'changes': changes,
          'comment': comment,
        });
      });

      developer.log(
        'Product updated with history',
        name: 'ProductService',
        error: 'Modified by: $modifiedBy, Type: $modificationType',
      );
    } catch (e) {
      developer.log(
        'Error updating product with history',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  /// 상품의 수정 이력 조회
  Stream<List<ProductModification>> getProductModifications(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('modifications')
        .orderBy('modifiedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModification.fromMap(doc.id, doc.data()))
            .toList());
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

  /// 상품 일괄 등록
  Future<(int success, int failed, List<String> errors)> addProductsBatch(
    List<Map<String, dynamic>> products
  ) async {
    int success = 0;
    int failed = 0;
    final errors = <String>[];

    for (final productData in products) {
      try {
        await _firestore.collection('products').add(productData);
        success++;
      } catch (e) {
        failed++;
        errors.add('${productData['name']}: $e');
        developer.log(
          'Error adding product in batch',
          error: e,
          name: 'ProductService',
        );
      }
    }

    return (success, failed, errors);
  }
}