import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'dart:developer' as developer;

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 주문 목록 스트림
  Stream<List<ProductOrder>> getOrders() {
    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          List<ProductOrder> orders = [];
          
          // 모든 상품 정보를 한 번에 가져오기
          final productsSnapshot = await _firestore.collection('products').get();
          final productsMap = Map.fromEntries(
            productsSnapshot.docs.map((doc) => 
              MapEntry(doc.data()['productNo']?.toString() ?? '', doc.data()['productName'] as String?)
            )
          );

          // 모든 사용자의 주문 정보 수집
          for (var doc in snapshot.docs) {
            var userData = doc.data();
            if (userData['productOrders'] != null) {
              List ordersList = userData['productOrders'] as List;
              orders.addAll(
                ordersList.map((orderData) {
                  if (orderData == null) return null;
                  
                  // 주문 상품 정보에 상품명 추가
                  List<dynamic> productNos = orderData['productNo'] as List? ?? [];
                  List<String?> productNames = List<String?>.filled(productNos.length, null);
                  
                  for (int i = 0; i < productNos.length; i++) {
                    String productNo = productNos[i].toString();
                    // products 컬렉션에서 가져온 상품명 매핑
                    productNames[i] = productsMap[productNo] ?? '상품 $productNo';
                  }
                  
                  // productNames 배열을 orderData에 추가
                  orderData['productNames'] = productNames;
                  orderData['userId'] = doc.id;
                  
                  return ProductOrder.fromMap(orderData as Map<String, dynamic>);
                }).whereType<ProductOrder>()
              );
            }
          }

          orders.sort((a, b) {
            final dateA = a.orderDate ?? DateTime.now();
            final dateB = b.orderDate ?? DateTime.now();
            return dateB.compareTo(dateA);
          });

          return orders;
        });
  }

  // 주문 상태 업데이트
  Future<void> updateOrderStatus(
    String userId, 
    String orderNo, 
    String newStatus, 
    String adminId,
    String adminEmail,
    {String? note}
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((order) => order['orderNo'] == orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 상태 업데이트
      orders[orderIndex]['deliveryStatus'] = newStatus;

      // 이력 추가
      if (orders[orderIndex]['history'] == null) {
        orders[orderIndex]['history'] = [];
      }
      
      orders[orderIndex]['history'].add({
        'status': newStatus,
        'timestamp': DateTime.now(),
        'adminId': adminId,
        'adminEmail': adminEmail,
        'note': note,
      });

      await _firestore.collection('users').doc(userId).update({
        'productOrders': orders,
      });
    } catch (e) {
      developer.log(
        'Error updating order status',
        error: e,
        name: 'OrderService',
      );
      rethrow;
    }
  }

  // 주문 검색 (검색 결과도 정렬 유지)
  Stream<List<ProductOrder>> searchOrders(String query) {
    query = query.toLowerCase().trim();
    
    return getOrders().map((orders) {
      return orders
          .where((order) {
            return order.buyerName.toLowerCase().contains(query) ||
                   order.buyerEmail.toLowerCase().contains(query) ||
                   order.orderNo.toLowerCase().contains(query);
          })
          .toList();  // 이미 정렬된 상태 유지
    });
  }

  // 운송장 번호 업데이트
  Future<void> updateTrackingNumber(
    String userId, 
    String orderNo, 
    String trackingNumber,
    String adminId,
    String adminEmail,
  ) async {
    try {
      await updateOrderStatus(
        userId, 
        orderNo, 
        '배송중', 
        adminId,
        adminEmail,
        note: '운송장 번호: $trackingNumber',
      );
    } catch (e) {
      developer.log(
        'Error updating tracking number',
        error: e,
        name: 'OrderService',
      );
      rethrow;
    }
  }
} 