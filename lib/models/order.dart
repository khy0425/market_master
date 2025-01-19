import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 주문 상태를 나타내는 열거형
enum OrderStatus {
  pending('주문접수', 'pending', true),
  confirmed('주문확인', 'confirmed', true),
  preparing('상품준비중', 'preparing', false),
  shipping('배송중', 'shipping', false),
  delivered('배송완료', 'delivered', false),
  cancelled('취소/반품', 'cancelled', false);

  final String text;
  final String code;
  final bool isWaiting;  // 처리 대기 상태 여부
  const OrderStatus(this.text, this.code, this.isWaiting);

  String get label => text;  // 새로운 UI용 getter

  static OrderStatus fromString(String status) {
    print('[OrderStatus] 상태 변환: $status');  // 로그 추가
    
    // 상태값 정규화
    final normalized = status.toLowerCase().trim();
    
    // 매핑 테이블
    final Map<String, OrderStatus> statusMap = {
      'pending': OrderStatus.pending,
      'confirmed': OrderStatus.confirmed,
      'preparing': OrderStatus.preparing,
      '상품준비중': OrderStatus.preparing,
      'shipping': OrderStatus.shipping,
      '배송중': OrderStatus.shipping,
      'delivered': OrderStatus.delivered,
      '배송완료': OrderStatus.delivered,
      'cancelled': OrderStatus.cancelled,
      '취소/반품': OrderStatus.cancelled,
      'waiting': OrderStatus.pending,  // waiting을 pending으로 매핑
    };

    final result = statusMap[normalized] ?? OrderStatus.pending;
    print('[OrderStatus] 변환 결과: ${result.text} (isWaiting: ${result.isWaiting})');  // 로그 추가
    return result;
  }

  // UI 색상 관련
  Color get color {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return Colors.red;
      case OrderStatus.preparing:
        return Colors.orange;
      case OrderStatus.shipping:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.grey;
    }
  }

  // UI 아이콘 관련
  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return Icons.notification_important;
      case OrderStatus.preparing:
        return Icons.inventory;
      case OrderStatus.shipping:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}

/// 결제 방식을 나타내는 열거형
enum PaymentMethodType {
  card('카드결제'),
  virtualAccount('가상계좌'),
  transfer('계좌이체'),
  phone('휴대폰결제');

  final String text;
  const PaymentMethodType(this.text);

  static PaymentMethodType fromString(String method) {
    switch (method) {
      case '카드결제':
        return PaymentMethodType.card;
      case '가상계좌':
        return PaymentMethodType.virtualAccount;
      case '계좌이체':
        return PaymentMethodType.transfer;
      case '휴대폰결제':
        return PaymentMethodType.phone;
      default:
        return PaymentMethodType.card;
    }
  }
}

/// 결제 상태를 나타내는 열거형
enum PaymentStatus {
  pending('결제대기'),
  completed('결제완료'),
  cancelled('취소/반품'),
  refunded('환불완료'),
  failed('결제실패');

  final String text;
  const PaymentStatus(this.text);

  static PaymentStatus fromString(String status) {
    switch (status) {
      case '결제대기':
        return PaymentStatus.pending;
      case '결제완료':
        return PaymentStatus.completed;
      case '취소/반품':
        return PaymentStatus.cancelled;
      case '환불완료':
        return PaymentStatus.refunded;
      case '결제실패':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.pending;
    }
  }
}

/// 결제 정보를 담는 클래스
class PaymentInfo {
  final String method;
  final int amount;
  final int deliveryFee;
  final int subtotal;

  PaymentInfo({
    required this.method,
    required this.amount,
    required this.deliveryFee,
    required this.subtotal,
  });
}

/// 주문 상품 정보를 나타내는 클래스
class OrderItem {
  final String productNo;
  final String name;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final String? productImageUrl;

  OrderItem({
    required this.productNo,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productImageUrl,
  });

  // 편의를 위한 getter
  String get productName => name;
  int get price => unitPrice;
}

/// 주문 처리 이력을 나타내는 클래스
class OrderHistory {
  final String status;
  final DateTime timestamp;
  final String adminId;
  final String adminEmail;
  final String? note;

  OrderHistory({
    required this.status,
    required this.timestamp,
    required this.adminId,
    required this.adminEmail,
    this.note,
  });

