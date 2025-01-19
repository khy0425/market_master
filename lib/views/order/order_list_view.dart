import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/format_utils.dart';
import '../../providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// 주문 목록을 관리하는 Provider
final orderServiceProvider = Provider((ref) => OrderService());

/// 주문 검색어를 관리하는 Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// 필터링된 주문 목록을 제공하는 Provider
final filteredOrdersProvider = StreamProvider.autoDispose<List<ProductOrder>>((ref) {
  print('filteredOrdersProvider 초기화');
  
  // 검색어 변경 감지
  final query = ref.watch(searchQueryProvider);
  
  // 스트림 구독 취소 시 정리
  ref.onDispose(() {
    print('filteredOrdersProvider disposed');
  });
  
  // 캐시 유지
  ref.keepAlive();
  
  return ref.watch(orderServiceProvider).getOrders().map((orders) {
    print('주문 데이터 수신: ${orders.length}건');
    print('주문 데이터 상세: ${orders.map((o) => '${o.orderNo}: ${o.deliveryStatus}').join(', ')}');
    return orders;
  });
});

/// 주문 목록 화면 위젯
/// 
/// 주문 목록을 표시하고 주문 상태 변경, 검색 등의 기능을 제공합니다.
class OrderListView extends ConsumerStatefulWidget {
  const OrderListView({super.key});

