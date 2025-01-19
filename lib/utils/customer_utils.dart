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
    // 입금 대기와 취소/반품만 제외하고 모든 상태를 유효한 구매로 인정
    return ![
      'waiting',        // 입금 대기
      '입금대기',        // 입금 대기 (한글)
      'cancelled',      // 취소
      '취소/반품',       // 반품
    ].contains(status);
  }

  /// 주문 상태 표시 문자열과 색상
  static Map<String, dynamic> getOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
      case '입금대기':
        return {'text': '입금 대기', 'color': Colors.orange};
      case 'confirmed':
      case '주문접수':
        return {'text': '주문 접수', 'color': Colors.blue};
      case 'preparing':
      case '상품준비중':
        return {'text': '상품 준비중', 'color': Colors.indigo};
      case 'shipping':
      case '배송중':
        return {'text': '배송중', 'color': Colors.green};
      case 'delivered':
      case '배송완료':
        return {'text': '배송완료', 'color': Colors.grey};
      case 'cancelled':
      case '취소/반품':
        return {'text': '취소/반품', 'color': Colors.red};
      default:
        return {'text': status, 'color': Colors.grey};  // 알 수 없는 상태는 원본 텍스트 표시
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
    return customer.validOrderCount;
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
    final totalAmount = customer.totalOrderAmount;  // 입금 대기 제외된 금액
    
    // VVIP 등급 (100만원 이상)
    if (totalAmount >= settings.vvipThreshold) {
      return {
        'tier': 'VVIP',
        'color': Colors.purple,
        'nextTierAmount': null,
        'progress': 1.0,
      };
    }
    
    // VIP 등급 (50만원 이상)
    if (totalAmount >= settings.vipThreshold) {
      final remaining = settings.vvipThreshold - totalAmount;
      final progress = totalAmount / settings.vvipThreshold;
      return {
        'tier': 'VIP',
        'color': Colors.blue,
        'nextTierAmount': remaining,
        'progress': progress,
      };
    }
    
    // GOLD 등급 (20만원 이상)
    if (totalAmount >= settings.goldThreshold) {
      final remaining = settings.vipThreshold - totalAmount;
      final progress = totalAmount / settings.vipThreshold;
      return {
        'tier': 'GOLD',
        'color': Colors.amber,
        'nextTierAmount': remaining,
        'progress': progress,
      };
    }
    
    // BASIC 등급
    final remaining = settings.goldThreshold - totalAmount;
    final progress = totalAmount / settings.goldThreshold;
    return {
      'tier': 'BASIC',
      'color': Colors.grey,
      'nextTierAmount': remaining,
      'progress': progress,
    };
  }

  /// 등급 업그레이드까지 남은 금액 계산
  static String getNextTierMessage(Map<String, dynamic> tierInfo) {
    if (tierInfo['nextTierAmount'] == null) {
      return '최고 등급입니다';
    }
    return '다음 등급까지 ${formatAmount(tierInfo['nextTierAmount'])} 남음';
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