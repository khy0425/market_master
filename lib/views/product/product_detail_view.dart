import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_master/views/product/product_edit_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:developer' as developer;

import '../../models/product.dart';
import '../../views/product/product_edit_view.dart';
import '../../utils/format_utils.dart';
import '../../widgets/network_image_with_retry.dart';

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

            // 이미지 섹션
            _buildSection(
              '상품 이미지',
              [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('대표 이미지:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildImage(widget.product.productImageUrl),
                    const SizedBox(height: 16),
                    const Text('상세 이미지:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildImage(widget.product.productDetailImage),
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
} 