  @override
  ConsumerState<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends ConsumerState<OrderListView> {
  late DateTime _startDate;
  late DateTime _endDate;
  OrderStatus? _selectedStatus;
  OrderStatus? _quickFilter;
  final _searchController = TextEditingController();
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day - 7);
    _endDate = DateTime(now.year, now.month, now.day);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (!_hasMoreData) return;
    setState(() {
      _currentPage++;
    });
  }

  void _resetPagination() {
    setState(() {
      _currentPage = 0;
      _hasMoreData = true;
    });
  }

  // 메트릭 카드 클릭 핸들러 수정
  void _handleMetricCardTap(OrderStatus? status) {
    setState(() {
      _quickFilter = status;
      _selectedStatus = status;
      _startDate = DateTime(2020); // 충분히 과거의 날짜
      _endDate = DateTime.now();
      _resetPagination();
    });
  }

  // 주문 취소 다이얼로그
  Future<void> _showCancelDialog(BuildContext context, ProductOrder order, WidgetRef ref) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: const Text('이 주문을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, '고객 요청'),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (reason != null) {
      await ref.read(orderServiceProvider).updateOrderStatus(
        order,
        OrderStatus.cancelled,
        'ADMIN_ID',  // TODO: 실제 관리자 ID로 변경
        'ADMIN_EMAIL',  // TODO: 실제 관리자 이메일로 변경
        note: reason,
      );
    }
  }

  // 날짜 관련 부분 수정
  Widget _buildOrderDateCell(ProductOrder order) {
    final orderDate = order.orderDate ?? DateTime(1900);
    return Text(
      DateFormat('yyyy-MM-dd HH:mm').format(orderDate),
      style: const TextStyle(fontSize: 14),
    );
  }

  // 셀 생성 메서드들
  Widget _buildOrderNoCell(ProductOrder order) {
    return Text(
      order.orderNo,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildBuyerCell(ProductOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.buyerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          order.buyerEmail,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildProductCell(ProductOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.productNames?.join(', ') ?? '상품명 없음',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${order.quantity.reduce((a, b) => a + b)}개',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAmountCell(ProductOrder order) {
    return Text(
      FormatUtils.formatPrice(order.totalAmount),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildStatusCell(ProductOrder order) {
    final status = OrderStatus.fromString(order.deliveryStatus);
    return Chip(
      label: Text(status.text),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  // 상태별 색상
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.grey;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.shipping:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 정렬 관련 메서드
  void _sortOrders(List<ProductOrder> orders, String field, bool ascending) {
    orders.sort((a, b) {
      switch (field) {
        case 'orderNo':
          return ascending
              ? a.orderNo.compareTo(b.orderNo)
              : b.orderNo.compareTo(a.orderNo);
        
        case 'orderDate':
          final aDate = a.orderDate ?? DateTime(1900);
          final bDate = b.orderDate ?? DateTime(1900);
          return ascending
              ? aDate.compareTo(bDate)
              : bDate.compareTo(aDate);
        
        case 'buyerName':
          return ascending
              ? a.buyerName.compareTo(b.buyerName)
              : b.buyerName.compareTo(a.buyerName);
        
        case 'totalAmount':
          return ascending
              ? a.totalAmount.compareTo(b.totalAmount)
              : b.totalAmount.compareTo(a.totalAmount);
        
        case 'status':
          return ascending
              ? a.deliveryStatus.compareTo(b.deliveryStatus)
              : b.deliveryStatus.compareTo(a.deliveryStatus);
        
        default:
          return 0;
      }
    });
  }

  // DataRow 생성
  DataRow _buildOrderRow(ProductOrder order) {
    return DataRow(
      cells: [
        DataCell(_buildOrderNoCell(order), onTap: () => _showOrderDetail(order)),
        DataCell(_buildOrderDateCell(order)),
        DataCell(_buildBuyerCell(order)),
        DataCell(_buildProductCell(order)),
        DataCell(_buildAmountCell(order)),
        DataCell(_buildStatusCell(order)),
        DataCell(
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showOrderDetail(order),
              ),
              if (OrderStatus.fromString(order.deliveryStatus) != OrderStatus.cancelled)
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => _showCancelDialog(context, order, ref),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // 필터링 메서드들
  bool _filterByDate(ProductOrder order, DateTime startDate, DateTime endDate) {
    final orderDate = order.orderDate ?? DateTime(1900);
    return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
           orderDate.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool _filterByStatus(ProductOrder order, OrderStatus? status) {
    if (status == null) return true;
    
    // 현재 주문의 상태를 OrderStatus 열거형으로 변환
    final orderStatus = OrderStatus.fromString(order.deliveryStatus);
    print('주문 상태 비교: ${order.orderNo} - 현재: ${orderStatus.code}, 필터: ${status.code}');
    
    return orderStatus == status;
  }

  bool _filterBySearch(ProductOrder order, String query) {
    query = query.toLowerCase();
    return order.orderNo.toLowerCase().contains(query) ||
           order.buyerName.toLowerCase().contains(query) ||
           order.buyerEmail.toLowerCase().contains(query) ||
           (order.productNames?.any((name) => 
             name?.toLowerCase().contains(query) ?? false) ?? false);
  }

  // 필터링 메서드 수정
  List<ProductOrder> _applyFilters(List<ProductOrder> orders) {
    print('필터 적용 시작: ${orders.length}건');
    
    var filteredOrders = orders.where((order) {
      bool dateFilter = _quickFilter != null ? true : 
        _filterByDate(order, _startDate, _endDate);
      
      bool statusFilter = _selectedStatus == null ? true :
        _filterByStatus(order, _selectedStatus);
      
      bool searchFilter = _searchController.text.isEmpty ||
        _filterBySearch(order, _searchController.text);

      return dateFilter && statusFilter && searchFilter;
    }).toList();

    print('필터 적용 후: ${filteredOrders.length}건');
    
    // 날짜순 정렬 (최신순)
    filteredOrders.sort((a, b) {
      final aDate = a.orderDate ?? DateTime(1900);
      final bDate = b.orderDate ?? DateTime(1900);
      return bDate.compareTo(aDate);
    });

    // 페이지네이션 적용
    final startIndex = _currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize) > filteredOrders.length 
        ? filteredOrders.length 
        : startIndex + _pageSize;
      
    print('페이지네이션 적용: $startIndex ~ $endIndex');
      
    if (startIndex >= filteredOrders.length) {
      _hasMoreData = false;
      return [];
    }
      
    if (endIndex == filteredOrders.length) {
      _hasMoreData = false;
    }

    final pagedOrders = filteredOrders.sublist(startIndex, endIndex);
    print('최종 표시 주문: ${pagedOrders.length}건');
      
    return pagedOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 관리'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildOrderMetrics(),
          Expanded(
            child: _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 상태 필터 칩
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
          children: [
                FilterChip(
                  label: const Text('전체'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = null;
                      _quickFilter = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(status.text),
                      selected: _selectedStatus == status,
                      selectedColor: _getStatusColor(status).withOpacity(0.8),
                      labelStyle: TextStyle(
                        color: _selectedStatus == status ? Colors.white : null,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedStatus = selected ? status : null;
                          _quickFilter = selected ? status : null;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 검색 필드
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: '검색',
                    hintText: '주문번호, 주문자명, 이메일로 검색',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // 날짜 선택
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        label: '시작일',
                        date: _startDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: _endDate,
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('~'),
                    ),
                    Expanded(
                      child: _buildDateField(
                        label: '종료일',
                        date: _endDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                      ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
      child: Row(
        children: [
            const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          ],
          ),
      ),
    );
  }

  Widget _buildOrderMetrics() {
    final ordersAsyncValue = ref.watch(filteredOrdersProvider);
    
    return ordersAsyncValue.when(
      data: (orders) {
        final totalOrders = orders.length;
        final pendingOrders = orders.where((o) {
          final status = OrderStatus.fromString(o.deliveryStatus);
          return status == OrderStatus.pending;
        }).length;
        
        final cancelledOrders = orders.where((o) {
          final status = OrderStatus.fromString(o.deliveryStatus);
          return status == OrderStatus.cancelled;
        }).length;

        print('주문 통계 - 전체: $totalOrders, 대기: $pendingOrders, 취소: $cancelledOrders');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildMetricCard(
                title: '전체 주문',
                value: '$totalOrders건',
                icon: Icons.shopping_cart,
                color: Colors.blue,
                onTap: () => _handleMetricCardTap(null),
              ),
              _buildMetricCard(
                title: '처리 대기',
                value: '$pendingOrders건',
                icon: Icons.pending_actions,
                color: Colors.orange,
                onTap: () => _handleMetricCardTap(OrderStatus.pending),
              ),
              _buildMetricCard(
                title: '취소/반품',
                value: '$cancelledOrders건',
                icon: Icons.cancel,
                color: Colors.red,
                onTap: () => _handleMetricCardTap(OrderStatus.cancelled),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('오류: $e')),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList() {
    return ref.watch(filteredOrdersProvider).when(
      data: (orders) {
        final filteredOrders = _applyFilters(orders);
        if (filteredOrders.isEmpty && _currentPage == 0) {
          return const Center(
            child: Text('주문이 없습니다'),
          );
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: [
                        const DataColumn(label: Text('주문번호')),
                        const DataColumn(label: Text('주문일시')),
                        const DataColumn(label: Text('주문자')),
                        const DataColumn(label: Text('상품')),
                        const DataColumn(label: Text('금액')),
                        const DataColumn(label: Text('상태')),
                        const DataColumn(label: Text('관리')),
                      ],
                      rows: filteredOrders.map((order) => _buildOrderRow(order)).toList(),
                    ),
                  ),
                ),
              ),
              if (_hasMoreData)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('오류가 발생했습니다: $error'),
      ),
    );
  }

  void _showOrderDetail(ProductOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('주문 상세 정보 #${order.orderNo}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailSection('주문자 정보', [
                '이름: ${order.buyerName}',
                '이메일: ${order.buyerEmail}',
                '전화번호: ${order.buyerPhone}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('배송 정보', [
                '수령인: ${order.receiverName}',
                '주소: ${order.receiverAddress1} ${order.receiverAddress2}',
                '우편번호: ${order.receiverZip}',
                '배송 요청사항: ${order.deliveryRequest}',
                if (order.trackingNumber != null)
                  '운송장 번호: ${order.trackingNumber}',
              ]),
              const SizedBox(height: 16),
              _buildDetailSection('결제 정보', [
                '결제 방법: ${order.paymentMethod}',
                '총 금액: ${FormatUtils.formatPrice(order.totalAmount)}원',
                '배송비: ${FormatUtils.formatPrice(order.deliveryFee)}원',
                if (order.couponUsed != null) '사용 쿠폰: ${order.couponUsed}',
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(detail),
        )),
      ],
    );
  }
} 