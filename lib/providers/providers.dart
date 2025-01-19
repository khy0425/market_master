import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/customer_memo.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/tier_settings.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/customer_memo_service.dart';
import '../services/customer_service.dart';
import '../services/order_service.dart';

// 서비스 프로바이더들
final productServiceProvider = Provider((ref) => ProductService());
final storageServiceProvider = Provider((ref) => StorageService());
final settingsServiceProvider = Provider((ref) => SettingsService());
final customerMemoServiceProvider = Provider((ref) => CustomerMemoService());
final customerServiceProvider = Provider((ref) => CustomerService());

final tierSettingsProvider = StreamProvider<TierSettings>((ref) {
  print('tierSettingsProvider 초기화');
  return ref.watch(settingsServiceProvider).getTierSettings();
});

// 메모 관련 프로바이더
final customerMemosProvider = StreamProvider.autoDispose.family<List<CustomerMemo>, String>((ref, customerId) {
  print('customerMemosProvider 초기화 - customerId: $customerId');
  
  // 캐시 유지 시간 설정
  ref.keepAlive();
  
  final memoService = ref.read(customerMemoServiceProvider);
  return memoService.getCustomerMemos(customerId);
});

final latestMemoProvider = StreamProvider.family((ref, String customerId) {
  return ref.read(customerMemoServiceProvider).getLatestMemo(customerId);
});

// 기존 프로바이더들에 추가
final orderServiceProvider = Provider((ref) => OrderService());

final orderStreamProvider = StreamProvider<List<ProductOrder>>((ref) {
  print('[orderStreamProvider] 초기화');
  final orderService = ref.read(orderServiceProvider);
  
  return orderService.getOrders().map((orders) {
    print('[orderStreamProvider] 데이터 수신: ${orders.length}건');
    return orders;
  });
});

final productStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.read(productServiceProvider).getProducts();
});

final customerStreamProvider = StreamProvider<List<Customer>>((ref) {
  return ref.read(customerServiceProvider).getCustomers();
}); 