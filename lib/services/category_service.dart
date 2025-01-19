import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // settings/store/categories 경로로 접근
  CollectionReference get _categoriesRef => 
      _db.collection('settings').doc('store').collection('categories');

  // 전체 카테고리 조회
  Stream<List<Category>> getCategories() {
    print('카테고리 목록 조회');
    return _categoriesRef
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          print('카테고리 데이터 수신: ${snapshot.docs.length}건');
          return snapshot.docs
              .map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // 카테고리 이름만 조회 (상품 필터용)
  Stream<List<String>> getCategoryNames() {
    return _categoriesRef
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['name'] as String;
          }).toList();
        });
  }

  // 메인 카테고리만 조회
  Stream<List<Category>> getMainCategories() {
    print('메인 카테고리 조회');
    return _categoriesRef
        .where('parentId', isNull: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
          print('메인 카테고리 데이터 수신: ${snapshot.docs.length}건');
          return snapshot.docs
              .map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList();
        });
  }

  // 서브 카테고리 조회
  Stream<List<Category>> getSubCategories(String parentId) {
    return _categoriesRef
        .where('parentId', isEqualTo: parentId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // 카테고리 추가
  Future<void> addCategory(Category category) async {
    print('카테고리 추가 시도: ${category.name}');
    try {
      // store 문서가 없으면 생성
      final storeDoc = _db.collection('settings').doc('store');
      await storeDoc.set({}, SetOptions(merge: true));
      
      final docRef = await _categoriesRef.add(category.toMap());
      print('카테고리 추가 성공 - 문서 ID: ${docRef.id}');
    } catch (e) {
      print('카테고리 추가 실패: $e');
      rethrow;
    }
  }

  // 카테고리 수정
  Future<void> updateCategory(String id, Map<String, dynamic> data) {
    return _categoriesRef.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 카테고리 삭제 (하위 카테고리도 함께 삭제)
  Future<void> deleteCategory(String id) async {
    // 하위 카테고리 삭제
    final subCategories = await _categoriesRef
        .where('parentId', isEqualTo: id)
        .get();
    
    for (var doc in subCategories.docs) {
      await doc.reference.delete();
    }

    // 메인 카테고리 삭제
    await _categoriesRef.doc(id).delete();
  }

  // 카테고리 순서 변경
  Future<void> reorderCategories(List<String> categoryIds) async {
    final batch = _db.batch();
    
    for (var i = 0; i < categoryIds.length; i++) {
      final ref = _categoriesRef.doc(categoryIds[i]);
      batch.update(ref, {'order': i});
    }

    await batch.commit();
  }
} 