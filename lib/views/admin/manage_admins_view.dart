import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_user.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

class ManageAdminsView extends ConsumerStatefulWidget {
  const ManageAdminsView({super.key});

  @override
  ConsumerState<ManageAdminsView> createState() => _ManageAdminsViewState();
}

class _ManageAdminsViewState extends ConsumerState<ManageAdminsView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = AuthService.MANAGER;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _showAddAdminDialog() async {
    final currentUser = ref.read(authStateProvider).value;
    _emailController.clear();
    _passwordController.clear();
    _displayNameController.clear();
    _phoneController.clear();
    
    // 현재 사용자의 권한에 따라 부여 가능한 권한 설정
    List<DropdownMenuItem<String>> availableRoles = [];
    
    if (currentUser?.role == AuthService.SUPER_ADMIN) {
      // SUPER_ADMIN은 모든 권한 부여 가능
      availableRoles = [
        DropdownMenuItem(
          value: AuthService.ADMIN,
          child: Text('관리자 (${AuthService.ADMIN})'),
        ),
        DropdownMenuItem(
          value: AuthService.MANAGER,
          child: Text('매니저 (${AuthService.MANAGER})'),
        ),
      ];
    } else if (currentUser?.role == AuthService.ADMIN) {
      // ADMIN은 MANAGER 권한만 부여 가능
      availableRoles = [
        DropdownMenuItem(
          value: AuthService.MANAGER,
          child: Text('매니저 (${AuthService.MANAGER})'),
        ),
      ];
    }

