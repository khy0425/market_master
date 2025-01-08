import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../providers/providers.dart';
import '../../utils/customer_utils.dart';
import 'customer_list_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class CustomerAnalyticsView extends ConsumerStatefulWidget {
  const CustomerAnalyticsView({super.key});

  @override
  ConsumerState<CustomerAnalyticsView> createState() => _CustomerAnalyticsViewState();
}

class _CustomerAnalyticsViewState extends ConsumerState<CustomerAnalyticsView> {
  bool _isLoading = false;
  Map<String, dynamic>? _stats;
  String _period = '전체';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final customers = await ref.read(customerServiceProvider)
          .getCustomers()
          .first;
      
      final settings = await ref.read(tierSettingsProvider.future);
      
      int totalCustomers = customers.length;
      int activeCustomers = 0;
      int totalOrders = 0;
      int totalRevenue = 0;
      
      Map<String, int> tierCounts = {
        'VVIP': 0,
        'VIP': 0,
        'GOLD': 0,
        'BASIC': 0,
      };

      Map<String, int> monthlyRevenue = {};
      Map<int, int> hourlyOrders = {};
      
      final now = DateTime.now();
      final periodStart = _getPeriodStart(now);

      for (var customer in customers) {
        final validOrders = customer.productOrders
            .where((order) => CustomerUtils.isValidPurchaseStatus(order.deliveryStatus))
            .toList();

        if (validOrders.isNotEmpty) {
          activeCustomers++;
          
          final tier = CustomerUtils.getCustomerTier(customer, settings)['tier'];
          tierCounts[tier] = (tierCounts[tier] ?? 0) + 1;

          for (var order in validOrders) {
            try {
              final orderDateStr = order.orderDate.split('.')[0];
              final orderDate = DateTime.parse(orderDateStr);
              
              if (periodStart != null && orderDate.isBefore(periodStart)) {
                continue;
              }

              totalOrders++;
              totalRevenue += order.paymentAmount;
              
              final monthKey = DateFormat('yyyy-MM').format(orderDate);
              monthlyRevenue[monthKey] = 
                  (monthlyRevenue[monthKey] ?? 0) + order.paymentAmount;
              
              final hour = orderDate.hour;
              hourlyOrders[hour] = (hourlyOrders[hour] ?? 0) + 1;
            } catch (e) {
              developer.log('Error parsing date: ${order.orderDate}', error: e);
              continue;
            }
          }
        }
      }

      setState(() {
        _stats = {
          'totalCustomers': totalCustomers,
          'activeCustomers': activeCustomers,
          'totalOrders': totalOrders,
          'totalRevenue': totalRevenue,
          'averageOrderValue': totalOrders > 0 
              ? (totalRevenue ~/ totalOrders) 
              : 0,
          'tierCounts': tierCounts,
          'monthlyRevenue': monthlyRevenue,
          'hourlyOrders': hourlyOrders,
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('통계 로딩 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime? _getPeriodStart(DateTime now) {
    switch (_period) {
      case '1개월': return now.subtract(const Duration(days: 30));
      case '3개월': return now.subtract(const Duration(days: 90));
      case '6개월': return now.subtract(const Duration(days: 180));
      case '1년': return now.subtract(const Duration(days: 365));
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원 통계'),
        actions: [
          DropdownButton<String>(
            value: _period,
            items: ['전체', '1개월', '3개월', '6개월', '1년']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (value) {
              setState(() => _period = value!);
              _loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('통계를 불러올 수 없습니다.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      _buildTierDistributionCard(),
                      const SizedBox(height: 16),
                      _buildMonthlyRevenueCard(),
                      const SizedBox(height: 16),
                      _buildHourlyOrdersCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard() {
    final numberFormat = NumberFormat('#,###');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '전체 현황',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('전체 회원 수', '${_stats!['totalCustomers']}명'),
            _buildStatRow('활성 회원 수', '${_stats!['activeCustomers']}명'),
            _buildStatRow('총 주문 수', '${_stats!['totalOrders']}건'),
            _buildStatRow('총 매출액', '${numberFormat.format(_stats!['totalRevenue'])}원'),
            _buildStatRow('평균 주문금액', '${numberFormat.format(_stats!['averageOrderValue'])}원'),
          ],
        ),
      ),
    );
  }

  Widget _buildTierDistributionCard() {
    final tierCounts = _stats!['tierCounts'] as Map<String, int>;
    final total = tierCounts.values.fold(0, (a, b) => a + b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '등급 분포',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: tierCounts.entries.map((e) {
                    final percent = total > 0 
                        ? (e.value / total * 100).round() 
                        : 0;
                    return PieChartSectionData(
                      value: e.value.toDouble(),
                      title: '$percent%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...tierCounts.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text('${e.value}명'),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenueCard() {
    final monthlyRevenue = Map<String, int>.from(_stats!['monthlyRevenue']);
    final sortedMonths = monthlyRevenue.keys.toList()..sort();
    final maxRevenue = monthlyRevenue.values.fold(0, 
        (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '월별 매출',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(CustomerUtils.formatAmount(value.toInt()));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final month = sortedMonths[value.toInt()];
                          return Text(month.substring(5));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sortedMonths.asMap().entries.map((e) {
                        return FlSpot(
                          e.key.toDouble(),
                          monthlyRevenue[e.value]!.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyOrdersCard() {
    final hourlyOrders = Map<int, int>.from(_stats!['hourlyOrders']);
    final maxOrders = hourlyOrders.values.fold(0, 
        (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시간대별 주문',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}시');
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(24, (hour) {
                    return BarChartGroupData(
                      x: hour,
                      barRods: [
                        BarChartRodData(
                          toY: hourlyOrders[hour]?.toDouble() ?? 0,
                          color: Colors.blue,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}