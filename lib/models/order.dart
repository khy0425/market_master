import 'package:cloud_firestore/cloud_firestore.dart';

/// 주문 상태를 나타내는 열거형
enum OrderStatus {
  pending('주문접수'),
  confirmed('주문확인'),
  preparing('상품준비중'),
  shipping('배송중'),
  delivered('배송완료'),
  cancelled('취소/반품');

  final String text;
  const OrderStatus(this.text);

  static OrderStatus fromString(String status) {
    switch (status) {
      case '주문접수':
        return OrderStatus.pending;
      case '주문확인':
        return OrderStatus.confirmed;
      case '상품준비중':
        return OrderStatus.preparing;
      case '배송중':
        return OrderStatus.shipping;
      case '배송완료':
        return OrderStatus.delivered;
      case '취소/반품':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
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

/// 주문 상품 정보를 나타내는 클래스
class OrderItem {
  final String productNo;
  final int quantity;
  final int unitPrice;
  final String? productName;
  final String? productImageUrl;

  /// 상품의 단가를 반환
  int get price => unitPrice;

  /// 상품의 총 금액 (단가 * 수량)을 계산
  int get totalPrice => quantity * unitPrice;

  OrderItem({
    required this.productNo,
    required this.quantity,
    required this.unitPrice,
    this.productName,
    this.productImageUrl,
  });

  // fromMap 메서드 개선
  factory OrderItem.fromMap(Map<String, dynamic> map, {
    String? productName,
    String? productImageUrl,
  }) {
    return OrderItem(
      productNo: map['productNo']?.toString() ?? '',
      quantity: map['quantity'] as int? ?? 0,
      unitPrice: map['unitPrice'] as int? ?? 0,
      productName: productName,
      productImageUrl: productImageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productNo': productNo,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'productName': productName,
      'productImageUrl': productImageUrl,
    };
  }
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

/// 결제 정보를 나타내는 클래스
class PaymentInfo {
  final PaymentStatus status;
  final PaymentMethodType method;
  final int amount;
  final DateTime paymentDate;
  
  // PG사 관련 정보
  final String? pgProvider;
  final String? paymentKey;
  final String? transactionId;
  final String? cardCompany;
  final String? cardNumber;
  final int? installmentPlan;
  
  // 가상계좌 정보
  final String? virtualAccountBank;
  final String? virtualAccountNumber;
  final String? virtualAccountHolder;
  final DateTime? virtualAccountExpiry;
  
  // 환불 정보
  final int? refundAmount;
  final DateTime? refundDate;
  final String? refundReason;
  final String? refundKey;

  PaymentInfo({
    required this.status,
    required this.method,
    required this.amount,
    required this.paymentDate,
    this.pgProvider,
    this.paymentKey,
    this.transactionId,
    this.cardCompany,
    this.cardNumber,
    this.installmentPlan,
    this.virtualAccountBank,
    this.virtualAccountNumber,
    this.virtualAccountHolder,
    this.virtualAccountExpiry,
    this.refundAmount,
    this.refundDate,
    this.refundReason,
    this.refundKey,
  });

  factory PaymentInfo.fromMap(Map<String, dynamic> map) {
    return PaymentInfo(
      status: PaymentStatus.fromString(map['status'] ?? '결제대기'),
      method: PaymentMethodType.fromString(map['method'] ?? '카드결제'),
      amount: map['amount'] as int? ?? 0,
      paymentDate: parseDateTime(map['paymentDate']),
      pgProvider: map['pgProvider'],
      paymentKey: map['paymentKey'],
      transactionId: map['transactionId'],
      cardCompany: map['cardCompany'],
      cardNumber: map['cardNumber'],
      installmentPlan: map['installmentPlan'],
      virtualAccountBank: map['virtualAccountBank'],
      virtualAccountNumber: map['virtualAccountNumber'],
      virtualAccountHolder: map['virtualAccountHolder'],
      virtualAccountExpiry: map['virtualAccountExpiry'] != null 
          ? parseDateTime(map['virtualAccountExpiry'])
          : null,
      refundAmount: map['refundAmount'],
      refundDate: map['refundDate'] != null 
          ? parseDateTime(map['refundDate'])
          : null,
      refundReason: map['refundReason'],
      refundKey: map['refundKey'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.text,
      'method': method.text,
      'amount': amount,
      'paymentDate': paymentDate,
      'pgProvider': pgProvider,
      'paymentKey': paymentKey,
      'transactionId': transactionId,
      'cardCompany': cardCompany,
      'cardNumber': cardNumber,
      'installmentPlan': installmentPlan,
      'virtualAccountBank': virtualAccountBank,
      'virtualAccountNumber': virtualAccountNumber,
      'virtualAccountHolder': virtualAccountHolder,
      'virtualAccountExpiry': virtualAccountExpiry,
      'refundAmount': refundAmount,
      'refundDate': refundDate,
      'refundReason': refundReason,
      'refundKey': refundKey,
    };
  }
}

/// 주문 정보를 나타내는 클래스
class ProductOrder {
  final String userId;
  final String orderNo;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;
  final String receiverName;
  final String receiverPhone;
  final String receiverZip;
  final String receiverAddress1;
  final String receiverAddress2;
  final List<OrderItem> items;
  final int deliveryFee;
  final String deliveryStatus;
  final String? deliveryRequest;
  final String? couponUsed;
  final DateTime orderDate;
  final String? trackingNumber;
  final List<OrderHistory> history;
  final PaymentInfo payment;
  
  /// 배송지 전체 주소를 반환
  String get shippingAddress => '$receiverAddress1 $receiverAddress2';
  
  /// 배송 요청사항을 반환
  String? get shippingNote => deliveryRequest;
  
  /// 현재 주문 상태를 OrderStatus 열거형으로 반환
  OrderStatus get status => OrderStatus.fromString(deliveryStatus);

  ProductOrder({
    required this.userId,
    required this.orderNo,
    required this.buyerName,
    required this.buyerEmail,
    required this.buyerPhone,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverZip,
    required this.receiverAddress1,
    required this.receiverAddress2,
    required this.items,
    required this.deliveryFee,
    required this.deliveryStatus,
    this.deliveryRequest,
    this.couponUsed,
    required this.orderDate,
    this.trackingNumber,
    this.history = const [],
    required this.payment,
  });

  factory ProductOrder.fromMap(Map<String, dynamic> map) {
    // 주문 상품 정보 변환
    List<dynamic> productNos = map['productNo'] as List? ?? [];
    List<dynamic> quantities = map['quantity'] as List? ?? [];
    List<dynamic> unitPrices = map['unitPrice'] as List? ?? [];
    List<dynamic> productNames = map['productNames'] as List? ?? [];
    
    List<OrderItem> items = [];
    for (int i = 0; i < productNos.length; i++) {
      items.add(OrderItem.fromMap(
        {
          'productNo': productNos[i],
          'quantity': quantities.length > i ? quantities[i] : 0,
          'unitPrice': unitPrices.length > i ? unitPrices[i] : 0,
        },
        productName: productNames.length > i ? productNames[i]?.toString() : '상품 ${productNos[i]}',
      ));
    }

    // 주문일시 파싱 로직 개선
    DateTime parsedDate;
    try {
      if (map['orderDate'] is Timestamp) {
        parsedDate = (map['orderDate'] as Timestamp).toDate();
      } else if (map['orderDate'] is String) {
        parsedDate = DateTime.parse(map['orderDate']);
      } else {
        // 주문일시가 없는 경우 1970년으로 설정
        parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
      }
    } catch (e) {
      // 파싱 실패시에도 1970년으로 설정
      parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
    }

    // 주문 이력 변환
    List<OrderHistory> historyList = [];
    if (map['history'] != null) {
      historyList = (map['history'] as List)
          .map((item) => OrderHistory.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // 기존 결제 정보를 PaymentInfo로 변환
    PaymentInfo paymentInfo = PaymentInfo.fromMap(
      map['payment'] as Map<String, dynamic>? ?? {
        'status': map['paymentStatus'] ?? '결제완료',
        'method': map['paymentMethod'] ?? '카드결제',
        'amount': map['paymentAmount'] ?? 0,
        'paymentDate': map['orderDate'],
      }
    );

    return ProductOrder(
      userId: map['userId']?.toString() ?? '',
      orderNo: map['orderNo']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? '',
      buyerEmail: map['buyerEmail']?.toString() ?? '',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      receiverName: map['receiverName']?.toString() ?? '',
      receiverPhone: map['receiverPhone']?.toString() ?? '',
      receiverZip: map['receiverZip']?.toString() ?? '',
      receiverAddress1: map['receiverAddress1']?.toString() ?? '',
      receiverAddress2: map['receiverAddress2']?.toString() ?? '',
      items: items,
      deliveryFee: map['deliveryFee'] as int? ?? 0,
      deliveryStatus: map['deliveryStatus']?.toString() ?? '주문접수',
      deliveryRequest: map['deliveryRequest']?.toString(),
      couponUsed: map['couponUsed']?.toString(),
      orderDate: parsedDate,
      trackingNumber: map['trackingNumber']?.toString(),
      history: historyList,
      payment: paymentInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNo': orderNo,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverZip': receiverZip,
      'receiverAddress1': receiverAddress1,
      'receiverAddress2': receiverAddress2,
      'productNo': items.map((e) => e.productNo).toList(),
      'quantity': items.map((e) => e.quantity).toList(),
      'unitPrice': items.map((e) => e.unitPrice).toList(),
      'deliveryFee': deliveryFee,
      'deliveryStatus': deliveryStatus,
      'deliveryRequest': deliveryRequest,
      'couponUsed': couponUsed,
      'orderDate': orderDate.toIso8601String(),
      'trackingNumber': trackingNumber,
      'history': history.map((h) => h.toMap()).toList(),
      'payment': payment.toMap(),
    };
  }

  /// 주문 상품의 총 금액을 계산 (배송비 포함)
  int get totalAmount => items.fold<int>(
    0, 
    (sum, item) => sum + (item.price * item.quantity)
  ) + deliveryFee;
  
  /// 결제가 완료되었는지 확인
  bool get isPaymentCompleted => 
    payment.status == PaymentStatus.completed;
  
  /// 주문 취소가 가능한지 확인
  bool get canBeCancelled => 
    status != OrderStatus.cancelled && 
    status != OrderStatus.delivered;

  /// 환불이 가능한지 확인
  bool get canBeRefunded =>
    status == OrderStatus.delivered &&
    payment.status == PaymentStatus.completed;
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