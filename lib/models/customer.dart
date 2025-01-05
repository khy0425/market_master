import 'package:cloud_firestore/cloud_firestore.dart';

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
    };
  }
}

class Customer {
  final String uid;
  final List<CustomerAddress> addresses;
  final List<String> coupons;
  final List<int> favorites;
  final List<CustomerOrder> productOrders;

  const Customer({
    required this.uid,
    this.addresses = const [],
    this.coupons = const [],
    this.favorites = const [],
    this.productOrders = const [],
  });

  factory Customer.fromMap(String uid, Map<String, dynamic> map) {
    return Customer(
      uid: uid,
      addresses: (map['addresses'] as List<dynamic>? ?? [])
          .map((addr) => CustomerAddress.fromMap(addr))
          .toList(),
      coupons: List<String>.from(map['coupons'] ?? []),
      favorites: List<int>.from(map['favorites'] ?? []),
      productOrders: (map['productOrders'] as List<dynamic>? ?? []) 
          .map((order) => CustomerOrder.fromMap(order))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'coupons': coupons,
      'favorites': favorites,
      'productOrders': productOrders.map((order) => order.toMap()).toList(),
    };
  }
} 