  factory OrderHistory.fromMap(Map<String, dynamic> map) {
    return OrderHistory(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': timestamp,
      'adminId': adminId,
      'adminEmail': adminEmail,
      'note': note,
    };
  }
}

/// 주문 정보를 나타내는 클래스
class ProductOrder {
  final String id;
  final String orderNo;
  final DateTime? orderDate;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String deliveryStatus;
  final int deliveryFee;
  final String deliveryRequest;
  final int totalAmount;
  final String paymentMethod;
  final String? couponUsed;
  final List<String> productNo;
  final List<String>? productNames;
  final List<int> quantity;
  final List<int> unitPrice;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress1;
  final String receiverAddress2;
  final String receiverZip;
  final String userId;
  final String? trackingNumber;
  final bool isActive;

  // 편의를 위한 getter 메서드들
  String get shippingAddress => '$receiverAddress1 $receiverAddress2';
  String? get shippingNote => deliveryRequest;
  OrderStatus get status => OrderStatus.fromString(deliveryStatus);
  bool get canBeCancelled => 
    status != OrderStatus.cancelled && 
    status != OrderStatus.delivered;
  bool get canBeRefunded =>
    status == OrderStatus.delivered;

  // 결제 정보 관련 getter
  PaymentInfo get payment => PaymentInfo(
    method: paymentMethod,
    amount: totalAmount,
    deliveryFee: deliveryFee,
    subtotal: totalAmount - deliveryFee,
  );

  // 주문 상품 정보 관련 getter
  List<OrderItem> get items => List.generate(
    productNo.length,
    (i) => OrderItem(
      productNo: productNo[i],
      name: productNames?[i] ?? '상품 ${productNo[i]}',
      quantity: quantity[i],
      unitPrice: unitPrice[i],
      totalPrice: unitPrice[i] * quantity[i],
      productImageUrl: null,
    ),
  );

  const ProductOrder({
    required this.id,
    required this.orderNo,
    this.orderDate,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.deliveryStatus,
    required this.deliveryFee,
    required this.deliveryRequest,
    required this.totalAmount,
    required this.paymentMethod,
    this.couponUsed,
    required this.productNo,
    this.productNames,
    required this.quantity,
    required this.unitPrice,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress1,
    required this.receiverAddress2,
    required this.receiverZip,
    required this.userId,
    this.trackingNumber,
    this.isActive = true,
  });

  factory ProductOrder.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      try {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          if (value.contains('.')) {
            value = value.split('.')[0];
          }
          return DateTime.parse(value);
        }
        return null;
      } catch (e) {
        print('날짜 파싱 실패: $value - $e');
        return null;
      }
    }

    return ProductOrder(
      id: id,
      orderNo: map['orderNo'] ?? '',
      orderDate: parseDate(map['orderDate']),
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      deliveryStatus: map['deliveryStatus'] ?? '',
      deliveryFee: map['deliveryFee'] ?? 0,
      deliveryRequest: map['deliveryRequest'] ?? '',
      totalAmount: map['paymentAmount'] ?? 0,
      paymentMethod: map['paymentMethod'] ?? '',
      couponUsed: map['couponUsed'],
      productNo: List<String>.from(map['productNo'] ?? []),
      productNames: map['productNames'] != null 
          ? List<String>.from(map['productNames'])
          : null,
      quantity: List<int>.from(map['quantity'] ?? []),
      unitPrice: List<int>.from(map['unitPrice'] ?? []),
      receiverName: map['receiverName'] ?? '',
      receiverPhone: map['receiverPhone'] ?? '',
      receiverAddress1: map['receiverAddress1'] ?? '',
      receiverAddress2: map['receiverAddress2'] ?? '',
      receiverZip: map['receiverZip'] ?? '',
      userId: map['userId'] ?? '',
      trackingNumber: map['trackingNumber'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNo': orderNo,
      'orderDate': orderDate?.toIso8601String(),
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'deliveryStatus': deliveryStatus,
      'deliveryFee': deliveryFee,
      'deliveryRequest': deliveryRequest,
      'paymentAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'couponUsed': couponUsed,
      'productNo': productNo,
      'productNames': productNames,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress1': receiverAddress1,
      'receiverAddress2': receiverAddress2,
      'receiverZip': receiverZip,
      'userId': userId,
      'trackingNumber': trackingNumber,
      'isActive': isActive,
    };
  }
}

