import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../models/tier_settings.dart';
import '../../services/customer_service.dart';
import '../../providers/providers.dart';
import '../../utils/customer_utils.dart';
import 'customer_detail_view.dart';
import 'customer_analytics_view.dart';

class CustomerListView extends ConsumerStatefulWidget {
  const CustomerListView({super.key});

  @override
  ConsumerState<CustomerListView> createState() => _CustomerListViewState();
}

class _CustomerListViewState extends ConsumerState<CustomerListView> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;

  // 필터링 상태
  String _selectedTier = '전체';  // VVIP, VIP, GOLD, BASIC
  int _minAmount = 0;  // 최소 구매액

  // 정렬 상태
  String _sortBy = '최근구매순';  // 구매액순, 구매횟수순
  String _customerType = '전체';  // 전체, 단골고객, 진상고객 추가

  @override
  void initState() {
    super.initState();
    _loadTotalPages();
  }

  Future<void> _loadTotalPages() async {
    final totalCustomers = await ref.read(customerServiceProvider).getTotalCustomers();
    setState(() {
      _totalPages = (totalCustomers / 100).ceil();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 페이지 변경 시 호출
  void _changePage(int newPage) {
    if (newPage == 0) {
      // 첫 페이지로 돌아갈 때는 페이지네이션 초기화
      ref.read(customerServiceProvider).resetPagination();
    }
    setState(() => _currentPage = newPage);
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsyncValue = ref.watch(tierSettingsProvider);

    return settingsAsyncValue.when(
      data: (settings) => Scaffold(
        appBar: AppBar(
          title: const Text('회원 관리'),
          actions: [
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
            // 필터 및 정렬 섹션
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 등급 필터
                    Row(
                      children: [
                        const Text('회원 등급:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: ['전체', 'VVIP', 'VIP', 'GOLD', 'BASIC'].map((tier) =>
                                ChoiceChip(
                                  label: Text(tier),
                                  selected: _selectedTier == tier,
                                  onSelected: (selected) {
                                    setState(() => _selectedTier = selected ? tier : '전체');
                                  },
                                ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 고객 유형 필터
                    Row(
                      children: [
                        const Text('고객 유형:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: ['전체', '단골고객', '진상고객', '일반고객'].map((type) =>
                                ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        type == '단골고객' ? Icons.favorite :
                                        type == '진상고객' ? Icons.warning :
                                        type == '일반고객' ? Icons.person_outline :
                                        Icons.person,
                                        size: 16,
                                        color: type == _customerType ? Colors.white : null,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(type),
                                    ],
                                  ),
                                  selected: _customerType == type,
                                  onSelected: (selected) {
                                    setState(() => _customerType = selected ? type : '전체');
                                  },
                                ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 최소 구매액 필터
                    Row(
                      children: [
                        const Text('최소 구매액:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [0, 50000, 100000, 500000, 1000000].map((amount) =>
                                ChoiceChip(
                                  label: Text(amount == 0
                                      ? '제한 없음'
                                      : CustomerUtils.formatAmount(amount)),
                                  selected: _minAmount == amount,
                                  onSelected: (selected) {
                                    setState(() => _minAmount = selected ? amount : 0);
                                  },
                                ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 정렬 기준
                    Row(
                      children: [
                        const Text('정렬:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: ['최근구매순', '구매액순', '구매횟수순'].map((sort) =>
                                ChoiceChip(
                                  label: Text(sort),
                                  selected: _sortBy == sort,
                                  onSelected: (selected) {
                                    setState(() => _sortBy = selected ? sort : '최근구매순');
                                  },
                                ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 검색바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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

            // 회이지네이션 UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => _changePage(_currentPage - 1)
                      : null,
                ),
                Text('${_currentPage + 1} / $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => _changePage(_currentPage + 1)
                      : null,
                ),
              ],
            ),

            // 고객 목록
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: ref.read(customerServiceProvider)
                    .getCustomersByPage(_currentPage),
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
                    CustomerUtils.getCustomerTier(c, settings)['tier'] == _selectedTier
                    ).toList();
                  }

                  if (_minAmount > 0) {
                    customers = customers.where((c) =>
                    CustomerUtils.calculateTotalOrderAmount(c) >= _minAmount
                    ).toList();
                  }

                  // 고객 유형 필터링을 FutureBuilder로 분리
                  if (_customerType != '전체') {
                    return FutureBuilder<List<Customer>>(
                      future: Future.wait(customers.map((customer) async {
                        if (_customerType == '단골고객') {
                          return customer.isRegular ? customer : null;
                        } else if (_customerType == '진상고객') {
                          return customer.isTroubled ? customer : null;
                        } else if (_customerType == '일반고객') {
                          return (!customer.isRegular && !customer.isTroubled) ? customer : null;
                        }
                        return customer;
                      })).then((list) => list.whereType<Customer>().toList()),
                      builder: (context, asyncSnapshot) {
                        if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (asyncSnapshot.hasError) {
                          return Center(child: Text('에러가 발생했습니다: ${asyncSnapshot.error}'));
                        }

                        return _buildCustomerListView(asyncSnapshot.data ?? [], settings);
                      },
                    );
                  }

                  return _buildCustomerListView(customers, settings);
                },
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류 발생: $error')),
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    final settingsAsyncValue = ref.watch(tierSettingsProvider);

    return settingsAsyncValue.when(
      data: (settings) {
        final lastOrderDate = CustomerUtils.getLastOrderDate(customer);
        final totalAmount = CustomerUtils.calculateTotalOrderAmount(customer);
        final tierInfo = CustomerUtils.getCustomerTier(customer, settings);

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
            onTap: () => _showCustomerDetail(customer),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류 발생: $error')),
    );
  }

  // VIP 등급 설정 다이얼로그
  void _showTierSettingsDialog(TierSettings settings) {
    final vvipController = TextEditingController(
        text: (settings.vvipThreshold / 10000).round().toString()
    );
    final vipController = TextEditingController(
        text: (settings.vipThreshold / 10000).round().toString()
    );
    final goldController = TextEditingController(
        text: (settings.goldThreshold / 10000).round().toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('VIP 등급 기준 설정'),
        content: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: vvipController,
                decoration: const InputDecoration(
                  labelText: 'VVIP 기준금액',
                  suffixText: '만원',
                  helperText: '100만원 이상 추천',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: vipController,
                decoration: const InputDecoration(
                  labelText: 'VIP 기준금액',
                  suffixText: '만원',
                  helperText: '50만원 이상 추천',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: goldController,
                decoration: const InputDecoration(
                  labelText: 'GOLD 기준금액',
                  suffixText: '만원',
                  helperText: '20만원 이상 추천',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newSettings = TierSettings(
                  vvipThreshold: int.parse(vvipController.text) * 10000,
                  vipThreshold: int.parse(vipController.text) * 10000,
                  goldThreshold: int.parse(goldController.text) * 10000,
                );

                await ref.read(settingsServiceProvider)
                    .updateTierSettings(newSettings);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('등급 기준이 변경되었습니다')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('저장 실패: $e')),
                );
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // 리스트뷰 빌더 분리
  Widget _buildCustomerListView(List<Customer> customers, TierSettings settings) {
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
  }

  // 고객 상세 정보 다이얼로그
  void _showCustomerDetail(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800,
          child: CustomerDetailView(customer: customer),
        ),
      ),
    );
  }
} 