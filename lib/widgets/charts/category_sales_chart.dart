import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategorySalesChart extends ConsumerWidget {
  const CategorySalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 데이터가 없는 경우 표시할 위젯
    if (true) {  // 데이터 없음 상태 체크
      return const Center(
        child: Text(
          '카테고리별 매출 데이터가 없습니다',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            color: const Color(0xFF5F0080),
            value: 40,
            title: '40%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.blue,
            value: 30,
            title: '30%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.green,
            value: 15,
            title: '15%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: 15,
            title: '15%',
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 