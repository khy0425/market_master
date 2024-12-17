import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 제품 관련 메서드
  Future<List<Product>> getProducts() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map((doc) => 
        Product.fromMap(doc.id, doc.data() as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('제품 목록 조회 오류: $e');
      return [];
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('products').doc(productId).update(data);
    } catch (e) {
      print('제품 업데이트 오류: $e');
      throw e;
    }
  }

  // 주문 관련 메서드
  Future<List<Map<String, dynamic>>> getAllOrders() async {
    try {
      QuerySnapshot userSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> allOrders = [];
      
      for (var doc in userSnapshot.docs) {
        var userData = doc.data() as Map<String, dynamic>;
        if (userData['productOrders'] != null) {
          List orders = userData['productOrders'] as List;
          for (var order in orders) {
            order['userId'] = doc.id;
            allOrders.add(Map<String, dynamic>.from(order));
          }
        }
      }
      
      return allOrders;
    } catch (e) {
      print('주문 목록 조회 오류: $e');
      return [];
    }
  }
} 