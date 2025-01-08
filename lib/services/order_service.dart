import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import 'dart:developer' as developer;
import '../models/customer.dart';

/// 주문 관련 서비스를 제공하는 클래스
/// 
/// Firebase Firestore와 통신하여 주문 데이터를 관리합니다.
class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 100;
  DocumentSnapshot? _lastDocument;

  /// 모든 주문 목록을 스트림으로 제공
  /// 
  /// 주문일시 기준 내림차순으로 정렬됩니다.
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

  /// 주문 상태를 업데이트
  Future<void> updateOrderStatus(
    ProductOrder order,
    OrderStatus newStatus,
    String adminId,
    String adminEmail,
    {String? note}
  ) async {
    try {
      final orderInfo = OrderInfo.fromProductOrder(
        order, 
        adminId, 
        adminEmail,
        note: note
      );

      final userDoc = await _firestore.collection('users').doc(orderInfo.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == orderInfo.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 상태 업데이트
      orders[orderIndex]['deliveryStatus'] = newStatus.text;

      // 이력 추가
      if (orders[orderIndex]['history'] == null) {
        orders[orderIndex]['history'] = [];
      }
      
      orders[orderIndex]['history'].add({
        'status': newStatus.text,
        'timestamp': DateTime.now(),
        'adminId': orderInfo.adminId,
        'adminEmail': orderInfo.adminEmail,
        'note': orderInfo.note,
      });

      await _firestore.collection('users').doc(orderInfo.userId).update({
        'productOrders': orders,
      });
    } catch (e) {
      developer.log('Error updating order status', error: e, name: 'OrderService');
      rethrow;
    }
  }

  /// 결제 상태 업데이트
  Future<void> updatePaymentStatus(OrderInfo order, PaymentStatus newStatus) async {
    try {
      final userDoc = await _firestore.collection('users').doc(order.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == order.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 결제 상태 업데이트
      orders[orderIndex]['payment']['status'] = newStatus.text;

      await _firestore.collection('users').doc(order.userId).update({
        'productOrders': orders,
      });
    } catch (e) {
      developer.log('Error updating payment status', error: e, name: 'OrderService');
      rethrow;
    }
  }

  /// 환불 처리
  Future<void> processRefund(OrderInfo order, RefundDetails refundDetails) async {
    try {
      final userDoc = await _firestore.collection('users').doc(order.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == order.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 환불 정보 업데이트
      orders[orderIndex]['payment']['status'] = PaymentStatus.refunded.text;
      orders[orderIndex]['payment']['refundAmount'] = refundDetails.amount;
      orders[orderIndex]['payment']['refundDate'] = DateTime.now();
      orders[orderIndex]['payment']['refundReason'] = refundDetails.reason;

      await _firestore.collection('users').doc(order.userId).update({
        'productOrders': orders,
      });
    } catch (e) {
      developer.log('Error processing refund', error: e, name: 'OrderService');
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
          .toList();  // 이미 정렬된 상상태 유지
    });
  }

  /// 운송장 번호 업데이트
  Future<void> updateTrackingNumber(
    ProductOrder order,
    String trackingNumber,
    String adminId,
    String adminEmail,
  ) async {
    try {
      // 운송장 번호 업데이트
      final userDoc = await _firestore.collection('users').doc(order.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == order.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 운송장 번호 저장
      orders[orderIndex]['trackingNumber'] = trackingNumber;

      // 배송 상태 변경
      await updateOrderStatus(
        order,
        OrderStatus.shipping,
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

  // 기간별 주문 조회 (페이지네이션 포함)
  Stream<List<ProductOrder>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
  }) {
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

          for (var doc in snapshot.docs) {
            var userData = doc.data();
            if (userData['productOrders'] != null) {
              List ordersList = userData['productOrders'] as List;
              
              for (var orderData in ordersList) {
                if (orderData == null) continue;
                
                // 주문 날짜 파싱
                final orderDate = DateTime.tryParse(orderData['orderDate']?.toString().split('.')[0] ?? '');
                if (orderDate == null) continue;

                // 날짜 범위 체크
                if (orderDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                    orderDate.isBefore(endDate.add(const Duration(days: 1)))) {
                  
                  // 주문 상품 정보에 상품명 추가
                  List<dynamic> productNos = orderData['productNo'] as List? ?? [];
                  List<String?> productNames = List<String?>.filled(productNos.length, null);
                  
                  for (int i = 0; i < productNos.length; i++) {
                    String productNo = productNos[i].toString();
                    productNames[i] = productsMap[productNo] ?? '상품 $productNo';
                  }
                  
                  orderData['productNames'] = productNames;
                  orderData['userId'] = doc.id;
                  
                  orders.add(ProductOrder.fromMap(orderData as Map<String, dynamic>));
                }
              }
            }
          }

          // 날짜 기준 내림차순 정렬
          orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
          
          // 페이지네이션 적용
          final start = page * pageSize;
          final end = start + pageSize;
          
          if (start >= orders.length) return [];
          return orders.sublist(start, end > orders.length ? orders.length : end);
        });
  }

  // 페이지 초기화
  void resetPagination() {
    _lastDocument = null;
  }

  // 전체 주문 수 조회 (기간별)
  Future<int> getTotalOrders(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .where('productOrders.orderDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('productOrders.orderDate', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    int totalOrders = 0;
    for (var doc in snapshot.docs) {
      final customer = Customer.fromMap({
        ...doc.data(),
        'uid': doc.id,
      });
      
      totalOrders += customer.productOrders.where((order) {
        final orderDate = DateTime.tryParse(order.orderDate.split('.')[0]);
        return orderDate != null &&
               orderDate.isAfter(startDate) && 
               orderDate.isBefore(endDate.add(const Duration(days: 1)));
      }).length;
    }

    return totalOrders;
  }
}

/// 환불 처리에 필요한 정보를 담는 클래스
class RefundDetails {
  final int amount;
  final String reason;
  final String adminId;
  final String adminEmail;

  RefundDetails({
    required this.amount,
    required this.reason,
    required this.adminId,
    required this.adminEmail,
  });
} 