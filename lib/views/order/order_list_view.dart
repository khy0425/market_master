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
final filteredOrdersProvider = StreamProvider<List<ProductOrder>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(orderServiceProvider).getOrders();
  } else {
    return ref.watch(orderServiceProvider).searchOrders(query);
  }
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
  int _currentPage = 0;
  int _totalPages = 1;
  late DateTime _startDate;
  late DateTime _endDate;
  OrderStatus? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));
    _loadTotalPages();
  }

  Future<void> _loadTotalPages() async {
    final totalOrders = await ref.read(orderServiceProvider)
        .getTotalOrders(_startDate, _endDate);
    setState(() {
      _totalPages = (totalOrders / 100).ceil();
    });
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _currentPage = 0;  // 페이지 초기화
      });
      ref.read(orderServiceProvider).resetPagination();
      _loadTotalPages();
    }
  }

  /// 주문 카드 위젯을 생성
  /// 
  /// [order]: 표시할 주문 정보
  /// [context]: 빌드 컨텍스트
  /// [ref]: Provider 참조
  Widget _buildOrderCard(BuildContext context, WidgetRef ref, ProductOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              '주문번호: ${order.orderNo}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            Chip(
              label: Text(OrderStatus.fromString(order.deliveryStatus).text),
              backgroundColor: _getStatusColor(OrderStatus.fromString(order.deliveryStatus)),
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('주문자: ${order.buyerName} (${order.buyerEmail})'),
            Text('주문일시: ${_formatDateTime(order.orderDate)}'),
            Text('결제금액: ${FormatUtils.formatPrice(order.totalAmount)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주문 상품',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => _buildOrderItemRow(item)),
                const Divider(),
                const Text(
                  '배송 정보',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('배송지: ${order.shippingAddress}'),
                if (order.shippingNote != null)
                  Text('배송 메모: ${order.shippingNote}'),
                if (order.trackingNumber != null)
                  Text('운송장 번호: ${order.trackingNumber}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (order.status == OrderStatus.pending)
                      ElevatedButton(
                        onPressed: () => _confirmOrder(context, ref, order),
                        child: const Text('주문 확인'),
                      ),
                    if (order.status == OrderStatus.confirmed)
                      ElevatedButton(
                        onPressed: () => _startPreparing(context, ref, order),
                        child: const Text('상품 준비'),
                      ),
                    if (order.status == OrderStatus.preparing)
                      ElevatedButton(
                        onPressed: () => _showTrackingNumberDialog(context, ref, order),
                        child: const Text('배송 시작'),
                      ),
                    if (order.status == OrderStatus.shipping)
                      ElevatedButton(
                        onPressed: () => _completeDelivery(context, ref, order),
                        child: const Text('배송 완료'),
                      ),
                    const SizedBox(width: 8),
                    if (order.status != OrderStatus.cancelled &&
                        order.status != OrderStatus.delivered)
                      TextButton(
                        onPressed: () => _showCancelDialog(context, ref, order),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('주문 취소'),
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

  Widget _buildOrderItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (item.productImageUrl != null)
            SizedBox(
              width: 50,
              height: 50,
              child: Image.network(
                item.productImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported),
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? '상품명 없음'),
                Text(
                  '${FormatUtils.formatPrice(item.price)} × ${item.quantity}개',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            FormatUtils.formatPrice(item.price * item.quantity),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 주문 확인 처리
  /// 
  /// [order]: 처리할 주문
  /// [context]: 다이얼로그 표시를 위한 컨텍스트
  /// [ref]: Provider 참조
  Future<void> _confirmOrder(BuildContext context, WidgetRef ref, ProductOrder order) async {
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
        order,
        OrderStatus.confirmed,
        adminUser.uid,
        adminUser.email ?? '',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주문이 확인되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _startPreparing(BuildContext context, WidgetRef ref, ProductOrder order) async {
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
        order,
        OrderStatus.preparing,
        adminUser.uid,
        adminUser.email ?? '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품 준비가 시작되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _showTrackingNumberDialog(
    BuildContext context,
    WidgetRef ref,
    ProductOrder order,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('운송장 번호 입력'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: '운송장 번호',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? '운송장 번호를 입력하세요' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(orderServiceProvider).updateTrackingNumber(
                    order,
                    controller.text,
                    adminUser.uid,
                    adminUser.email ?? '',
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('배송이 시작되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDelivery(
    BuildContext context,
    WidgetRef ref,
    ProductOrder order,
  ) async {
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
        order,
        OrderStatus.delivered,
        adminUser.uid,
        adminUser.email ?? '',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('배송이 완료되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    ProductOrder order,
  ) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주문 취소'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('정말로 이 주문을 취소하시겠습니까?'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '취소 사유',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? '취소 사유를 입력하세요' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(orderServiceProvider).updateOrderStatus(
                    order,
                    OrderStatus.cancelled,
                    adminUser.uid,
                    adminUser.email ?? '',
                    note: controller.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('주문이 취소되었었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    ProductOrder order,
  ) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('환불 처리'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: '환불 금액',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? '환불 금액을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: '환불 사유',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? '환불 사사유를 입력하세요' : null,
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
              if (formKey.currentState!.validate()) {
                try {
                  final refundDetails = RefundDetails(
                    amount: int.parse(amountController.text),
                    reason: reasonController.text,
                    adminId: adminUser.uid,
                    adminEmail: adminUser.email ?? '',
                  );

                  final orderInfo = OrderInfo.fromProductOrder(
                    order,
                    adminUser.uid,
                    adminUser.email ?? '',
                  );

                  await ref.read(orderServiceProvider).processRefund(
                    orderInfo,
                    refundDetails,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('환불이 처리되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류가 발생했습니다: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('환불'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(ProductOrder order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: false,  // 기본적으로 접힌 상태로 변경
        title: Row(
          children: [
            Text(
              order.orderNo,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text(OrderStatus.fromString(order.deliveryStatus).text),
              backgroundColor: _getStatusColor(OrderStatus.fromString(order.deliveryStatus)),
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('주문자: ${order.buyerName} (${order.buyerEmail})'),
                  Text('연락처: ${order.buyerPhone}'),
                  Text('주문일시: ${FormatUtils.formatDateTime(order.orderDate)}'),
                ],
              ),
            ),
            Text(
              FormatUtils.formatPrice(order.totalAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 주문 상품 목록
                const Text('주문 상품', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 8),
                ...List.generate(
                  order.productNo.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(order.productNames?[index] ?? '상품 ${order.productNo[index]}'),
                        ),
                        Expanded(
                          child: Text('${order.quantity[index]}개'),
                        ),
                        Expanded(
                          child: Text(
                            FormatUtils.formatPrice(order.unitPrice[index] * order.quantity[index]),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                
                // 배송 정보
                const Text('배송 정보', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 8),
                Text('받는분: ${order.receiverName} (${order.receiverPhone})'),
                Text('주소: [${order.receiverZip}] ${order.receiverAddress1} ${order.receiverAddress2}'),
                if (order.deliveryRequest.isNotEmpty)
                  Text('배송요청: ${order.deliveryRequest}'),
                if (order.trackingNumber?.isNotEmpty ?? false)
                  Text('운송장번호: ${order.trackingNumber}'),
                const Divider(),

                // 결제 정보
                const Text('결제 정보', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('결제수단: ${order.paymentMethod}'),
                          if (order.couponUsed?.isNotEmpty ?? false)
                            Text('사용쿠폰: ${order.couponUsed}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('상품금액: ${FormatUtils.formatPrice(order.totalAmount - order.deliveryFee)}'),
                        Text('배송비: ${FormatUtils.formatPrice(order.deliveryFee)}'),
                        Text(
                          '총 결제금액: ${FormatUtils.formatPrice(order.totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                // 주문 상태 변경 버튼
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 상태 변경 버튼들...
                    _buildStatusChangeButton(order),
                    const SizedBox(width: 8),
                    // 운송장 입력 버튼
                    if (order.status == OrderStatus.preparing)
                      _buildTrackingNumberButton(order),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 주문 상태에 따른 색상
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.indigo;
      case OrderStatus.shipping:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  // 상태 변경 버튼 생성
  Widget _buildStatusChangeButton(ProductOrder order) {
    return PopupMenuButton<OrderStatus>(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('상태 변경'),
        onPressed: null,  // PopupMenuButton이 처리
      ),
      itemBuilder: (context) => OrderStatus.values
          .where((status) => status != OrderStatus.fromString(order.deliveryStatus))
          .map((status) => PopupMenuItem(
                value: status,
                child: Text(status.text),
              ))
          .toList(),
      onSelected: (newStatus) async {
        try {
          final adminUser = ref.read(authStateProvider).value;
          if (adminUser == null) return;

          await ref.read(orderServiceProvider).updateOrderStatus(
            order,
            newStatus,
            adminUser.uid,
            adminUser.email ?? '',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('주문 상태가 ${newStatus.text}로 변경되었습니다')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('상태 변경 실패: $e')),
            );
          }
        }
      },
    );
  }

  // 운송장 번호 입력 버튼
  Widget _buildTrackingNumberButton(ProductOrder order) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.local_shipping),
      label: const Text('운송장 입력'),
      onPressed: () => _showTrackingNumberInputDialog(order),
    );
  }

  // 운송장 번호 입력 다이얼로그
  Future<void> _showTrackingNumberInputDialog(ProductOrder order) async {
    final controller = TextEditingController();
    
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('운송장 번호 입력'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '운송장 번호',
            hintText: '운송장 번호를 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) return;
              
              try {
                final adminUser = ref.read(authStateProvider).value;
                if (adminUser == null) return;

                await ref.read(orderServiceProvider).updateTrackingNumber(
                  order,
                  controller.text,
                  adminUser.uid,
                  adminUser.email ?? '',
                );

                if (mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('운송장 번호가 등록되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('운송장 번호 등록 실패: $e')),
                  );
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('주문 관리'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                '${DateFormat('yy/MM/dd').format(_startDate)} - '
                '${DateFormat('yy/MM/dd').format(_endDate)}',
              ),
              onPressed: _showDateRangePicker,
            ),
          ],
        ),
        body: Column(
          children: [
            // 필터 섹션
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주문 상태 필터
                    Row(
                      children: [
                        const Text('주문 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: OrderStatus.values.map((status) => 
                              ChoiceChip(
                                label: Text(status.text),
                                selected: _selectedStatus == status,
                                onSelected: (selected) {
                                  setState(() => _selectedStatus = selected ? status : null);
                                },
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 검색바
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '주문번호, 주문자명, 이메일로 검색',
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
                  ],
                ),
              ),
            ),

            // 페이지네이션 UI
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                ),
                Text('${_currentPage + 1} / $_totalPages'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                ),
              ],
            ),

            // 주문 목록
            Expanded(
              child: StreamBuilder<List<ProductOrder>>(
                stream: ref.read(orderServiceProvider).getOrdersByDateRange(
                  startDate: _startDate,
                  endDate: _endDate,
                  page: _currentPage,
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var orders = snapshot.data!;
                  
                  // 필터링 적용
                  if (_selectedStatus != null) {
                    orders = orders.where((order) => 
                      OrderStatus.fromString(order.deliveryStatus) == _selectedStatus
                    ).toList();
                  }

                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    orders = orders.where((order) =>
                      order.orderNo.toLowerCase().contains(query) ||
                      order.buyerName.toLowerCase().contains(query) ||
                      order.buyerEmail.toLowerCase().contains(query)
                    ).toList();
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildOrderTile(orders[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 주문 상세 정보 표시
  void _showOrderDetail(ProductOrder order) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 800,
          child: _buildOrderCard(context, ref, order),
        ),
      ),
    );
  }

  // 주문 상품 목록 표시
  Widget _buildOrderItems(List<OrderItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => 
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(item.name),
              ),
              Expanded(
                child: Text('${item.quantity}개'),
              ),
              Expanded(
                child: Text(
                  FormatUtils.formatPrice(item.totalPrice),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ).toList(),
    );
  }
} 