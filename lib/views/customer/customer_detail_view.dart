import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../models/customer.dart';
import '../../models/tier_settings.dart';
import '../../utils/customer_utils.dart';
import '../../models/customer_memo.dart';
import '../../providers/providers.dart';
import '../../services/customer_service.dart';

class CustomerDetailView extends ConsumerWidget {
  final Customer customer;

  const CustomerDetailView({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsyncValue = ref.watch(tierSettingsProvider);

    return settingsAsyncValue.when(
      data: (settings) {
        return CustomerDetailContent(customer: customer, settings: settings);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('오류 발생: $error')),
    );
  }
}

class CustomerDetailContent extends ConsumerStatefulWidget {
  final Customer customer;
  final TierSettings settings;

  const CustomerDetailContent({
    super.key,
    required this.customer,
    required this.settings,
  });

  @override
  ConsumerState<CustomerDetailContent> createState() => _CustomerDetailContentState();
}

class _CustomerDetailContentState extends ConsumerState<CustomerDetailContent> {
  late TextEditingController memoController;
  late MemoType memoType;
  bool isPrivate = false;
  bool isRegular = false;
  bool isTroubled = false;

  @override
  void initState() {
    super.initState();
    memoController = TextEditingController();
    memoType = MemoType.normal;
    isRegular = widget.customer.isRegular;
    isTroubled = widget.customer.isTroubled;
  }

  @override
  void dispose() {
    memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tierInfo = CustomerUtils.getCustomerTier(widget.customer, widget.settings);
    final totalAmount = CustomerUtils.calculateTotalOrderAmount(widget.customer);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.customer.productOrders.isNotEmpty
                ? widget.customer.productOrders.last.buyerName
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(totalAmount),
                  const SizedBox(height: 16),
                  if (widget.customer.addresses.isNotEmpty) ...[
                    _buildAddressesCard(),
                    const SizedBox(height: 16),
                  ],
                  if (widget.customer.productOrders.isNotEmpty)
                    _buildOrderHistoryCard(),
                  _buildMemoSection(),
                ],
              ),
            ),
          ),
          // 수정하기 버튼
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveCustomerInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '수정하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(int totalAmount) {
    final tierInfo = CustomerUtils.getCustomerTier(widget.customer, widget.settings);
    final validOrderCount = CustomerUtils.getValidOrderCount(widget.customer);
    
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
                  '${CustomerUtils.getValidOrderCount(widget.customer)}회',
                  Icons.shopping_bag,
                ),
                _buildSummaryItem(
                  '배송지',
                  '${widget.customer.addresses.length}개',
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
            ...widget.customer.addresses.map((addr) => Column(
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
    final sortedOrders = widget.customer.productOrders.toList()
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

  Widget _buildMemoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '고객 메모',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 메모 입력 영역
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: memoController,
                    decoration: const InputDecoration(
                      hintText: '고객 메모를 입력하세요',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<MemoType>(
                  value: memoType,
                  items: MemoType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, color: type.color, size: 16),
                        const SizedBox(width: 4),
                        Text(type.text),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => memoType = value);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    isPrivate ? Icons.lock : Icons.lock_open,
                    color: isPrivate ? Colors.red : Colors.grey,
                  ),
                  onPressed: () { 
                    setState(() => isPrivate = !isPrivate);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _saveMemo(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 체크리스트 추가
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('단골고객'),
                    value: isRegular,
                    onChanged: (value) {
                      setState(() => isRegular = value ?? false);
                    },
                    secondary: const Icon(Icons.favorite, color: Colors.red),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('진상고객'),
                    value: isTroubled,
                    onChanged: (value) {
                      setState(() => isTroubled = value ?? false);
                    },
                    secondary: const Icon(Icons.warning, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 메모 목록 표시
            StreamBuilder<List<CustomerMemo>>(
              stream: ref.read(customerMemosProvider(widget.customer.uid).stream),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final memos = snapshot.data!;
                if (memos.isEmpty) {
                  return const Center(child: Text('메모가 없습니다'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    return ListTile(
                      leading: Icon(memo.type.icon, color: memo.type.color),
                      title: Text(memo.content),
                      subtitle: Text(
                        CustomerUtils.formatDate(memo.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (memo.isPrivate)
                            const Icon(Icons.lock, color: Colors.red, size: 16),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showEditMemoDialog(memo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _showDeleteMemoDialog(memo),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 메모 저장 함수 분리
  Future<void> _saveMemo() async {
    if (memoController.text.trim().isEmpty) return;

    try {
      final memo = CustomerMemo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerId: widget.customer.uid,
        content: memoController.text.trim(),
        adminId: 'admin',
        createdAt: DateTime.now(),
        type: memoType,
        isPrivate: isPrivate,
      );
      
      await ref.read(customerMemoServiceProvider).addMemo(memo);
      memoController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메모가 저장되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 저장 실패: $e')),
        );
      }
    }
  }

  void _saveCustomerInfo() async {
    try {
      // 1. 메모 저장 (내용이 있는 경우)
      if (memoController.text.trim().isNotEmpty) {
        final memo = CustomerMemo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          customerId: widget.customer.uid,
          content: memoController.text.trim(),
          adminId: 'admin',
          createdAt: DateTime.now(),
          type: memoType,
          isPrivate: isPrivate,
        );
        
        await ref.read(customerMemoServiceProvider).addMemo(memo);
        memoController.clear();
      }

      // 2. 고객 정보 업데이트 (단골/진상 상태만)
      final updatedCustomer = Customer(
        uid: widget.customer.uid,
        addresses: widget.customer.addresses,
        productOrders: widget.customer.productOrders,
        isRegular: isRegular,
        isTroubled: isTroubled,
      );

      await ref.read(customerServiceProvider).updateCustomer(updatedCustomer);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객 정보가 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  // 메모 수정 다이얼로그
  void _showEditMemoDialog(CustomerMemo memo) {
    final editController = TextEditingController(text: memo.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 수정'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            hintText: '메모 내용을 입력하세요',
          ),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(customerMemoServiceProvider)
                    .updateMemo(memo.id, editController.text.trim());
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('메모가 수정되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('메모 수정 실패: $e')),
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

  // 메모 삭제 확인 다이얼로그
  void _showDeleteMemoDialog(CustomerMemo memo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await ref.read(customerMemoServiceProvider)
                    .deleteMemo(memo.id);
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('메모가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('메모 삭제 실패: $e')),
                  );
                }
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
} 