/// Timestamp 또는 String 형식의 날짜를 DateTime으로 변환
/// 
/// [value]가 Timestamp 또는 String 형식이 아니거나 파싱에 실패한 경우
/// 1970년 1월 1일을 반환
DateTime parseDateTime(dynamic value) {
  try {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    }
  } catch (e) {
    // 파싱 실패 시 기본값 반환
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// 주문 정보를 나타내는 클래스
class OrderInfo {
  final String userId;
  final String orderNo;
  final String adminId;
  final String adminEmail;
  final String? note;
  final OrderStatus status;
  final PaymentInfo payment;
  // ... 기타 필드들

  OrderInfo({
    required this.userId,
    required this.orderNo,
    required this.adminId,
    required this.adminEmail,
    this.note,
    required this.status,
    required this.payment,
    // ... 기타 필드들
  });

  // ProductOrder에서 OrderInfo로 변환하는 메서드
  static OrderInfo fromProductOrder(
    ProductOrder order, 
    String adminId, 
    String adminEmail,
    {String? note}
  ) {
    return OrderInfo(
      userId: order.userId,
      orderNo: order.orderNo,
      adminId: adminId,
      adminEmail: adminEmail,
      note: note,
      status: order.status,
      payment: order.payment,
    );
  }
}

// CustomerOrder를 OrderData로 변경
class OrderData {
  final String orderNo;
  final String orderDate;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String deliveryStatus;
  final int deliveryFee;
  final String deliveryRequest;
  final int paymentAmount;
  final String paymentMethod;
  final String couponUsed;
  final List<String> productNo;
  final List<int> quantity;
  final List<int> unitPrice;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress1;
  final String receiverAddress2;
  final String receiverZip;
  final String userId;

  OrderData({
    required this.orderNo,
    required this.orderDate,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.deliveryStatus,
    required this.deliveryFee,
    required this.deliveryRequest,
    required this.paymentAmount,
    required this.paymentMethod,
    required this.couponUsed,
    required this.productNo,
    required this.quantity,
    required this.unitPrice,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverAddress1,
    required this.receiverAddress2,
    required this.receiverZip,
    required this.userId,
  });

  factory OrderData.fromMap(Map<String, dynamic> map) {
    return OrderData(
      orderNo: map['orderNo'] ?? '',
      orderDate: map['orderDate'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      deliveryStatus: map['deliveryStatus'] ?? '',
      deliveryFee: map['deliveryFee'] ?? 0,
      deliveryRequest: map['deliveryRequest'] ?? '',
      paymentAmount: map['paymentAmount'] ?? 0,
      paymentMethod: map['paymentMethod'] ?? '',
      couponUsed: map['couponUsed'] ?? '',
      productNo: List<String>.from(map['productNo'] ?? []),
      quantity: List<int>.from(map['quantity'] ?? []),
      unitPrice: List<int>.from(map['unitPrice'] ?? []),
      receiverName: map['receiverName'] ?? '',
      receiverPhone: map['receiverPhone'] ?? '',
      receiverAddress1: map['receiverAddress1'] ?? '',
      receiverAddress2: map['receiverAddress2'] ?? '',
      receiverZip: map['receiverZip'] ?? '',
      userId: map['userId'] ?? '',
    );
  }
}

class ShopOrder {
  final String? orderId;
  final String? orderDate;
  final String? buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final String? deliveryStatus;
  final int paymentAmount;
  final bool isActive;

  const ShopOrder({
    this.orderId,
    this.orderDate,
    this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    this.deliveryStatus,
    required this.paymentAmount,
    this.isActive = true,
  });

  factory ShopOrder.fromMap(Map<String, dynamic> map) {
    return ShopOrder(
      orderId: map['orderId'] as String?,
      orderDate: map['orderDate'] as String?,
      buyerName: map['buyerName'] as String?,
      buyerEmail: map['buyerEmail'] as String?,
      buyerPhone: map['buyerPhone'] as String?,
      deliveryStatus: map['deliveryStatus'] as String?,
      paymentAmount: (map['paymentAmount'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'orderDate': orderDate,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'deliveryStatus': deliveryStatus,
      'paymentAmount': paymentAmount,
      'isActive': isActive,
    };
  }
} 