    _selectedRole = availableRoles.first.value!;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 관리자 추가'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '이름을 입력하세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '휴대폰 번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '01012345678',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return '휴대폰 번호를 입력하세요';
                    if (!RegExp(r'^010\d{8}$').hasMatch(value!)) {
                      return '올바른 휴대폰 번호 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return '이메일을 입력하세요';
                    if (!value!.contains('@')) return '올바른 이메일 형식이 아닙니다';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return '비밀번호를 입력하세요';
                    if (value!.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 권한 선택
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '부여할 권한',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.admin_panel_settings),
                      ),
                      items: availableRoles,
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '현재 내 권한: ${_getRoleDisplayName(currentUser?.role ?? "")}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await ref.read(authServiceProvider).registerWithEmail(
                        _emailController.text,
                        _passwordController.text,
                        _displayNameController.text,
                        phoneNumber: _phoneController.text,
                        initialRole: _selectedRole,
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('관리자가 추가되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(String adminId) async {
    final currentUser = ref.read(authStateProvider).value;
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(adminId)
        .get();
    
    if (!adminDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('관리자를 찾을 수 없습니다')),
        );
      }
      return;
    }

    final adminData = adminDoc.data()!;
    String currentRole = adminData['role'];
    bool isActive = adminData['isActive'] ?? true;

    // 권한 변경 가능 여부 확인 수정
    bool canChangeRole = currentUser?.role == AuthService.SUPER_ADMIN;
    // SUPER_ADMIN이 아닌 경우에만 자신의 계정 권한 변경 불가
    if (adminData['email'] == currentUser?.email && 
        currentUser?.role != AuthService.SUPER_ADMIN) {
      canChangeRole = false;
    }

    // 사용 가능한 권한 목록 설정
    List<DropdownMenuItem<String>> availableRoles = [];
    if (currentUser?.role == AuthService.SUPER_ADMIN) {
      availableRoles = [
        DropdownMenuItem(
          value: AuthService.SUPER_ADMIN,
          child: Text('최고 관리자 (${AuthService.SUPER_ADMIN})'),
        ),
        DropdownMenuItem(
          value: AuthService.ADMIN,
          child: Text('관리자 (${AuthService.ADMIN})'),
        ),
        DropdownMenuItem(
          value: AuthService.MANAGER,
          child: Text('매니저 (${AuthService.MANAGER})'),
        ),
      ];
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('관리자 수정: ${adminData['email']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('권한 설정'),
              if (canChangeRole)
                DropdownButton<String>(
                  value: currentRole,
                  items: availableRoles,
                  onChanged: (value) {
                    setState(() => currentRole = value!);
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '현재 권한: ${_getRoleDisplayName(currentRole)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              if (!canChangeRole)
                const Text(
                  '권한 변경은 최고 관리자만 가능합니다.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 16),
              // 계정 활성화 토글은 SUPER_ADMIN만 가능
              if (currentUser?.role == AuthService.SUPER_ADMIN)
                Row(
                  children: [
                    const Text('계정 활성화'),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setState(() => isActive = value);
                      },
                    ),
                  ],
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  // 권한 변경 (SUPER_ADMIN만 가능)
                  if (canChangeRole) {
                    await ref
                        .read(authServiceProvider)
                        .updateAdminRole(adminId, currentRole);
                  }
                  
                  // 계정 활성화/비활성화 (SUPER_ADMIN만 가능)
                  if (currentUser?.role == AuthService.SUPER_ADMIN) {
                    if (!isActive) {
                      await ref.read(authServiceProvider).deactivateAdmin(adminId);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('admins')
                          .doc(adminId)
                          .update({'isActive': true});
                    }
                  }

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('관리자 정보가 수정되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                }
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(String adminId) async {
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: '새 비밀번호',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return '비밀번호를 입력하세요';
                  if (value!.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return '비밀번호가 일치하지 않습니다';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  await ref
                      .read(authServiceProvider)
                      .updatePassword(adminId, _newPasswordController.text);
                  
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('비밀번호가 변경되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류 발생: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );

    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 권한 표시 이름 변환 함수 추가
  String _getRoleDisplayName(String role) {
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

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final isSuperAdmin = currentUser?.role == AuthService.SUPER_ADMIN;

    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 계정 관리'),
        actions: [
          // AppBar의 관리자 추가 버튼
          if (isSuperAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('새 관리자 추가'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _showAddAdminDialog(),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 상단에 설명 추드 추가
          if (ref.watch(authStateProvider).value?.role == AuthService.SUPER_ADMIN)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '관리자 계정 관리',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• 상단의 "새 관리자 추가" 버튼으로 새로운 관리자를 등록할 수 있습니다.\n'
                        '• 관리자 목록에서 각 관리자의 정보를 수정하거나 비활성화할 수 있습니다.\n'
                        '• 자신의 계정은 비밀번호 변경만 가능합니다.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // 기존 관리자 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('admins').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final admin = snapshot.data!.docs[index];
                    final data = admin.data() as Map<String, dynamic>;
                    
                    final createdAt = data['createdAt'] is Timestamp 
                        ? (data['createdAt'] as Timestamp).toDate() 
                        : null;
                    
                    final updatedAt = data['updatedAt'] is Timestamp 
                        ? (data['updatedAt'] as Timestamp).toDate() 
                        : null;
                    
                    final modType = data['lastModificationType'] as String?;
                    final isActive = data['isActive'] as bool? ?? true;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(data['email'] ?? '이메일 없음'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('권한: ${data['role'] ?? '권한 없음'}'),
                            if (createdAt != null)
                              Text(
                                '생성: ${_formatDate(createdAt)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (updatedAt != null)
                              Text(
                                '수정: ${_formatDate(updatedAt)}${modType != null ? ' ($modType)' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            Text(
                              '상태: ${isActive ? '활성' : '비활성'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 자신의 계정이거나 SUPER_ADMIN인 경우에만 수정 버튼 표시
                            if (data['email'] == ref.watch(authStateProvider).value?.email ||
                                ref.watch(authStateProvider).value?.role == AuthService.SUPER_ADMIN)
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditDialog(admin.id),
                                tooltip: '관리자 정보 수정',
                              ),
                            // 현재 로그인한 사용자의 계정인 경우 비밀번호 변경 버튼 추가
                            if (data['email'] == ref.watch(authStateProvider).value?.email)
                              IconButton(
                                icon: const Icon(Icons.key),
                                onPressed: () => _showChangePasswordDialog(admin.id),
                                tooltip: '비밀번호 변경',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // FloatingActionButton 추가
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showAddAdminDialog(),
              icon: const Icon(Icons.person_add),
              label: const Text('새 관리자 추가'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              elevation: 4,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
} 