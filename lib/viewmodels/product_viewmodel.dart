import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/product_service.dart';

final productViewModelProvider = StateNotifierProvider<ProductViewModel, AsyncValue<List<Product>>>((ref) {
  return ProductViewModel(ProductService());
});

class ProductViewModel extends StateNotifier<AsyncValue<List<Product>>> {
  final ProductService _productService;

  ProductViewModel(this._productService) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      _productService.getProducts().listen(
        (products) {
          state = AsyncValue.data(products);
        },
        onError: (error) {
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _productService.updateProduct(product);
    } catch (e) {
      rethrow;
    }
  }
} 