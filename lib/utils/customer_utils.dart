import '../models/customer.dart';
import '../models/order.dart' show OrderStatus;  // OrderStatus enum import
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/tier_settings.dart';

class CustomerUtils {
  static final _numberFormat = NumberFormat('#,###');
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _shortDateFormat = DateFormat('MM/dd HH:mm');

  /// 등급별 기준 금액 (변경 가능)
  static const vvipThreshold = 1000000;  // 100만원 이상
  static const vipThreshold = 500000;    // 50만원 이상
  static const goldThreshold = 200000;   // 20만원 이상

  /// 주문 상태 코드
  static const STATUS_WAITING = 'waiting';      // 결제대기
  static const STATUS_CONFIRMED = 'confirmed';  // 결제완료
  static const STATUS_PREPARING = 'preparing';  // 배송준비
  static const STATUS_SHIPPING = 'shipping';    // 배송중
  static const STATUS_DELIVERED = 'delivered';  // 배송완료
  static const STATUS_CANCELLED = 'cancelled';  // 취소
  static const STATUS_RETURNED = '취소/반품';    // 반품

  /// 유효한 구매액으로 인정되는 상태인지 확인
  static bool isValidPurchaseStatus(String status) {
    // OrderStatus enum의 값들과 비교
    final orderStatus = OrderStatus.fromString(status);
    return [
      OrderStatus.confirmed,    // 주문확인
      OrderStatus.preparing,    // 상품준비중
      OrderStatus.shipping,     // 배송중
      OrderStatus.delivered,    // 배송완료
    ].contains(orderStatus);
  }

  /// 주문 상태 표시 문자열과 색상
  static Map<String, dynamic> getOrderStatus(String status) {
    final orderStatus = OrderStatus.fromString(status);
    
    switch (orderStatus) {
      case OrderStatus.pending:
        return {'text': orderStatus.text, 'color': Colors.orange};
      case OrderStatus.confirmed:
        return {'text': orderStatus.text, 'color': Colors.blue};
      case OrderStatus.preparing:
        return {'text': orderStatus.text, 'color': Colors.indigo};
      case OrderStatus.shipping:
        return {'text': orderStatus.text, 'color': Colors.green};
      case OrderStatus.delivered:
        return {'text': orderStatus.text, 'color': Colors.grey};
      case OrderStatus.cancelled:
        return {'text': orderStatus.text, 'color': Colors.red};
      default:  // 기본값 추가
        return {'text': '알 수 없음', 'color': Colors.grey};
    }
  }

  /// 총 주문 금액 계산 (유효한 구매 상태의 주문만 포함)
  static int calculateTotalOrderAmount(Customer customer) {
    return customer.productOrders
        .where((order) => isValidPurchaseStatus(order.deliveryStatus))
        .map((order) => order.paymentAmount)
        .fold(0, (a, b) => a + b);
  }

  /// 유효 주문 수 계산 (유효한 구매 상태의 주문만 포함)
  static int getValidOrderCount(Customer customer) {
    return customer.productOrders
        .where((order) => isValidPurchaseStatus(order.deliveryStatus))
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
        .where((order) => isValidPurchaseStatus(order.deliveryStatus))
        .toList();

    if (validOrders.isEmpty) return null;
    return formatOrderDateShort(validOrders.last.orderDate);
  }

  /// 주문 금액별 등급 계산과 색상
  static Map<String, dynamic> getCustomerTier(Customer customer, TierSettings settings) {
    final totalAmount = calculateTotalOrderAmount(customer);

    if (totalAmount >= settings.vvipThreshold) {
      return {
        'tier': 'VVIP',
        'color': Colors.red[700],
        'amount': totalAmount,
        'nextTierAmount': null,
        'progress': 1.0,
      };
    }
    if (totalAmount >= settings.vipThreshold) {
      return {
        'tier': 'VIP',
        'color': Colors.orange[700],
        'amount': totalAmount,
        'nextTierAmount': settings.vvipThreshold,
        'progress': (totalAmount - settings.vipThreshold) / (settings.vvipThreshold - settings.vipThreshold),
      };
    }
    if (totalAmount >= settings.goldThreshold) {
      return {
        'tier': 'GOLD',
        'color': Colors.amber[700],
        'amount': totalAmount,
        'nextTierAmount': settings.vipThreshold,
        'progress': (totalAmount - settings.goldThreshold) / (settings.vipThreshold - settings.goldThreshold),
      };
    }
    return {
      'tier': 'BASIC',
      'color': Colors.blue[700],
      'amount': totalAmount,
      'nextTierAmount': settings.goldThreshold,
      'progress': totalAmount / settings.goldThreshold,
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

  /// 주문 요약 정보
  static String getOrderSummary(CustomerOrder order) {
    final items = order.productNo.length;
    final total = formatAmount(order.paymentAmount);
    
    if (!isValidPurchaseStatus(order.deliveryStatus)) {
      final status = OrderStatus.fromString(order.deliveryStatus).text;
      return '$items개 상품 $total ($status)';
    }
    return '$items개 상품 $total';
  }

  /// 배송지 포맷팅
  static String formatAddress(CustomerAddress address) {
    return '${address.deliveryAddress1} ${address.deliveryAddress2}'
        '\n[${address.postalCode}]';
  }

  /// 날짜 포맷팅
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }
} 