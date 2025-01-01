import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/format_utils.dart';
import '../../providers/auth_provider.dart';

final orderServiceProvider = Provider((ref) => OrderService());

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredOrdersProvider = StreamProvider<List<ProductOrder>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(orderServiceProvider).getOrders();
  } else {
    return ref.watch(orderServiceProvider).searchOrders(query);
  }
});

class OrderListView extends ConsumerWidget {
  const OrderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(filteredOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 관리'),
      ),
      body: Column(
        children: [
          // 검색 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '주문자명, 이메일, 주문번호로 검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ordersAsyncValue.when(
                  data: (orders) => Text(
                    '총 ${orders.length}건',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // 주문 목록
          Expanded(
            child: ordersAsyncValue.when(
              data: (orders) => orders.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _buildOrderCard(context, ref, order);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류가 발생했습니다: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
            Text('결제금액: ${FormatUtils.formatPrice(order.paymentAmount)}'),
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.shipping:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref, ProductOrder order) async {
    final adminUser = ref.read(authStateProvider).value;
    if (adminUser == null) return;

    try {
      await ref.read(orderServiceProvider).updateOrderStatus(
        order.userId,
        order.orderNo,
        '주문확인',
        adminUser.uid,
        adminUser.email,
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
        order.userId,
        order.orderNo,
        '상품준비중',
        adminUser.uid,
        adminUser.email,
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
                    order.userId,
                    order.orderNo,
                    controller.text,
                    adminUser.uid,
                    adminUser.email,
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
        order.userId,
        order.orderNo,
        '배송완료',
        adminUser.uid,
        adminUser.email,
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
                    order.userId,
                    order.orderNo,
                    '취소/반품',
                    adminUser.uid,
                    adminUser.email,
                    note: controller.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('주문이 취소되었습니다')),
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
} 