import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

final productViewModelProvider = StateNotifierProvider<ProductViewModel, AsyncValue<List<Product>>>((ref) {
  return ProductViewModel(FirestoreService());
});

class ProductViewModel extends StateNotifier<AsyncValue<List<Product>>> {
  final FirestoreService _firestoreService;

  ProductViewModel(this._firestoreService) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      state = const AsyncValue.loading();
      final products = await _firestoreService.getProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      await _firestoreService.updateProduct(productId, data);
      await loadProducts(); // 목록 새로고침
    } catch (e) {
      print('제품 업데이트 실패: $e');
      throw e;
    }
  }
} 