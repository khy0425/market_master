import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/customer.dart';
import '../../utils/customer_utils.dart';

class CustomerDetailView extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailView({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierInfo = CustomerUtils.getCustomerTier(customer);
    final totalAmount = CustomerUtils.calculateTotalOrderAmount(customer);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(customer.productOrders.isNotEmpty
                ? customer.productOrders.last.buyerName
                : "미구매 회원"),
            const SizedBox(width: 8),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(totalAmount),
            const SizedBox(height: 16),
            if (customer.addresses.isNotEmpty) ...[
              _buildAddressesCard(),
              const SizedBox(height: 16),
            ],
            if (customer.productOrders.isNotEmpty)
              _buildOrderHistoryCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int totalAmount) {
    final tierInfo = CustomerUtils.getCustomerTier(customer);
    final validOrderCount = CustomerUtils.getValidOrderCount(customer);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${tierInfo['tier']} 회원',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: tierInfo['color'],
                  ),
                ),
                const Spacer(),
                Text(
                  CustomerUtils.getNextTierMessage(tierInfo),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tierInfo['nextTierAmount'] != null)
              LinearProgressIndicator(
                value: tierInfo['progress'],
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(tierInfo['color']),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  '총 구매액',
                  CustomerUtils.formatAmount(totalAmount),
                  Icons.payment,
                ),
                _buildSummaryItem(
                  '유효 구매',
                  '$validOrderCount회',
                  Icons.shopping_bag,
                ),
                _buildSummaryItem(
                  '배송지',
                  '${customer.addresses.length}개',
                  Icons.location_on,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '배송지 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...customer.addresses.map((addr) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  addr.addressName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(CustomerUtils.formatAddress(addr)),
                const Divider(),
              ],
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistoryCard() {
    final sortedOrders = customer.productOrders.toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '주문 이력',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedOrders.map((order) {
              final status = CustomerUtils.getOrderStatus(order.deliveryStatus);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNo,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: order.deliveryStatus == 'cancelled' 
                                ? Colors.grey 
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: status['color']?.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status['text'],
                          style: TextStyle(
                            color: status['color'],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(CustomerUtils.formatOrderDate(order.orderDate)),
                  Text(CustomerUtils.getOrderSummary(order)),
                  const Divider(),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
} 