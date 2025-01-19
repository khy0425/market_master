import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModification {
  final String id;
  final String productId;
  final String modifiedBy;
  final DateTime modifiedAt;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final String? comment;

  const ProductModification({
    required this.id,
    required this.productId,
    required this.modifiedBy,
    required this.modifiedAt,
    required this.field,
    required this.oldValue,
    required this.newValue,
    this.comment,
  });

  factory ProductModification.fromMap(String id, Map<String, dynamic> map) {
    return ProductModification(
      id: id,
      productId: map['productId'] ?? '',
      modifiedBy: map['modifiedBy'] ?? '',
      modifiedAt: (map['modifiedAt'] as Timestamp).toDate(),
      field: map['field'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      comment: map['comment'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'modifiedBy': modifiedBy,
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'comment': comment,
    };
  }
} 