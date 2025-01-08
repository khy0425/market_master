import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../services/settings_service.dart';
import '../services/customer_memo_service.dart';
import '../services/customer_service.dart';

// 서비스 프로바이더들
final productServiceProvider = Provider((ref) => ProductService());
final storageServiceProvider = Provider((ref) => StorageService());
final settingsServiceProvider = Provider((ref) => SettingsService());
final customerMemoServiceProvider = Provider((ref) => CustomerMemoService());
final customerServiceProvider = Provider((ref) => CustomerService());

final tierSettingsProvider = StreamProvider((ref) {
  return ref.read(settingsServiceProvider).getTierSettings();
});

// 메모 관련 프로바이더 추가
final customerMemosProvider = StreamProvider.family((ref, String customerId) {
  return ref.read(customerMemoServiceProvider).getCustomerMemos(customerId);
});

final latestMemoProvider = StreamProvider.family((ref, String customerId) {
  return ref.read(customerMemoServiceProvider).getLatestMemo(customerId);
}); 