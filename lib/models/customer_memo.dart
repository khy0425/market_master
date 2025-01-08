import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 메모 종류 enum
enum MemoType {
  normal('일반메모', Icons.note, Colors.grey),
  important('중요메모', Icons.star, Colors.orange),
  warning('경고메모', Icons.warning, Colors.red),
  vip('VIP메모', Icons.diamond, Colors.purple);
  
  final String text;
  final IconData icon;
  final Color color;
  const MemoType(this.text, this.icon, this.color);
}

class CustomerMemo {
  final String id;
  final String customerId;
  final String content;
  final String adminId;
  final DateTime createdAt;
  final MemoType type;
  final bool isPrivate;

  const CustomerMemo({
    required this.id,
    required this.customerId,
    required this.content,
    required this.adminId,
    required this.createdAt,
    this.type = MemoType.normal,
    this.isPrivate = false,
  });

  factory CustomerMemo.fromMap(Map<String, dynamic> map) {
    return CustomerMemo(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      content: map['content'] ?? '',
      adminId: map['adminId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: MemoType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => MemoType.normal,
      ),
      isPrivate: map['isPrivate'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'content': content,
      'adminId': adminId,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.name,
      'isPrivate': isPrivate,
    };
  }
} 