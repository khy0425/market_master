import 'package:cloud_firestore/cloud_firestore.dart';

/// 주문 상태를 나타내는 열거형
enum OrderStatus {
  pending('주문접수', 'pending'),
  confirmed('주문확인', 'confirmed'),
  preparing('상품준비중', 'preparing'),
  shipping('배송중', 'shipping'),
  delivered('배송완료', 'delivered'),
  cancelled('취소/반품', 'cancelled');

  final String text;
  final String code;
  const OrderStatus(this.text, this.code);

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (s) => s.text == status || s.code == status,
      orElse: () => OrderStatus.pending,
    );
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
  final String orderNo;
  final DateTime orderDate;
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

  ProductOrder({
    required this.orderNo,
    required this.orderDate,
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
  });

  factory ProductOrder.fromMap(Map<String, dynamic> map) {
    return ProductOrder(
      orderNo: map['orderNo'] ?? '',
      orderDate: DateTime.parse(map['orderDate'].toString().split('.')[0]),
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
    );
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