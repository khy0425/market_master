import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'package:excel/excel.dart';
import 'dart:developer' as developer;
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CollectionReference _productsCollection = 
      FirebaseFirestore.instance.collection('products');

  // 이미지 URL 가져오기
  Future<String> getImageDownloadUrl(String imagePath) async {
    try {
      // 이미 완전한 URL인 경우 그대로 반환
      if (imagePath.startsWith('http')) {
        return imagePath;
      }
      
      // Firebase Storage 경로인 경우에만 다운로드 URL 가져오기
      if (imagePath.isNotEmpty) {
        final ref = _storage.ref().child(imagePath);
        final url = await ref.getDownloadURL();
        return url;
      }
      
      return '';
    } catch (e) {
      developer.log(
        'Error getting download URL for: $imagePath',
        error: e,
        name: 'ProductService',
      );
      return imagePath; // 에러 발생 시 원본 경로 반환
    }
  }

  // 엑셀 파일에서 상품 일괄 등록
  Future<List<String>> importProductsFromExcel(List<int> excelBytes) async {
    final excel = Excel.decodeBytes(excelBytes);
    final sheet = excel.tables[excel.tables.keys.first];
    final List<String> results = [];

    // 헤더 행 제외하고 처리
    for (var row in sheet!.rows.skip(1)) {
      try {
        final product = Product(
          id: '', // Firestore에서 자동 생성될 ID
          productCode: row[0]?.value.toString() ?? '',
          name: row[1]?.value.toString() ?? '',
          description: row[2]?.value.toString() ?? '',
          originalPrice: int.tryParse(row[3]?.value.toString() ?? '0') ?? 0,
          sellingPrice: int.tryParse(row[4]?.value.toString() ?? '0') ?? 0,
          discountRate: int.tryParse(row[5]?.value.toString() ?? '0') ?? 0,
          mainCategory: row[6]?.value.toString() ?? '',
          subCategory: row[7]?.value.toString() ?? '',
          productImageUrl: row[8]?.value.toString() ?? '',
          productDetailImage: row[9]?.value.toString() ?? '',
          stockQuantity: int.tryParse(row[10]?.value.toString() ?? '0') ?? 0,
          createdAt: DateTime.now(),
        );

        // Firestore에 추가
        final docRef = await _firestore.collection('products').add(product.toMap());
        results.add('성공: ${product.productCode}');
      } catch (e) {
        results.add('오류 발생 (${row[0]?.value}): $e');
      }
    }

    return results;
  }

  // 상품 목록 스트림
  Stream<List<Product>> getProducts() {
    try {
      return _productsCollection
          .orderBy('productNo', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Product.fromMap(doc.id, data);
            }).toList();
          });
    } catch (e) {
      developer.log(
        'Error in getProducts',
        error: e,
        name: 'ProductService',
      );
      return Stream.value(<Product>[]);
    }
  }

  // 상품 업데이트
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _productsCollection.doc(productId).update(data);
    } catch (e) {
      developer.log(
        'Error updating product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  // 상품 삭제
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      developer.log(
        'Error deleting product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  // 상품 추가
  Future<void> addProduct(Map<String, dynamic> data) async {
    try {
      await _productsCollection.add(data);
    } catch (e) {
      developer.log(
        'Error adding product',
        error: e,
        name: 'ProductService',
      );
      rethrow;
    }
  }

  Stream<List<Product>> searchProducts(String query) {
    query = query.toLowerCase().trim();
    
    try {
      return _productsCollection
          .orderBy('productNo', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Product.fromMap(doc.id, data);
            }).where((product) {
              // 상품명 또는 상품코드로 검색
              return product.name.toLowerCase().contains(query) ||
                     product.productCode.toLowerCase().contains(query);
            }).toList();
          });
    } catch (e) {
      developer.log(
        'Error in searchProducts',
        error: e,
        name: 'ProductService',
      );
      return Stream.value(<Product>[]);
    }
  }
}