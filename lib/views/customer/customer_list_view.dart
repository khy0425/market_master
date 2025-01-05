import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../services/customer_service.dart';
import '../../providers/providers.dart';
import '../../utils/customer_utils.dart';
import 'customer_detail_view.dart';
import 'customer_analytics_view.dart';

final customerServiceProvider = Provider((ref) => CustomerService());

class CustomerListView extends ConsumerStatefulWidget {
  const CustomerListView({super.key});

  @override
  ConsumerState<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends ConsumerState<CustomerListView> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  
  // 필터링 상태
  String _selectedTier = '전체';  // VVIP, VIP, GOLD, BASIC
  int _minAmount = 0;  // 최소 구매액
  
  // 정렬 상태
  String _sortBy = '최근구매순';  // 구매액순, 구매횟수순

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: '필터',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
            tooltip: '정렬',
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CustomerAnalyticsView(),
              ),
            ),
            tooltip: '회원 통계',
          ),
        ],
      ),
      body: Column(
        children: [
          // 현재 적용된 필터/정렬 표시
          if (_selectedTier != '전체' || _minAmount > 0 || _sortBy != '최근구매순')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedTier != '전체')
                    Chip(
                      label: Text(_selectedTier),
                      onDeleted: () => setState(() => _selectedTier = '전체'),
                    ),
                  if (_minAmount > 0)
                    Chip(
                      label: Text('${CustomerUtils.formatAmount(_minAmount)} 이상'),
                      onDeleted: () => setState(() => _minAmount = 0),
                    ),
                  Chip(
                    label: Text(_sortBy),
                    onDeleted: () => setState(() => _sortBy = '최근구매순'),
                  ),
                ],
              ),
            ),

          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '주문자 이메일로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // 회원 목록
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: _searchController.text.isEmpty
                  ? ref.read(customerServiceProvider).getCustomers()
                  : ref.read(customerServiceProvider).searchCustomers(_searchController.text),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var customers = snapshot.data!;
                
                // 필터링 적용
                if (_selectedTier != '전체') {
                  customers = customers.where((c) => 
                    CustomerUtils.getCustomerTier(c)['tier'] == _selectedTier
                  ).toList();
                }
                
                if (_minAmount > 0) {
                  customers = customers.where((c) => 
                    CustomerUtils.calculateTotalOrderAmount(c) >= _minAmount
                  ).toList();
                }
                
                // 정렬 적용
                switch (_sortBy) {
                  case '구매액순':
                    customers.sort((a, b) => 
                      CustomerUtils.calculateTotalOrderAmount(b)
                      .compareTo(CustomerUtils.calculateTotalOrderAmount(a))
                    );
                    break;
                  case '구매횟수순':
                    customers.sort((a, b) => 
                      b.productOrders.length.compareTo(a.productOrders.length)
                    );
                    break;
                  case '최근구매순':
                    customers.sort((a, b) {
                      if (a.productOrders.isEmpty) return 1;
                      if (b.productOrders.isEmpty) return -1;
                      return b.productOrders.last.orderDate
                          .compareTo(a.productOrders.last.orderDate);
                    });
                    break;
                }

                if (customers.isEmpty) {
                  return const Center(child: Text('조건에 맞는 회원이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return _buildCustomerTile(customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('필터 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 등급 필터
            DropdownButtonFormField<String>(
              value: _selectedTier,
              decoration: const InputDecoration(labelText: '회원 등급'),
              items: ['전체', 'VVIP', 'VIP', 'GOLD', 'BASIC']
                  .map((tier) => DropdownMenuItem(
                        value: tier,
                        child: Text(tier),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedTier = value!);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            // 최소 구매액 필터
            DropdownButtonFormField<int>(
              value: _minAmount,
              decoration: const InputDecoration(labelText: '최소 구매액'),
              items: [0, 50000, 100000, 500000, 1000000]
                  .map((amount) => DropdownMenuItem(
                        value: amount,
                        child: Text(amount == 0 
                            ? '제한 없음' 
                            : CustomerUtils.formatAmount(amount)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() => _minAmount = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTier = '전체';
                _minAmount = 0;
              });
              Navigator.pop(context);
            },
            child: const Text('필터 초기화'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('정렬 기준'),
        children: [
          for (var sort in ['최근구매순', '구매액순', '구매횟수순'])
            RadioListTile<String>(
              title: Text(sort),
              value: sort,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value!);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final lastOrderDate = CustomerUtils.getLastOrderDate(customer);
    final totalAmount = CustomerUtils.calculateTotalOrderAmount(customer);
    final tierInfo = CustomerUtils.getCustomerTier(customer);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tierInfo['color'],
          child: Text(
            tierInfo['tier'][0],  // 첫 글자만 표시
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.productOrders.isNotEmpty 
                    ? customer.productOrders.last.buyerName 
                    : "미구매",
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierInfo['color']?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tierInfo['tier'],
                style: TextStyle(
                  color: tierInfo['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('구매횟수: ${customer.productOrders.length}회'),
            if (lastOrderDate != null)
              Text('최근구매: $lastOrderDate'),
            Text(
              '총 구매액: ${CustomerUtils.formatAmount(totalAmount)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: customer.addresses.isNotEmpty
            ? const Icon(Icons.location_on, color: Colors.grey)
            : null,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailView(customer: customer),
          ),
        ),
      ),
    );
  }
} 