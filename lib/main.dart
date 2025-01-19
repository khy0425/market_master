import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_master/services/auth_service.dart';
import 'package:market_master/views/dashboard/admin_dashboard_view.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import 'views/auth/login_view.dart';
import 'views/admin/manage_admins_view.dart';
import 'views/product/product_list_view.dart';
import 'views/order/order_list_view.dart';
import 'views/customer/customer_list_view.dart';

/// 마켓마스터 관리자 앱의 메인 엔트리 포인트
/// 
/// Firebase 초기화 및 앱 실행을 담당합니다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: 'Market Master',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Consumer(
          builder: (context, ref, _) {
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                return snapshot.hasData 
                    ? const AdminDashboardView() 
                    : const LoginView();
              },
            );
          },
        ),
      ),
    ),
  );
}

/// 앱의 루트 위젯
/// 
/// 테마 설정 및 라우팅 설정을 담당합니다.
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Market Master',
      theme: ThemeData(
        // 밝은 테마 기본 설정
        brightness: Brightness.light,
        
        // 기본 배경색을 흰색으로 설정
        scaffoldBackgroundColor: Colors.white,
        
        // AppBar 테마
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        
        // 카드 테마
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 1,
        ),
        
        // 기본 색상 스키마
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          background: Colors.white,
          surface: Colors.white,
        ),
        
        // 입력 필드 테마
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // 로그인된 상태면 대시보드로, 아니면 로그인 화면으로
          return snapshot.hasData 
              ? const AdminDashboardView()
              : const LoginView();
        },
      ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginView();
        return const AdminDashboard();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Master Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
            tooltip: '로그아웃',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            authState.when(
              data: (user) => UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                accountName: Text(
                  user?.displayName ?? '이름 없음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                accountEmail: Container(
                  constraints: const BoxConstraints(maxHeight: 80),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getRoleDisplayName(user?.role),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (user?.createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '가입일: ${_formatDate(user!.createdAt!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                currentAccountPicture: null,
              ),
              loading: () => const DrawerHeader(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const DrawerHeader(
                child: Center(child: Text('오류 발생')),
              ),
            ),
            // 관리자 관리 메뉴 (SUPER_ADMIN만)
            authState.when(
              data: (user) {
                if (user?.role == AuthService.SUPER_ADMIN) {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('관리자 관리'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageAdminsView(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 상품 관리 (SUPER_ADMIN, ADMIN)
            authState.when(
              data: (user) {
                if (user?.role == AuthService.SUPER_ADMIN ||
                    user?.role == AuthService.ADMIN) {
                  return ListTile(
                    leading: const Icon(Icons.inventory),
                    title: const Text('상품 관리'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductListView(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 주문 관리 (모든 권한)
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('주문 관리'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderListView(),
                  ),
                );
              },
            ),
            // 고객 관리 (SUPER_ADMIN, ADMIN)
            authState.when(
              data: (user) {
                if (user?.role == AuthService.SUPER_ADMIN ||
                    user?.role == AuthService.ADMIN) {
                  return ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('고객 관리'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CustomerListView(),
                        ),
                      );
                      if (Scaffold.of(context).isDrawerOpen) {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // 통계 (SUPER_ADMIN, ADMIN)
            authState.when(
              data: (user) {
                if (user?.role == AuthService.SUPER_ADMIN ||
                    user?.role == AuthService.ADMIN) {
                  return ListTile(
                    leading: const Icon(Icons.analytics),
                    title: const Text('통계'),
                    onTap: () {
                      // TODO: 통계 화면으로 이동
                    },
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('관리자 대시보드'),
            const SizedBox(height: 16),
            // Firebase 테스트 버튼은 개발 중에만 사용
            if (const bool.fromEnvironment('dart.vm.product') == false)
              ElevatedButton(
                onPressed: () async {
                  try {
                    final firestore = FirebaseFirestore.instance;
                    final testDoc = await firestore.collection('test').add({
                      'message': 'Firebase 연결 테스트',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    print('Firestore 테스트 문서 생성 성공: ${testDoc.id}');
                  } catch (e) {
                    print('Firestore 테스트 실패: $e');
                  }
                },
                child: const Text('Firebase 연결 테스트'),
              ),
          ],
        ),
      ),
    );
  }
}

// 권한 표시 이름 변환 함수
String _getRoleDisplayName(String? role) {
  switch (role) {
    case AuthService.SUPER_ADMIN:
      return '최고 관리자';
    case AuthService.ADMIN:
      return '관리자';
    case AuthService.MANAGER:
      return '매니저';
    default:
      return '권한 없음';
  }
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}