import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
// ... 다른 import들

/// 상품 서비스 프로바이더
final productServiceProvider = Provider((ref) => ProductService());

/// 주문 서비스 프로바이더
final orderServiceProvider = Provider((ref) => OrderService());

/// 인증 서비스 프로바이더
final authServiceProvider = Provider((ref) => AuthService());

// ... 다른 프로바이더들 