import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_master/views/product/product_edit_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:developer' as developer;

import '../../models/product.dart';
import '../../models/product_modification.dart';
import '../../views/product/product_edit_view.dart';
import '../../utils/format_utils.dart';
import '../../widgets/network_image_with_retry.dart';
import '../../services/storage_service.dart';
import '../../services/product_service.dart';

final productServiceProvider = Provider((ref) => ProductService());

class ProductDetailView extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailView({super.key, required this.product});

  @override
  ConsumerState<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<ProductDetailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: '상품 정보 수정',
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductEditView(product: widget.product),
                ),
              );
              
              if (result == true && mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '상품 삭제',
            onPressed: () => _showDeleteConfirmDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 기본 정보 섹션
            _buildSection(
              '기본 정보',
              [
                _buildInfoRow('상품코드', widget.product.productCode),
                _buildInfoRow('상품명', widget.product.name),
                _buildInfoRow('카테고리', '${widget.product.mainCategory} > ${widget.product.subCategory}'),
                _buildInfoRow('판매상태', widget.product.isActive ? '판매중' : '판매중지'),
              ],
            ),
            
            // 가격 정보 섹션
            _buildSection(
              '가격 정보',
              [
                _buildInfoRow('정가', FormatUtils.formatPrice(widget.product.originalPrice)),
                _buildInfoRow('판매가', FormatUtils.formatPrice(widget.product.sellingPrice)),
                _buildInfoRow('할인율', '${widget.product.discountRate}%'),
              ],
            ),

            // 재고 정보 섹션
            _buildSection(
              '재고 정보',
              [
                _buildInfoRow('현재 재고', '${widget.product.stockQuantity}개'),
              ],
            ),

            // 수정 이력 섹션을 재고 정보 다음으로 이동
            _buildSection(
              '수정 이력',
              [
                StreamBuilder<List<ProductModification>>(
                  stream: ref.read(productServiceProvider).getProductModifications(widget.product.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('오류 발생: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final modifications = snapshot.data!;
                    if (modifications.isEmpty) {
                      return const Text('수정 이력이 없습니다.');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modifications.length,
                      itemBuilder: (context, index) {
                        final modification = modifications[index];
                        return Card(
                          child: ListTile(
                            title: Text(modification.modificationType),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('수정자: ${modification.modifiedBy}'),
                                Text('수정일시: ${FormatUtils.formatDateTime(modification.modifiedAt)}'),
                                if (modification.comment != null)
                                  Text('코멘트: ${modification.comment}'),
                                const SizedBox(height: 8),
                                ...modification.changes.entries.map((entry) {
                                  final fieldName = entry.key;
                                  final change = entry.value;
                                  return Text(
                                    '$fieldName: ${change['old']} → ${change['new']}',
                                    style: const TextStyle(fontSize: 12),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // 이미지 섹션 - 중앙 정렬 적용
            _buildSection(
              '상품 이미지',
              [
                Column(
                  children: [
                    // 대표 이미지
                    const Text('대표 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 400,  // 이미지 최대 너비 지정
                        child: AspectRatio(
                          aspectRatio: 1,  // 1:1 비율 유지
                          child: _buildImage(widget.product.productImageUrl),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 상세 이미지
                    const Text('상세 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 600,  // 상세 이미지는 더 크게 표시
                        child: _buildImage(widget.product.productDetailImage),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    // 수정 다이로그 표시
    showDialog(
      context: context,
      builder: (context) => ProductEditDialog(product: widget.product),
    );
  }

  // 이미지 위젯 빌더 메서드 추가
  Widget _buildImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: imageUrl.isNotEmpty
          ? NetworkImageWithRetry(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            )
          : Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }

  Future<void> _showDeleteConfirmDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 삭제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정말 "${widget.product.name}" 상품을 삭제하시겠습니까?'),
            const SizedBox(height: 16),
            const Text(
              '* 삭제된 상품은 복구할 수 없습니다.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 상품 이미지 삭제
        final storageService = StorageService();
        if (widget.product.productImageUrl.isNotEmpty) {
          await storageService.deleteImage(widget.product.productImageUrl);
        }
        if (widget.product.productDetailImage.isNotEmpty) {
          await storageService.deleteImage(widget.product.productDetailImage);
        }

        // 상품 데이터 삭제
        await ref.read(productServiceProvider).deleteProduct(widget.product.id);

        if (mounted) {
          Navigator.of(context).pop(true); // 상품 목록으로 돌아가기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }
} 