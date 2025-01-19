import 'package:cloud_firestore/cloud_firestore.dart';
import 'customer_memo.dart';
import 'dart:developer' as developer;

class CustomerAddress {
  final String id;
  final String addressName;
  final String deliveryAddress1;
  final String deliveryAddress2;
  final String postalCode;
  final String userId;

  const CustomerAddress({
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
    return ![
      'waiting',
      '입금대기',
      'cancelled',
      '취소/반품',
    ].contains(deliveryStatus);
  }

  bool get isPending => deliveryStatus == 'waiting' || deliveryStatus == '입금대기';
  bool get isCancelled => ['cancelled', '취소/반품'].contains(deliveryStatus);
  bool get isConfirmed => deliveryStatus == 'confirmed' || deliveryStatus == '주문접수';
  bool get isPreparing => deliveryStatus == 'preparing' || deliveryStatus == '상품준비중';
  bool get isShipping => deliveryStatus == 'shipping' || deliveryStatus == '배송중';
  bool get isDelivered => deliveryStatus == 'delivered' || deliveryStatus == '배송완료';
}

class Customer {
  final String id;  // Firestore document ID
  final String? uid;  // Firebase Auth UID
  final String? name;  // 고객 이름 (buyerName에서 가져옴)
  final String? email;  // 이메일 (buyerEmail에서 가져옴)
  final DateTime? joinDate;  // 가입일
  final List<CustomerAddress> addresses;
  final List<String> coupons;
  final List<int> favorites;
  final bool isRegular;
  final bool isTroubled;
  final List<CustomerMemo> memos;
  final List<CustomerOrder> productOrders;

  const Customer({
    required this.id,
    this.uid,
    this.name,
    this.email,
    this.joinDate,
    this.addresses = const [],
    this.coupons = const [],
    this.favorites = const [],
    this.isRegular = false,
    this.isTroubled = false,
    this.memos = const [],
    this.productOrders = const [],
  });

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    developer.log('Customer.fromMap 시작 - ID: $id');
    developer.log('입력 데이터: $map');

    try {
      // 주문 목록에서 가장 최근 주문의 구매자 정보 가져오기
      final productOrders = (map['productOrders'] as List<dynamic>? ?? [])
          .map((order) => CustomerOrder.fromMap(Map<String, dynamic>.from(order)))
          .toList();

      // 주소 목록 변환
      final addresses = (map['addresses'] as List<dynamic>? ?? [])
          .map((addr) => CustomerAddress.fromMap(Map<String, dynamic>.from(addr)))
          .toList();

      // 메모 목록 변환
      final memos = (map['memos'] as List<dynamic>? ?? [])
          .map((memo) => CustomerMemo.fromMap(Map<String, dynamic>.from(memo)))
          .toList();

      final customer = Customer(
        id: id,
        uid: map['uid'] as String?,
        addresses: addresses,
        coupons: List<String>.from(map['coupons'] ?? []),
        favorites: List<int>.from(map['favorites'] ?? []),
        isRegular: map['isRegular'] ?? false,
        isTroubled: map['isTroubled'] ?? false,
        memos: memos,
        productOrders: productOrders,
      );

      developer.log('Customer 변환 성공: $customer');
      return customer;
    } catch (e, stackTrace) {
      developer.log(
        'Customer.fromMap 오류',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'joinDate': joinDate,
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'coupons': coupons,
      'favorites': favorites,
      'isRegular': isRegular,
      'isTroubled': isTroubled,
      'memos': memos.map((memo) => memo.toMap()).toList(),
      'productOrders': productOrders.map((order) => order.toMap()).toList(),
    };
  }

  // 유용한 getter 추가
  int get totalOrderAmount => productOrders
      .where((order) => order.isValid)
      .fold<int>(0, (sum, order) => sum + order.paymentAmount);

  DateTime? get lastOrderDate => productOrders.isEmpty
      ? null
      : DateTime.tryParse(productOrders
          .map((o) => o.orderDate)
          .reduce((a, b) => a.compareTo(b) > 0 ? a : b));

  // 가장 최근 주문의 배송지 정보
  CustomerAddress? get latestAddress => productOrders.isEmpty
      ? addresses.isEmpty ? null : addresses.first
      : CustomerAddress(
          id: DateTime.now().toIso8601String(),
          addressName: "최근 배송지",
          deliveryAddress1: productOrders.last.receiverAddress1,
          deliveryAddress2: productOrders.last.receiverAddress2,
          postalCode: productOrders.last.receiverZip,
          userId: uid ?? id,
        );

  // 유효 주문 수 계산
  int get validOrderCount => productOrders
      .where((order) => order.isValid)
      .length;

  // 대기 중인 주문 금액
  int get pendingOrderAmount => productOrders
      .where((order) => order.isPending)
      .fold<int>(0, (sum, order) => sum + order.paymentAmount);

  @override
  String toString() {
    return 'Customer{id: $id, uid: $uid, addresses: ${addresses.length}, orders: ${productOrders.length}}';
  }
}