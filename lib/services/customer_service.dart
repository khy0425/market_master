import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import 'dart:developer' as developer;

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const int pageSize = 100;

  // 전체 고객 목록 조회
  Stream<List<Customer>> getCustomers() {
    print('[CustomerService] getCustomers 호출');
    
    return _db.collection('customers').snapshots().map((snapshot) {
      print('[CustomerService] Firestore 데이터 수신: ${snapshot.docs.length}건');
      
      // 고객 ID 기준으로 중복 제거
      final uniqueCustomers = <String, Customer>{};
      
      for (var doc in snapshot.docs) {
        try {
          final customer = Customer.fromMap(doc.id, doc.data());
          if (!uniqueCustomers.containsKey(customer.id)) {
            uniqueCustomers[customer.id] = customer;
          }
        } catch (e) {
          print('[CustomerService] 고객 데이터 변환 실패: ${doc.id} - $e');
        }
      }
      
      final customers = uniqueCustomers.values.toList();
      print('[CustomerService] 중복 제거 후 고객 수: ${customers.length}건');
      return customers;
    });
  }

  // 단일 고객 조회
  Stream<Customer?> getCustomer(String id) {
    print('getCustomer 호출 - ID: $id'); // 디버그 로그 추가
    return _db
        .collection('users')
        .doc(id)
        .snapshots()
        .map((doc) {
          print('Firestore 문서 데이터: ${doc.data()}'); // 데이터 로깅
          return doc.exists 
              ? Customer.fromMap(doc.id, doc.data() ?? {}) 
              : null;
        });
  }

  // 고객 검색
  Stream<List<Customer>> searchCustomers(String query) {
    if (query.isEmpty) return getCustomers();

    return _db
        .collection('users')
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThan: '${query}z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Customer.fromMap(doc.id, doc.data()))
            .toList());
  }

  // 고객 정보 업데이트
  Future<void> updateCustomer(Customer customer) {
    return _db
        .collection('users')
        .doc(customer.id)
        .update(customer.toMap());
  }

  // 전체 고객 수 조회
  Future<int> getTotalCustomers() async {
    final snapshot = await _db
        .collection('users')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // 고객 삭제
  Future<void> deleteCustomer(String customerId) {
    return _db.collection('users').doc(customerId).delete();
  }

  // 페이지네이션 초기화 추가
  void resetPagination() {
    // 페이지네이션 관련 상태 초기화
  }

  // 페이지별 고객 목록 조회
  Stream<List<Customer>> getCustomersByPage(int page) {
    return getCustomers().map((customers) {
      final start = page * pageSize;
      final end = start + pageSize;
      if (start >= customers.length) return [];
      return customers.sublist(start, end > customers.length ? customers.length : end);
    });
  }
}