import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModification {
  final String id;
  final String productId;
  final String modifiedBy;  // 수정한 관리자 이메일
  final DateTime modifiedAt;
  final String modificationType;  // 수정 유형 (가격변경, 재고변경, 정보수정 등)
  final Map<String, dynamic> changes;  // 변경된 필드와 값
  final String? comment;  // 수정 사유나 코멘트

  ProductModification({
    required this.id,
    required this.productId,
    required this.modifiedBy,
    required this.modifiedAt,
    required this.modificationType,
    required this.changes,
    this.comment,
  });

  factory ProductModification.fromMap(String id, Map<String, dynamic> map) {
    return ProductModification(
      id: id,
      productId: map['productId'],
      modifiedBy: map['modifiedBy'],
      modifiedAt: (map['modifiedAt'] as Timestamp).toDate(),
      modificationType: map['modificationType'],
      changes: map['changes'],
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'modifiedBy': modifiedBy,
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'modificationType': modificationType,
      'changes': changes,
      'comment': comment,
    };
  }
} 