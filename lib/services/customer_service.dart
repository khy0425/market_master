import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'dart:developer' as developer;

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int pageSize = 100;  // 페이지당 고객 수

  // 마지막으로 가져온 문서를 저장
  DocumentSnapshot? _lastDocument;
  DateTime? _lastOrderDate;  // 마지막 주문 날짜 추가

  // 페이지네이션 최적화
  Stream<List<Customer>> getCustomersByPage(int page) {
    if (page == 0) {
      _lastDocument = null;
      _lastOrderDate = null;
    }

    var query = _firestore
        .collection('users')
        .orderBy('lastOrderDate', descending: true)
        .limit(pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    return query.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _lastOrderDate = (snapshot.docs.last.data()['lastOrderDate'] as Timestamp?)?.toDate();
      }
      return snapshot.docs.map((doc) => Customer.fromMap({
        ...doc.data(),
        'uid': doc.id,
      })).toList();
    });
  }

  // 전체 고객 목록 조회
  Stream<List<Customer>> getCustomers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return Customer.fromMap({
                ...data,
                'uid': doc.id,
                'isRegular': data['isRegular'] ?? false,
                'isTroubled': data['isTroubled'] ?? false,
              });
            }).toList());
  }

  // 페이지 초기화
  void resetPagination() {
    _lastDocument = null;
  }

  // 전체 고객 수 조회
  Future<int> getTotalCustomers() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;  // null 처리 추가
  }

  // 캐시 추가
  final _customerCache = <String, Customer>{};
  
  Future<Customer?> getCustomer(String uid) async {
    // 캐시 확인
    if (_customerCache.containsKey(uid)) {
      return _customerCache[uid];
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      
      final customer = Customer.fromMap({
        ...doc.data()!,
        'uid': doc.id,
      });
      
      // 캐시 저장
      _customerCache[uid] = customer;
      return customer;
    } catch (e) {
      developer.log('Error getting customer', error: e, name: 'CustomerService');
      return null;
    }
  }

  // 고객 검색 (주문 이메일 기준)
  Stream<List<Customer>> searchCustomers(String query) {
    query = query.toLowerCase().trim();
    return getCustomers().map((customers) => customers
        .where((customer) => customer.productOrders.any(
            (order) => order.buyerEmail.toLowerCase().contains(query)))
        .toList());
  }

  // 고객 통계
  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final now = DateTime.now();
      
      int totalCustomers = snapshot.docs.length;
      int activeCustomers = 0;  // 주문이 있는 고객 수
      int totalOrders = 0;      // 전체 주문 수
      int totalRevenue = 0;     // 전체 매출액

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final customer = Customer.fromMap({
          'uid': doc.id,
          ...data,
        });
        
        if (customer.productOrders.isNotEmpty) {
          activeCustomers++;
          totalOrders += customer.productOrders.length;
          totalRevenue += customer.productOrders
              .map((order) => order.paymentAmount)
              .fold(0, (a, b) => a + b);
        }
      }

      return {
        'totalCustomers': totalCustomers,
        'activeCustomers': activeCustomers,
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'averageOrderValue': totalOrders > 0 
            ? (totalRevenue / totalOrders).round() 
            : 0,
      };
    } catch (e) {
      developer.log('Error getting customer stats', error: e, name: 'CustomerService');
      rethrow;
    }
  }

  // 고객 정보 업데이트
  Future<void> updateCustomer(Customer customer) async {
    await _firestore
        .collection('users')
        .doc(customer.uid)
        .update(customer.toMap());
  }
}