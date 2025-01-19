import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/providers.dart';
import '../admin/manage_admins_view.dart';
import '../auth/login_view.dart';
import '../customer/customer_list_view.dart';
import '../order/order_list_view.dart';
import '../product/product_list_view.dart';
import '../../models/product.dart';
import '../../models/order.dart';
import '../../utils/format_utils.dart';
import '../../widgets/charts/sales_chart.dart';
import '../../widgets/charts/category_sales_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';

// 로컬 provider들만 남기고 서비스 provider들은 제거
final lowStockPageProvider = StateProvider<int>((ref) => 0);
final newCustomersPageProvider = StateProvider<int>((ref) => 0);
final pendingOrdersPageProvider = StateProvider<int>((ref) => 0);

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  // 에러 카드 위젯
  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  // 요약 아이템 위젯
  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
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
    );
  }

  // 신규 회원 위젯
  Widget _buildNewCustomers(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storeProvider);
    final currentPage = ref.watch(newCustomersPageProvider);
    final itemsPerPage = 5;

    final newCustomers = state.customers.where((c) {
      final joinDate = c.joinDate;
      if (joinDate == null) return false;
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      return joinDate.isAfter(startOfMonth);
    }).toList();

    final totalPages = (newCustomers.length / itemsPerPage).ceil();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '신규 회원',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (newCustomers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('최근 가입한 회원이 없습니다'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: newCustomers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = newCustomers[index];
                return ListTile(
                  title: Text(customer.name ?? '이름 없음'),
                  subtitle: Text(customer.email ?? '이메일 없음'),
                  trailing: customer.joinDate != null
                      ? Text(DateFormat('yyyy-MM-dd').format(customer.joinDate!))
                      : const Text('-'),
                );
              },
            ),
          if (newCustomers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: currentPage > 0
                        ? () => ref.read(newCustomersPageProvider.notifier).state--
                        : null,
                  ),
                  Text('${currentPage + 1} / $totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: currentPage < totalPages - 1
                        ? () => ref.read(newCustomersPageProvider.notifier).state++
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 재고 부족 상품 위젯
  Widget _buildLowStockProducts(BuildContext context, WidgetRef ref) {
    final productsStream = ref.watch(productServiceProvider).getProducts();
    final currentPage = ref.watch(lowStockPageProvider);
    final itemsPerPage = 5;

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('상품 데이터 로드 실패');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final lowStockProducts = snapshot.data!
            .where((p) => p.stockQuantity < 10)
            .toList();

        // 페이지네이션 적용
        final startIndex = currentPage * itemsPerPage;
        final endIndex = min(startIndex + itemsPerPage, lowStockProducts.length);
        final currentPageProducts = lowStockProducts.sublist(startIndex, endIndex);
        final totalPages = (lowStockProducts.length / itemsPerPage).ceil();

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '재고 부족 상품',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (currentPageProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('재고 부족 상품이 없습니다'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: currentPageProducts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = currentPageProducts[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            FormatUtils.formatPrice(product.sellingPrice),
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          Text('재고: ${product.stockQuantity}개'),
                        ],
                      ),
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('재고 보충'),
                        onPressed: () {
                          // 상품 관리 페이지의 해당 상품으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductListView(
                                initialProductId: product.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              
              // 페이지네이션 컨트롤
              if (lowStockProducts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: currentPage > 0
                            ? () => ref.read(lowStockPageProvider.notifier).state--
                            : null,
                      ),
                      Text('${currentPage + 1} / $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: currentPage < totalPages - 1
                            ? () => ref.read(lowStockPageProvider.notifier).state++
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 판매 통계 위젯
  Widget _buildSalesStatistics(WidgetRef ref) {
    final ordersAsync = ref.watch(orderStreamProvider);

    return ordersAsync.when(
      data: (orders) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '판매 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // TODO: 차트 위젯 추가
                const Text('준비 중...'),
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => _buildErrorCard('판매 통계 데이터 로드 실패'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[AdminDashboardView] build 시작 - hashCode: ${context.hashCode}');
    
    final result = Scaffold(
      drawer: _buildDrawer(context, ref),  // 기존 drawer 유지
      appBar: AppBar(
        title: const Text('대시보드'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFF5F0080)),
      ),
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refresh(orderStreamProvider);
          ref.refresh(productStreamProvider);
          ref.refresh(customerStreamProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 요약 통계 카드
              _buildSummaryCards(ref),
              const SizedBox(height: 24),

              // 차트 섹션
              _buildChartSection(ref),
              const SizedBox(height: 24),

              // 처리 대기 주문
              _buildPendingOrdersCard(context, ref),
              const SizedBox(height: 24),

              // 재고 부족 상품과 신규 회원 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildLowStockProducts(context, ref),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildNewCustomers(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    print('[AdminDashboardView] build 완료 - hashCode: ${context.hashCode}');
    return result;
  }

// 현재 사용 중인 새로운 디자인의 요약 카드 위젯
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(WidgetRef ref) {
    final state = ref.watch(storeProvider);
    return Row(
      children: [
        _buildSummaryCard(
          title: '오늘의 주문',
          value: state.isLoading ? '로딩중...' : '${ref.watch(todayOrdersProvider)}건',
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFF5F0080),
        ),
        _buildSummaryCard(
          title: '처리 대기',
          value: '${ref.watch(pendingOrdersProvider)}건',
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _buildSummaryCard(
          title: '신규 회원',
          value: '${ref.watch(newCustomersProvider)}명',
          icon: Icons.person_add_outlined,
          color: Colors.blue,
        ),
        _buildSummaryCard(
          title: '재고 부족',
          value: '${ref.watch(lowStockProductsProvider)}개',
          icon: Icons.warning_amber_outlined,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildChartSection(WidgetRef ref) {
    return Row(
      children: [
        // 매출 추이 차트
        Expanded(
          flex: 2,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: SizedBox(
                height: 300,
                child: SalesChart(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 카테고리별 매출 파이차트
        Expanded(
          child: _buildSalesStatistics(ref),
        ),
      ],
    );
  }

  Widget _buildPendingOrdersCard(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '처리 대기 주문',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('전체보기'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderListView()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final recentOrders = ref.watch(recentOrdersProvider);
                
                if (recentOrders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('처리 대기중인 주문이 없습니다'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentOrders.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final order = recentOrders[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.pending_actions, color: Colors.orange),
                      ),
                      title: Text(
                        order.orderNo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.buyerName),
                          Text(
                            FormatUtils.formatPrice(order.totalAmount ?? 0),
                            style: const TextStyle(
                              color: Color(0xFF5F0080),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        order.orderDate != null
                            ? FormatUtils.formatDateTime(order.orderDate!)
                            : '-',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
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

  // _buildDrawer 메서드 추가
  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authStateProvider);
              
              return DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF5F0080),  // 마켓컬리 보라색
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '관리자 메뉴',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    authState.when(
                      data: (user) {
                        if (user == null) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '권한: ${user.role ?? '일반 관리자'}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      error: (error, stack) => Text(
                        '오류 발생: $error',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.shopping_bag,
            title: '상품 관리',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProductListView()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: '회원 관리',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomerListView()),
            ),
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long,
            title: '주문 관리',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const OrderListView()),
            ),
          ),
          const Divider(),
          Consumer(
            builder: (context, ref, _) {
              final authState = ref.watch(authStateProvider);
              
              return authState.when(
                data: (user) {
                  if (user?.role == 'super_admin') {
                    return _buildDrawerItem(
                      icon: Icons.admin_panel_settings,
                      title: '관리자 관리',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageAdminsView(),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () {
              ref.read(authServiceProvider).signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginView()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // Drawer 아이템 위젯
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5F0080)),
      title: Text(title),
      onTap: onTap,
    );
  }
} 