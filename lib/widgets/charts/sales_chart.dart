import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/store_provider.dart';

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklySales = ref.watch(weeklySalesProvider);
    
    // 데이터가 없는 경우
    if (weeklySales.isEmpty) {
      return const Center(child: Text('데이터가 없습니다'));
    }

    // 차트 데이터 생성
    final spots = weeklySales.asMap().entries.map((entry) {
      final data = entry.value;
      return FlSpot(
        entry.key.toDouble(),
        (data['amount'] as int).toDouble(),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}일',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade200),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF5F0080),
            barWidth: 2,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF5F0080).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
} 