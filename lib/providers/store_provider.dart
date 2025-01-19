import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/order.dart';
import './providers.dart';

// 전체 스토어 상태를 관리하는 클래스
class StoreState {
  final List<Customer> customers;
  final List<Product> products;
  final List<ProductOrder> orders;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? error;

  const StoreState({
    this.customers = const [],
    this.products = const [],
    this.orders = const [],
    this.lastUpdated,
    this.isLoading = false,
    this.error,
  });

  StoreState copyWith({
    List<Customer>? customers,
    List<Product>? products,
    List<ProductOrder>? orders,
    DateTime? lastUpdated,
    bool? isLoading,
    String? error,
  }) {
    return StoreState(
      customers: customers ?? this.customers,
      products: products ?? this.products,
      orders: orders ?? this.orders,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class StoreManager extends StateNotifier<StoreState> {
  final Ref ref;
  StreamSubscription? _customersSub;
  StreamSubscription? _productsSub;
  StreamSubscription? _ordersSub;

  StoreManager(this.ref) : super(const StoreState()) {
    _initialize();
  }

  void _initialize() {
    print('[StoreManager] 초기화');
    state = state.copyWith(isLoading: true);

    // 고객 데이터 구독
    _customersSub = ref.read(customerServiceProvider)
        .getCustomers()
        .listen(
          _handleCustomerUpdate,
          onError: _handleError,
        );

    // 상품 데이터 구독
    _productsSub = ref.read(productServiceProvider)
        .getProducts()
        .listen(
          _handleProductUpdate,
          onError: _handleError,
        );

    // 주문 데이터 구독
    _ordersSub = ref.read(orderServiceProvider)
        .getOrders()
        .listen(
          _handleOrderUpdate,
          onError: _handleError,
        );
  }

  void _handleCustomerUpdate(List<Customer> customers) {
    print('[StoreManager] 고객 데이터 수신: ${customers.length}건');
    
    // 고객 ID 기준으로 중복 제거
    final uniqueCustomers = <String, Customer>{};
    for (var customer in customers) {
      if (customer.id.isNotEmpty && !uniqueCustomers.containsKey(customer.id)) {
        uniqueCustomers[customer.id] = customer;
      }
    }
    
    final uniqueCustomersList = uniqueCustomers.values.toList();
    print('[StoreManager] 중복 제거 후 고객 수: ${uniqueCustomersList.length}건');
    
    // 고객 상태별 카운트 로깅 (예: 일반/VIP/정지 등)
    final statusCount = <String, int>{};
    for (var customer in uniqueCustomersList) {
      final status = customer.isRegular == true ? 'regular' : 'normal';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    print('[StoreManager] 고객 상태별 카운트: $statusCount');

    state = state.copyWith(
      customers: uniqueCustomersList,
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  void _handleProductUpdate(List<Product> products) {
    print('[StoreManager] 상품 데이터 업데이트: ${products.length}건');
    state = state.copyWith(
      products: products,
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  void _handleOrderUpdate(List<ProductOrder> orders) {
    print('[StoreManager] 주문 데이터 수신: ${orders.length}건');
    
    // 주문번호 기준으로 중복 제거
    final uniqueOrders = <String, ProductOrder>{};
    for (var order in orders) {
      if (order.orderNo.isNotEmpty && !uniqueOrders.containsKey(order.orderNo)) {
        uniqueOrders[order.orderNo] = order;
      }
    }
    
    final uniqueOrdersList = uniqueOrders.values.toList();
    print('[StoreManager] 중복 제거 후 주문 수: ${uniqueOrdersList.length}건');
    
    // 주문 상태별 카운트 로깅
    final statusCount = <String, int>{};
    for (var order in uniqueOrdersList) {
      final status = order.deliveryStatus ?? 'unknown';
      statusCount[status] = (statusCount[status] ?? 0) + 1;
    }
    print('[StoreManager] 주문 상태별 카운트: $statusCount');

    state = state.copyWith(
      orders: uniqueOrdersList,
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  void _handleError(error) {
    print('[StoreManager] 에러 발생: $error');
    state = state.copyWith(
      error: error.toString(),
      isLoading: false,
    );
  }

  @override
  void dispose() {
    print('[StoreManager] dispose');
    _customersSub?.cancel();
    _productsSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }
}

// 메인 Provider
final storeProvider = StateNotifierProvider<StoreManager, StoreState>((ref) {
  return StoreManager(ref);
});

// 파생 Provider들
final newCustomersProvider = Provider<int>((ref) {
  final state = ref.watch(storeProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  
  final newCustomers = state.customers.where((customer) => 
    customer.joinDate?.isAfter(startOfDay) ?? false
  ).toList();
  
  print('[newCustomersProvider] 오늘 가입한 고객: ${newCustomers.length}건');
  for (var customer in newCustomers) {
    print('[newCustomersProvider] - 고객ID: ${customer.id}, 가입일: ${customer.joinDate}');
  }
  
  return newCustomers.length;
});

// 상태별 주문 수를 반환하는 Provider 추가
final orderStatusCountProvider = Provider<Map<OrderStatus, int>>((ref) {
  final state = ref.watch(storeProvider);
  final statusCount = <OrderStatus, int>{};
  
  for (var order in state.orders) {
    final status = OrderStatus.fromString(order.deliveryStatus ?? '');
    statusCount[status] = (statusCount[status] ?? 0) + 1;
  }
  
  print('[orderStatusCountProvider] 상태별 주문 수: $statusCount');
  return statusCount;
});

final lowStockProductsProvider = Provider<int>((ref) {
  final state = ref.watch(storeProvider);
  return state.products.where((product) => 
    product.stockQuantity < 10 && product.isActive
  ).length;
});

// pendingOrdersProvider 수정
final pendingOrdersProvider = Provider<int>((ref) {
  final state = ref.watch(storeProvider);
  
  print('[pendingOrdersProvider] 전체 주문 수: ${state.orders.length}건');  // 로그 추가
  
  final pendingOrders = state.orders.where((order) {
    final status = OrderStatus.fromString(order.deliveryStatus ?? '');
    final isPending = status.isWaiting;
    
    // 상세 로그 추가
    print('[pendingOrdersProvider] 주문번호: ${order.orderNo}');
    print('  - 원래 상태: ${order.deliveryStatus}');
    print('  - 변환된 상태: ${status.text}');
    print('  - 처리대기 여부: $isPending');
    
    return isPending;
  }).toList();
  
  print('[pendingOrdersProvider] 처리 대기 주문: ${pendingOrders.length}건');
  for (var order in pendingOrders) {
    print('[pendingOrdersProvider] - 주문번호: ${order.orderNo}, 상태: ${order.deliveryStatus}');
  }
  
  return pendingOrders.length;
});

// recentOrdersProvider 수정
final recentOrdersProvider = Provider<List<ProductOrder>>((ref) {
  final state = ref.watch(storeProvider);
  if (state.orders.isEmpty) return [];
  
  print('[recentOrdersProvider] 전체 주문 수: ${state.orders.length}건');
  
  // 처리 대기 중인 주문만 필터링
  final pendingOrders = state.orders.where((order) {
    final status = OrderStatus.fromString(order.deliveryStatus ?? '');
    return status.isWaiting;
  }).toList();
  
  print('[recentOrdersProvider] 처리 대기 주문 수: ${pendingOrders.length}건');
  
  // 주문번호 기준으로 중복 제거
  final uniqueOrders = <String, ProductOrder>{};
  for (var order in pendingOrders) {
    if (order.orderNo.isNotEmpty && !uniqueOrders.containsKey(order.orderNo)) {
      uniqueOrders[order.orderNo] = order;
    }
  }
  
  final sortedOrders = uniqueOrders.values.toList()
    ..sort((a, b) {
      final aDate = a.orderDate ?? DateTime.now();
      final bDate = b.orderDate ?? DateTime.now();
      return bDate.compareTo(aDate);  // 최신순 정렬
    });
  
  print('[recentOrdersProvider] 최종 표시할 주문:');
  for (var order in sortedOrders) {
    final status = OrderStatus.fromString(order.deliveryStatus ?? '');
    print('  - 주문번호: ${order.orderNo}, 상태: ${status.text}');
  }
  
  return sortedOrders;  // 처리 대기 주문만 있으므로 take(5) 제거
});

final todayOrdersProvider = Provider<int>((ref) {
  final state = ref.watch(storeProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  
  return state.orders.where((order) => 
    order.orderDate?.isAfter(startOfDay) ?? false
  ).length;
});

final weeklySalesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final state = ref.watch(storeProvider);
  final now = DateTime.now();
  final days = List.generate(7, (i) => 
    DateTime(now.year, now.month, now.day - i)
  );
  
  return days.map((date) {
    final dayOrders = state.orders.where((order) => 
      order.orderDate?.year == date.year &&
      order.orderDate?.month == date.month &&
      order.orderDate?.day == date.day
    );
    
    return {
      'date': date.toIso8601String(),
      'amount': dayOrders.fold<int>(
        0, 
        (sum, order) => sum + (order.totalAmount ?? 0)
      ),
    };
  }).toList();
}); 