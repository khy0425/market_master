import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/product_modification.dart';
import 'firestore_service.dart';

class ProductService {
  final _service = FirestoreService();
  static const String collection = 'products';

  // 전체 상품 목록 조회
  Stream<List<Product>> getProducts() {
    return _service.getCollection<Product>(
      path: collection,
      builder: (id, data) => Product.fromMap(id, data),
    );
  }

  // 상품 검색
  Stream<List<Product>> searchProducts(String query) {
    return _service.searchCollection<Product>(
      path: collection,
      field: 'productName',
      query: query,
      builder: (id, data) => Product.fromMap(id, data),
    );
  }

  // 단일 상품 조회
  Future<Product?> getProduct(String id) {
    return _service.getDocument<Product>(
      path: collection,
      id: id,
      builder: (id, data) => Product.fromMap(id, data),
    );
  }

  // 상품 업데이트
  Future<void> updateProduct(Product product) {
    return _service.updateDocument(
      path: collection,
      id: product.id,
      data: product.toMap(),
    );
  }

  // 상품 삭제
  Future<void> deleteProduct(String id) {
    return _service.deleteDocument(
      path: collection,
      id: id,
    );
  }

  // 새 상품 추가
  Future<void> addProduct(Product product) async {
    await _service.addDocument(
      path: collection,
      data: product.toMap(),
    );
  }

  // 상품 수정 이력 조회
  Stream<List<ProductModification>> getProductModifications(String productId) {
    return _service.getCollection<ProductModification>(
      path: '$collection/$productId/modifications',
      builder: (id, data) => ProductModification.fromMap(id, data),
    );
  }

  // 상품 일괄 등록
  Future<(int success, int failed, List<String> errors)> addProductsBatch(
    List<Map<String, dynamic>> products
  ) async {
    int success = 0;
    int failed = 0;
    final errors = <String>[];

    for (final productData in products) {
      try {
        await _service.addDocument(
          path: collection,
          data: productData,
        );
        success++;
      } catch (e) {
        failed++;
        errors.add('${productData['productName']}: $e');
        print('Error adding product in batch: $e');
      }
    }

    return (success, failed, errors);
  }
}