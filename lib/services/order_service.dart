import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../models/order.dart';
import 'dart:developer' as developer;
import '../models/customer.dart';

/// 주문 관련 서비스를 제공하는 클래스
/// 
/// Firebase Firestore와 통신하여 주문 데이터를 관리합니다.
class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int pageSize = 100;
  DocumentSnapshot? _lastDocument;

  // 주문 스트림 캐시
  final _ordersSubject = BehaviorSubject<List<ProductOrder>>();

  // 캐시된 주문 데이터
  List<ProductOrder>? _cachedOrders;
  Stream<List<ProductOrder>>? _ordersStream;

  Stream<List<ProductOrder>> getOrders() {
    // 캐시된 스트림이 있으면 재사용
    _ordersStream ??= _db.collection('users')
        .snapshots()
        .map((snapshot) {
          print('[OrderService] Firestore 데이터 수신: ${snapshot.docs.length}건');
          
          List<ProductOrder> allOrders = [];
          
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final List<dynamic> orders = data['productOrders'] ?? [];
              
              for (var orderData in orders) {
                try {
                  orderData['userId'] = doc.id;
                  final order = ProductOrder.fromMap(
                    orderData['orderNo'], 
                    Map<String, dynamic>.from(orderData)
                  );
                  allOrders.add(order);
                } catch (e) {
                  print('[OrderService] 주문 변환 오류: $e');
                }
              }
            } catch (e) {
              print('[OrderService] 사용자 데이터 처리 오류: $e');
            }
          }
          
          allOrders.sort((a, b) => 
            (b.orderDate ?? DateTime.now())
              .compareTo(a.orderDate ?? DateTime.now())
          );
          
          // 캐시 업데이트
          _cachedOrders = allOrders;
          
          print('[OrderService] 총 변환된 주문 수: ${allOrders.length}건');
          return allOrders;
        }).asBroadcastStream();  // 여러 구독자가 공유할 수 있도록

    return _ordersStream!;
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

      final userDoc = await _db.collection('users').doc(orderInfo.userId).get();
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

      await _db.collection('users').doc(orderInfo.userId).update({
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
      final userDoc = await _db.collection('users').doc(order.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == order.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 결제 상태 업데이트
      orders[orderIndex]['payment']['status'] = newStatus.text;

      await _db.collection('users').doc(order.userId).update({
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
      final userDoc = await _db.collection('users').doc(order.userId).get();
      List<dynamic> orders = userDoc.data()?['productOrders'] ?? [];
      int orderIndex = orders.indexWhere((o) => o['orderNo'] == order.orderNo);
      
      if (orderIndex == -1) throw '주문을 찾을 수 없습니다.';

      // 환불 정보 업데이트
      orders[orderIndex]['payment']['status'] = PaymentStatus.refunded.text;
      orders[orderIndex]['payment']['refundAmount'] = refundDetails.amount;
      orders[orderIndex]['payment']['refundDate'] = DateTime.now();
      orders[orderIndex]['payment']['refundReason'] = refundDetails.reason;

      await _db.collection('users').doc(order.userId).update({
        'productOrders': orders,
      });
    } catch (e) {
      developer.log('Error processing refund', error: e, name: 'OrderService');
      rethrow;
    }
  }

  // 주문 검색
  Stream<List<ProductOrder>> searchOrders(String query) {
    query = query.toLowerCase().trim();
    
    return getOrders().map((orders) {
      return orders
          .where((order) {
            final buyerName = order.buyerName?.toLowerCase() ?? '';
            final buyerEmail = order.buyerEmail?.toLowerCase() ?? '';
            final orderNo = order.orderNo?.toLowerCase() ?? '';
            
            return buyerName.contains(query) ||
                   buyerEmail.contains(query) ||
                   orderNo.contains(query);
          })
          .toList();
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
      final userDoc = await _db.collection('users').doc(order.userId).get();
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

  // 기간별 주문 조회
  Stream<List<ProductOrder>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
  }) {
    return _db
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          List<ProductOrder> orders = [];
          
          // 모든 상품 정보를 한 번에 가져오기
          final productsSnapshot = await _db.collection('products').get();
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
                  
                  orders.add(ProductOrder.fromMap(
                    doc.id,  // 문서 ID를 첫 번째 인자로 전달
                    orderData as Map<String, dynamic>
                  ));
                }
              }
            }
          }

          // 날짜 기준 내림차순 정렬
          orders.sort((a, b) {
            final aDate = a.orderDate ?? DateTime.now();
            final bDate = b.orderDate ?? DateTime.now();
            return bDate.compareTo(aDate);
          });
          
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
    final snapshot = await _db
        .collection('users')
        .where('productOrders.orderDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('productOrders.orderDate', isLessThanOrEqualTo: endDate.toIso8601String())
        .get();

    int totalOrders = 0;
    for (var doc in snapshot.docs) {
      final customer = Customer.fromMap(
        doc.id,  // 문서 ID를 첫 번째 인자로 전달
        doc.data()  // 데이터를 두 번째 인자로 전달
      );
      
      totalOrders += customer.productOrders.where((order) {
        final orderDate = DateTime.tryParse(order.orderDate.split('.')[0]);
        return orderDate != null &&
               orderDate.isAfter(startDate) && 
               orderDate.isBefore(endDate.add(const Duration(days: 1)));
      }).length;
    }

    return totalOrders;
  }

  // 서비스 정리
  void dispose() {
    _ordersSubject.close();
  }

  // 고객별 주문 조회
  Stream<List<ProductOrder>> getCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductOrder.fromMap(
                  doc.id,  // 문서 ID를 첫 번째 인자로 전달
                  doc.data()
                ))
            .toList());
  }

  // 캐시된 데이터 반환
  List<ProductOrder> getCachedOrders() {
    return _cachedOrders ?? [];
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