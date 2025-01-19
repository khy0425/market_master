import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../providers/store_provider.dart';
import 'package:intl/intl.dart';

class RecentOrdersList extends ConsumerWidget {
  const RecentOrdersList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentOrders = ref.watch(recentOrdersProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  '최근 주문',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _buildOrderCountBadge(recentOrders),
              ],
            ),
          ),
          if (recentOrders.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('최근 주문이 없습니다'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentOrders.length,
              separatorBuilder: (context, index) {
                // 상태가 다른 경우 구분선 추가
                final currentStatus = OrderStatus.fromString(
                  recentOrders[index].deliveryStatus ?? ''
                );
                final nextStatus = index + 1 < recentOrders.length
                    ? OrderStatus.fromString(
                        recentOrders[index + 1].deliveryStatus ?? ''
                      )
                    : null;
                
                return currentStatus != nextStatus
                    ? const Divider(height: 1, thickness: 1)
                    : const SizedBox(height: 1);
              },
              itemBuilder: (context, index) {
                final order = recentOrders[index];
                final status = OrderStatus.fromString(order.deliveryStatus ?? '');
                
                return ListTile(
                  leading: _buildStatusIcon(status),
                  title: Row(
                    children: [
                      Text(
                        order.orderNo,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusChip(status),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${order.buyerName} · ${NumberFormat('#,###').format(order.totalAmount)}원',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MM/dd HH:mm').format(order.orderDate ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  trailing: (status == OrderStatus.pending || status == OrderStatus.confirmed)
                      ? OutlinedButton(
                          onPressed: () {
                            // TODO: 주문 처리 화면으로 이동
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            side: BorderSide(
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          child: const Text('처리하기'),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: (status == OrderStatus.pending || status == OrderStatus.confirmed)
            ? Border.all(
                color: status.color,
                width: 2,
              )
            : null,
      ),
      child: Stack(
        children: [
          Icon(status.icon, color: status.color),
          if (status == OrderStatus.pending)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'N',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: (status == OrderStatus.pending || status == OrderStatus.confirmed)
            ? Border.all(
                color: status.color,
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == OrderStatus.pending)
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              color: status.color,
              fontWeight: (status == OrderStatus.pending || status == OrderStatus.confirmed)
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCountBadge(List<ProductOrder> orders) {
    final pendingCount = orders.where((order) {
      final status = OrderStatus.fromString(order.deliveryStatus ?? '');
      return status == OrderStatus.pending;
    }).length;

    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '신규 $pendingCount건',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 