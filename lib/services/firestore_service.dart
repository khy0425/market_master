import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 문서 목록 조회
  Stream<List<T>> getCollection<T>({
    required String path,
    required T Function(String id, Map<String, dynamic> data) builder,
  }) {
    return _db.collection(path).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return builder(doc.id, doc.data());
      }).toList();
    });
  }

  // 문서 검색
  Stream<List<T>> searchCollection<T>({
    required String path,
    required String field,
    required String query,
    required T Function(String id, Map<String, dynamic> data) builder,
  }) {
    return _db
        .collection(path)
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThan: '${query}z')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return builder(doc.id, doc.data());
          }).toList();
        });
  }

  // 단일 문서 조회
  Future<T?> getDocument<T>({
    required String path,
    required String id,
    required T Function(String id, Map<String, dynamic> data) builder,
  }) async {
    final doc = await _db.doc('$path/$id').get();
    if (!doc.exists || doc.data() == null) return null;
    return builder(doc.id, doc.data()!);
  }

  // 문서 업데이트
  Future<void> updateDocument({
    required String path,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _db.doc('$path/$id').update(data);
  }

  // 문서 삭제
  Future<void> deleteDocument({
    required String path,
    required String id,
  }) async {
    await _db.doc('$path/$id').delete();
  }

  // 문서 추가
  Future<DocumentReference> addDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    return await _db.collection(path).add(data);
  }

  // 문서 추가 (ID 지정)
  Future<void> setDocument({
    required String path,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    await _db.doc('$path/$id').set(data);
  }
} 