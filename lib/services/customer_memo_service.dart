import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_memo.dart';

class CustomerMemoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 메모 추가
  Future<void> addMemo(CustomerMemo memo) async {
    final docRef = _firestore.collection('memos').doc();  // 새 문서 ID 생성
    await docRef.set({
      ...memo.toMap(),
      'id': docRef.id,  // Firestore 문서 ID 사용
    });
  }
  
  // 메모 수정
  Future<void> updateMemo(String memoId, String content) async {
    await _firestore.collection('memos').doc(memoId).update({
      'content': content,
    });
  }
  
  // 메모 삭제
  Future<void> deleteMemo(String memoId) async {
    await _firestore.collection('memos').doc(memoId).delete();
  }
  
  // 고객별 메모 조회 (인덱스 없이)
  Stream<List<CustomerMemo>> getCustomerMemos(String customerId) {
    return _firestore
        .collection('memos')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final memos = snapshot.docs
              .map((doc) => CustomerMemo.fromMap(doc.data()))
              .toList();
          // 클라이언트 측에서 정렬
          memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return memos;
        });
  }
  
  // 중요 메모 조회
  Stream<List<CustomerMemo>> getImportantMemos() {
    return _firestore
        .collection('memos')
        .where('type', whereIn: ['important', 'warning', 'vip'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerMemo.fromMap(doc.data()))
            .toList());
  }
  
  /// 고객의 최신 메모 조회
  Stream<CustomerMemo?> getLatestMemo(String customerId) {
    return _firestore
        .collection('memos')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          
          // 클라이언트 측에서 정렬
          final docs = snapshot.docs.toList()
            ..sort((a, b) => b.data()['createdAt'].compareTo(a.data()['createdAt']));
          
          return CustomerMemo.fromMap(docs.first.data());
        });
  }
} 