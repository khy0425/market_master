import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final bool isAdmin;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedBy;

  AdminUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.isAdmin = true,
    this.role = 'admin',
    this.createdAt,
    this.updatedAt,
    this.updatedBy,
  });

  factory AdminUser.fromMap(String uid, Map<String, dynamic> map) {
    return AdminUser(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      isAdmin: true,
      role: map['role'] ?? 'admin',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      updatedBy: map['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'role': role,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }
}