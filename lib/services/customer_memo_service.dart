import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_memo.dart';

class CustomerMemoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 고객의 메모 목록 조회
  Stream<List<CustomerMemo>> getCustomerMemos(String customerId) {
    print('getCustomerMemos 호출 - customerId: $customerId');
    
    if (customerId.isEmpty) {
      print('customerId가 비어있음');
      return Stream.value([]);
    }

    return _db
        .collection('memos')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          print('메모 데이터 수신: ${snapshot.docs.length}건');
          try {
            final memos = snapshot.docs
                .map((doc) => CustomerMemo.fromMap(doc.data()))
                .toList();
            
            memos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return memos;
          } catch (e, stack) {
            print('메모 변환 오류: $e');
            print(stack);
            rethrow;
          }
        })
        .handleError((error) {
          print('메모 스트림 에러: $error');
          return [];
        });
  }

  // 가장 최근 메모 조회
  Stream<CustomerMemo?> getLatestMemo(String customerId) {
    return _db
        .collection('memos')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : CustomerMemo.fromMap(snapshot.docs.first.data()));
  }

  // 메모 추가
  Future<void> addMemo(CustomerMemo memo) {
    return _db
        .collection('memos')
        .doc()  // Firestore가 자동으로 ID 생성
        .set(memo.toMap());
  }

  // 메모 수정
  Future<void> updateMemo(String memoId, String content) {
    return _db
        .collection('memos')
        .doc(memoId)
        .update({'content': content});
  }

  // 메모 삭제
  Future<void> deleteMemo(String memoId) {
    return _db
        .collection('memos')
        .doc(memoId)
        .delete();
  }
} 