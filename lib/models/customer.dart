import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_memo.dart';

class CustomerAddress {
  final String id;
  final String addressName;
  final String deliveryAddress1;
  final String deliveryAddress2;
  final String postalCode;
  final String userId;

  CustomerAddress({
    required this.id,
    required this.addressName,
    required this.deliveryAddress1,
    required this.deliveryAddress2,
    required this.postalCode,
    required this.userId,
  });

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: map['id'] ?? '',
      addressName: map['addressName'] ?? '',
      deliveryAddress1: map['deliveryAddress1'] ?? '',
      deliveryAddress2: map['deliveryAddress2'] ?? '',
      postalCode: map['postalCode'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'addressName': addressName,
      'deliveryAddress1': deliveryAddress1,
      'deliveryAddress2': deliveryAddress2,
      'postalCode': postalCode,
      'userId': userId,
    };
  }
}

class CustomerOrder {
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
  String userId;

  CustomerOrder({
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
    this.userId = '',
  });

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    return CustomerOrder(
      orderNo: map['orderNo'] ?? '',
      orderDate: map['orderDate'] ?? '',
      buyerName: map['buyerName'] ?? '',
      buyerEmail: map['buyerEmail'] ?? '',
      buyerPhone: map['buyerPhone'] ?? '',
      deliveryStatus: map['deliveryStatus'] ?? '',
      deliveryFee: map['deliveryFee'] ?? 0,
      deliveryRequest: map['deliveryRequest'] ?? '',
      paymentAmount: int.tryParse(map['paymentAmount']?.toString() ?? '0') ?? 0,
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

  Map<String, dynamic> toMap() {
    return {
      'orderNo': orderNo,
      'orderDate': orderDate,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'buyerPhone': buyerPhone,
      'deliveryStatus': deliveryStatus,
      'deliveryFee': deliveryFee,
      'deliveryRequest': deliveryRequest,
      'paymentAmount': paymentAmount,
      'paymentMethod': paymentMethod,
      'couponUsed': couponUsed,
      'productNo': productNo,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress1': receiverAddress1,
      'receiverAddress2': receiverAddress2,
      'receiverZip': receiverZip,
      'userId': userId,
    };
  }

  bool get isValid {
    return !['cancelled', '취소/반품'].contains(deliveryStatus);
  }
}

class Customer {
  final String uid;
  final List<CustomerAddress> addresses;
  final List<CustomerOrder> productOrders;
  final bool isRegular;
  final bool isTroubled;
  int? _totalOrderAmount;
  int get totalOrderAmount {
    _totalOrderAmount ??= productOrders
        .where((order) => order.isValid)
        .fold<int>(0, (sum, order) => sum + order.paymentAmount);
    return _totalOrderAmount!;
  }
  final DateTime? lastOrderDate;

  Customer({
    required this.uid,
    required this.addresses,
    required this.productOrders,
    this.isRegular = false,
    this.isTroubled = false,
    this.lastOrderDate,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    final orders = (map['productOrders'] as List<dynamic>? ?? [])
        .map((order) => CustomerOrder.fromMap(order))
        .toList();
    
    DateTime? lastOrderDate;
    if (orders.isNotEmpty) {
      lastOrderDate = orders
          .map((order) => DateTime.parse(order.orderDate))
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return Customer(
      uid: map['uid'] ?? '',
      addresses: (map['addresses'] as List<dynamic>? ?? [])
          .map((addr) => CustomerAddress.fromMap(addr))
          .toList(),
      productOrders: orders,
      isRegular: map['isRegular'] ?? false,
      isTroubled: map['isTroubled'] ?? false,
      lastOrderDate: lastOrderDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'productOrders': productOrders.map((order) => order.toMap()).toList(),
      'isRegular': isRegular,
      'isTroubled': isTroubled,
    };
  }
}