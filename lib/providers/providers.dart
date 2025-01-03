import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';

// 서비스 프로바이더들
final productServiceProvider = Provider((ref) => ProductService());
final storageServiceProvider = Provider((ref) => StorageService()); 