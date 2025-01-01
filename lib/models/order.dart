import 'package:cloud_firestore/cloud_firestore.dart';

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

class OrderItem {
  final String productNo;
  final int quantity;
  final int unitPrice;
  final String? productName;
  final String? productImageUrl;

  int get price => unitPrice;

  OrderItem({
    required this.productNo,
    required this.quantity,
    required this.unitPrice,
    this.productName,
    this.productImageUrl,
  });

  factory OrderItem.fromMap(String productNo, int quantity, int unitPrice, {String? productName, String? productImageUrl}) {
    return OrderItem(
      productNo: productNo,
      quantity: quantity,
      unitPrice: unitPrice,
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
  final int paymentAmount;
  final String paymentMethod;
  final String deliveryStatus;
  final String? deliveryRequest;
  final String? couponUsed;
  final DateTime orderDate;
  final String? trackingNumber;
  final List<OrderHistory> history;
  
  String get shippingAddress => '$receiverAddress1 $receiverAddress2';
  String? get shippingNote => deliveryRequest;
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
    required this.paymentAmount,
    required this.paymentMethod,
    required this.deliveryStatus,
    this.deliveryRequest,
    this.couponUsed,
    required this.orderDate,
    this.trackingNumber,
    this.history = const [],
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
        productNos[i].toString(),
        quantities.length > i ? quantities[i] as int : 0,
        unitPrices.length > i ? unitPrices[i] as int : 0,
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
      paymentAmount: map['paymentAmount'] as int? ?? 0,
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      deliveryStatus: map['deliveryStatus']?.toString() ?? '주문접수',
      deliveryRequest: map['deliveryRequest']?.toString(),
      couponUsed: map['couponUsed']?.toString(),
      orderDate: parsedDate,
      trackingNumber: map['trackingNumber']?.toString(),
      history: historyList,
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
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'deliveryStatus': deliveryStatus,
      'deliveryRequest': deliveryRequest,
      'couponUsed': couponUsed,
      'orderDate': orderDate.toIso8601String(),
      'trackingNumber': trackingNumber,
      'history': history.map((h) => h.toMap()).toList(),
    };
  }
} 