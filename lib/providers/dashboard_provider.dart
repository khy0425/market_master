import 'dart:async';  // StreamSubscription을 위한 import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/customer.dart';  // Customer 모델 import
import './providers.dart';  // providers.dart에서 직접 import

// 대시보드 데이터 상태 관리를 위한 클래스
class DashboardState {
  final List<ProductOrder> orders;
  final List<Product> products;
  final List<Customer> customers;
  
  const DashboardState({
    this.orders = const [],
    this.products = const [],
    this.customers = const [],
  });

  DashboardState copyWith({
    List<ProductOrder>? orders,
    List<Product>? products,
    List<Customer>? customers,
  }) {
    return DashboardState(
      orders: orders ?? this.orders,
      products: products ?? this.products,
      customers: customers ?? this.customers,
    );
  }
}

// 대시보드 데이터 관리 Provider
final dashboardManagerProvider = StateNotifierProvider<DashboardManager, DashboardState>((ref) {
  return DashboardManager(ref);
});

class DashboardManager extends StateNotifier<DashboardState> {
  final Ref ref;
  StreamSubscription? _ordersSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _customersSub;

  DashboardManager(this.ref) : super(const DashboardState()) {
    _initialize();
  }

  void _initialize() {
    print('[DashboardManager] 초기화');
    
    // 주문 데이터 구독
    _ordersSub = ref.read(orderStreamProvider.stream).listen((orders) {
      print('[DashboardManager] 주문 데이터 업데이트: ${orders.length}건');
      state = state.copyWith(orders: orders);
    });

    // 상품 데이터 구독
    _productsSub = ref.read(productStreamProvider.stream).listen((products) {
      print('[DashboardManager] 상품 데이터 업데이트: ${products.length}건');
      state = state.copyWith(products: products);
    });

    // 고객 데이터 구독
    _customersSub = ref.read(customerStreamProvider.stream).listen((customers) {
      print('[DashboardManager] 고객 데이터 업데이트: ${customers.length}건');
      state = state.copyWith(customers: customers);
    });
  }

  @override
  void dispose() {
    print('[DashboardManager] dispose');
    _ordersSub?.cancel();
    _productsSub?.cancel();
    _customersSub?.cancel();
    super.dispose();
  }
}

// 페이지네이션을 위한 로컬 상태 Provider들만 남김
final lowStockPageProvider = StateProvider<int>((ref) => 0);
final newCustomersPageProvider = StateProvider<int>((ref) => 0);
final pendingOrdersPageProvider = StateProvider<int>((ref) => 0);

// 나머지 Provider들은 store_provider.dart로 이동했으므로 제거 