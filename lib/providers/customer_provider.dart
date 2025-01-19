import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import './providers.dart';

class CustomerState {
  final List<Customer> customers;
  final DateTime? lastUpdated;
  
  const CustomerState({
    this.customers = const [],
    this.lastUpdated,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    DateTime? lastUpdated,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class CustomerManager extends StateNotifier<CustomerState> {
  final Ref ref;
  StreamSubscription? _subscription;

  CustomerManager(this.ref) : super(const CustomerState()) {
    _initialize();
  }

  void _initialize() {
    print('[CustomerManager] 초기화');
    _subscription = ref.read(customerServiceProvider)
        .getCustomers()
        .listen(_handleCustomerUpdate);
  }

  void _handleCustomerUpdate(List<Customer> customers) {
    print('[CustomerManager] 고객 데이터 업데이트: ${customers.length}건');
    state = state.copyWith(
      customers: customers,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  void dispose() {
    print('[CustomerManager] dispose');
    _subscription?.cancel();
    super.dispose();
  }
}

// 고객 관리 Provider
final customerManagerProvider = StateNotifierProvider<CustomerManager, CustomerState>((ref) {
  return CustomerManager(ref);
});

// 파생 Provider들
final newCustomersProvider = Provider<int>((ref) {
  final state = ref.watch(customerManagerProvider);
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  
  return state.customers.where((customer) => 
    customer.joinDate?.isAfter(startOfDay) ?? false
  ).length;
});

final regularCustomersProvider = Provider<int>((ref) {
  final state = ref.watch(customerManagerProvider);
  return state.customers.where((customer) => 
    customer.isRegular ?? false
  ).length;
}); 