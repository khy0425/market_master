import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'dart:developer' as developer;

class CustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 고객 목록 조회 (스트림)
  Stream<List<Customer>> getCustomers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromMap(doc.id, doc.data()))
            .toList());
  }

  // 단일 고객 조회
  Future<Customer?> getCustomer(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return Customer.fromMap(doc.id, doc.data()!);
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
        final customer = Customer.fromMap(doc.id, doc.data());
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
} 