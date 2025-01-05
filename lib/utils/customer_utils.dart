import '../models/customer.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class CustomerUtils {
  static final _numberFormat = NumberFormat('#,###');
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _shortDateFormat = DateFormat('MM/dd HH:mm');

  /// 등급별 기준 금액 (변경 가능)
  static const vvipThreshold = 1000000;  // 100만원 이상
  static const vipThreshold = 500000;    // 50만원 이상
  static const goldThreshold = 200000;   // 20만원 이상

  /// 주문 상태 표시 문자열과 색상
  static Map<String, dynamic> getOrderStatus(String status) {
    switch (status) {
      case 'waiting':
        return {'text': '결제대기', 'color': Colors.orange};
      case 'confirmed':
        return {'text': '결제완료', 'color': Colors.blue};
      case 'preparing':
        return {'text': '배송준비', 'color': Colors.indigo};
      case 'shipping':
        return {'text': '배송중', 'color': Colors.green};
      case 'delivered':
        return {'text': '배송완료', 'color': Colors.grey};
      case 'cancelled':
        return {'text': '취소/반품', 'color': Colors.red};
      default:
        return {'text': status, 'color': Colors.black54};
    }
  }

  /// 유효한 주문인지 확인 (결제 대기, 취소, 반품 제외)
  static bool isValidOrder(CustomerOrder order) {
    return order.deliveryStatus != 'waiting' &&  // 결제 대기 제외
           order.deliveryStatus != 'cancelled';
  }

  /// 총 주문 금액 계산 (결제 대기, 취소, 반품 주문 제외)
  static int calculateTotalOrderAmount(Customer customer) {
    return customer.productOrders
        .where((order) => isValidOrder(order))
        .map((order) => order.paymentAmount)
        .fold(0, (a, b) => a + b);
  }

  /// 유효 주문 수 계산 (결제 대기, 취소, 반품 주문 제외)
  static int getValidOrderCount(Customer customer) {
    return customer.productOrders
        .where((order) => isValidOrder(order))
        .length;
  }

  /// 주문 금액 포맷팅 (₩ 기호 추가)
  static String formatAmount(int amount) {
    return '₩${_numberFormat.format(amount)}';
  }

  /// 주문일 포맷팅 (상세)
  static String formatOrderDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.split('.')[0]);
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// 주문일 포맷팅 (간단)
  static String formatOrderDateShort(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.split('.')[0]);
      return _shortDateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// 최근 유효 주문일 가져오기 (결제 대기, 취소, 반품 제외)
  static String? getLastOrderDate(Customer customer) {
    final validOrders = customer.productOrders
        .where((order) => isValidOrder(order))
        .toList();

    if (validOrders.isEmpty) return null;
    return formatOrderDateShort(validOrders.last.orderDate);
  }

  /// 주문 금액별 등급 계산과 색상
  static Map<String, dynamic> getCustomerTier(Customer customer) {
    final totalAmount = calculateTotalOrderAmount(customer);  // 이미 취소 주문이 제외된 금액

    if (totalAmount >= vvipThreshold) {
      return {
        'tier': 'VVIP',
        'color': Colors.red[700],
        'amount': totalAmount,
        'nextTierAmount': null,
        'progress': 1.0,
      };
    }
    if (totalAmount >= vipThreshold) {
      return {
        'tier': 'VIP',
        'color': Colors.orange[700],
        'amount': totalAmount,
        'nextTierAmount': vvipThreshold,
        'progress': (totalAmount - vipThreshold) / (vvipThreshold - vipThreshold),
      };
    }
    if (totalAmount >= goldThreshold) {
      return {
        'tier': 'GOLD',
        'color': Colors.amber[700],
        'amount': totalAmount,
        'nextTierAmount': vipThreshold,
        'progress': (totalAmount - goldThreshold) / (vipThreshold - goldThreshold),
      };
    }
    return {
      'tier': 'BASIC',
      'color': Colors.blue[700],
      'amount': totalAmount,
      'nextTierAmount': goldThreshold,
      'progress': totalAmount / goldThreshold,
    };
  }

  /// 등급 업그레이드까지 남은 금액 계산
  static String getNextTierMessage(Map<String, dynamic> tierInfo) {
    if (tierInfo['nextTierAmount'] == null) {
      return '최고 등급입니다';
    }

    final remaining = tierInfo['nextTierAmount'] - tierInfo['amount'];
    return '다음 등급까지 ${formatAmount(remaining)} 남음';
  }

  /// 주문 요약 정보 (취소 여부 표시)
  static String getOrderSummary(CustomerOrder order) {
    final items = order.productNo.length;
    final total = formatAmount(order.paymentAmount);
    if (order.deliveryStatus == 'cancelled') {
      return '$items개 상품 $total (취소됨)';
    }
    return '$items개 상품 $total';
  }

  /// 배송지 포맷팅
  static String formatAddress(CustomerAddress address) {
    return '${address.deliveryAddress1} ${address.deliveryAddress2}'
        '\n[${address.postalCode}]';
  }
} 