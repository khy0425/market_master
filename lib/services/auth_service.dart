import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 관리자 권한 레벨
  static const String SUPER_ADMIN = 'super_admin';
  static const String ADMIN = 'admin';
  static const String MANAGER = 'manager';

  // 현재 로그인된 관리자 정보 스트림
  Stream<AdminUser?> get authStateChanges => _auth.authStateChanges().asyncMap(
    (User? user) async {
      if (user == null) {
        print('로그인 상태 변경: 로그아웃');
        return null;
      }
      print('로그인 상태 변경: ${user.email}');
      return await _getAdminUser(user.uid);
    },
  );

  // 관리자 정보 조회
  Future<AdminUser?> _getAdminUser(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      
      print('관리자 정보 조회: ${doc.exists ? '성공' : '실패'} (UID: $uid)');
      
      if (!doc.exists) {
        print('관리자 권한 없음: $uid');
        return null;
      }

      final adminData = doc.data()!;
      print('관리자 권한 레벨: ${adminData['role']}');
      
      // 계정이 비활성화되었는지 확인
      if (adminData['isActive'] == false) {
        print('비활성화된 관리자 계정: $uid');
        return null;
      }

      return AdminUser.fromMap(uid, adminData);
    } catch (e) {
      print('관리자 정보 조회 오류: $e');
      return null;
    }
  }

  // 슈퍼 관리자 확인
  Future<bool> isSuperAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      return doc.exists && doc.data()?['role'] == SUPER_ADMIN;
    } catch (e) {
      print('슈퍼 관리자 확인 오류: $e');
      return false;
    }
  }

  // 관리자 권한 변경
  Future<void> updateAdminRole(String targetUid, String newRole) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw '권한 없음: 로그인이 필요합니다.';

      // 현재 사용자가 슈퍼 관리자인지 확인
      final isSuperAdminUser = await isSuperAdmin(currentUser.uid);
      if (!isSuperAdminUser) {
        throw '권한 없음: 슈퍼 관리자만 권한을 변경할 수 있습니다.';
      }

      await _firestore.collection('admins').doc(targetUid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.uid,
        'lastModificationType': 'role_change',
      });

      print('관리자 권한 변경 성공: $targetUid -> $newRole (수정자: ${currentUser.email})');
    } catch (e) {
      print('관리자 권한 변경 실패: $e');
      rethrow;
    }
  }

  // 관리자 계정 비활성화
  Future<void> deactivateAdmin(String targetUid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw '권한 없음: 로그인이 필요합니다.';

      final isSuperAdminUser = await isSuperAdmin(currentUser.uid);
      if (!isSuperAdminUser) {
        throw '권한 없음: 슈퍼 관리자만 계정을 비활성화할 수 있습니다.';
      }

      await _firestore.collection('admins').doc(targetUid).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
        'deactivatedBy': currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.uid,
        'lastModificationType': 'account_deactivation',
      });

      print('관리자 계정 비활성화 성공: $targetUid (처리자: ${currentUser.email})');
    } catch (e) {
      print('관리자 계정 비활성화 실패: $e');
      rethrow;
    }
  }

  // 이메일/비밀번호로 관리자 회원가입
  Future<AdminUser?> registerWithEmail(
    String email, 
    String password, 
    String displayName,
    {
      String? phoneNumber,
      String initialRole = MANAGER,
    }
  ) async {
    try {
      print('관리자 회원가입 시도: $email');

      // 이미 등록된 관리자인지 확인
      final adminSnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .get();
      
      if (adminSnapshot.docs.isNotEmpty) {
        print('회원가입 실패: 이미 등록된 관리자 이메일');
        throw '이미 등록된 관리자 이메일입니다.';
      }

      // 첫 번째 관리자 등록인 경우 SUPER_ADMIN 권한 부여
      final allAdmins = await _firestore.collection('admins').get();
      final isFirstAdmin = allAdmins.docs.isEmpty;
      final role = isFirstAdmin ? SUPER_ADMIN : initialRole;

      // 계정 생성
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user == null) throw '회원가입 실패';

      // 사용자 프로필 업데이트
      await user.updateDisplayName(displayName);
      
      // admins 컬렉션에 관리자 추가
      await _firestore.collection('admins').doc(user.uid).set({
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'role': role,
        'isActive': true,
      });

      print('관리자 회원가입 성공: $email (권한: $role)');

      return AdminUser(
        uid: user.uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        role: role,
      );
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    final user = _auth.currentUser;
    print('로그아웃: ${user?.email}');
    await _auth.signOut();
  }

  // 이메일/비밀번호로 로그인
  Future<AdminUser?> signInWithEmail(String email, String password) async {
    try {
      print('로그인 시도: $email');
      
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      if (user == null) throw '로그인 실패';

      // 관리자 권한 확인
      final adminUser = await _getAdminUser(user.uid);
      if (adminUser == null) {
        print('로그인 실패: 관리자 권한 없음 (${user.email})');
        await _auth.signOut();
        throw '관리자 권한이 없습니다.';
      }

      print('로그인 성공: ${user.email} (권한: ${adminUser.role})');
      return adminUser;
    } catch (e) {
      print('로그인 오류: $e');
      rethrow;
    }
  }

  // 비밀번호 변경
  Future<void> updatePassword(String targetUid, String newPassword) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw '권한 없음: 로그인이 필요합니다.';

      // 자신의 비밀번호를 변경하거나, 슈퍼 관리자만 다른 사용자의 비밀번호를 변경할 수 있음
      if (currentUser.uid != targetUid) {
        final isSuperAdminUser = await isSuperAdmin(currentUser.uid);
        if (!isSuperAdminUser) {
          throw '권한 없음: 다른 사용자의 비밀번호를 변경할 수 없습니다.';
        }
      }

      // Firebase Auth 비밀번호 변경
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: currentUser.email!,
        password: newPassword,
      );
      await userCredential.user?.updatePassword(newPassword);

      // 수정 이력 기록
      await _firestore.collection('admins').doc(targetUid).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.uid,
        'lastModificationType': 'password_change',
      });

      print('비밀번호 변경 성공: $targetUid (수정자: ${currentUser.email})');
    } catch (e) {
      print('비밀번호 변경 실패: $e');
      rethrow;
    }
  }

  // 관리자 정보 수정 이력 조회
  Future<List<Map<String, dynamic>>> getAdminModificationHistory(String adminId) async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('modifications')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('수정 이력 조회 실패: $e');
      return [];
    }
  }
}