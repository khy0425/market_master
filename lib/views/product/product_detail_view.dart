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

                    return _buildModificationHistory(snapshot.data!);
                  },
                ),
              ],
            ),

            // 이미지 섹션
            _buildSection(
              '상품 이미지',
              [
                Column(
                  children: [
                    // 대표 이미지
                    const Text('대표 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.product.productImageUrl),
                        child: Hero(
                          tag: 'product_image_${widget.product.id}',
                          child: SizedBox(
                            width: 400,  // 대표 이미지는 적당한 크기로
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: _buildImage(widget.product.productImageUrl),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // 상세 이미지
                    const Text('상세 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showFullScreenImage(context, widget.product.productDetailImage),
                        child: Hero(
                          tag: 'product_detail_image_${widget.product.id}',
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1200),  // 최대 너비 제한
                            child: _buildDetailImage(widget.product.productDetailImage),
                          ),
                        ),
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
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('이미지 로드 에러: $error');
            return const Center(child: Icon(Icons.error));
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
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

  // 수정 이력 표시 위젯
  Widget _buildModificationHistory(List<ProductModification> modifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '수정 이력',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (modifications.isEmpty)
          const Text('수정 이력이 없습니다')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modifications.length,
            itemBuilder: (context, index) {
              final modification = modifications[index];
              return Card(
                child: ListTile(
                  title: Text(
                    '${modification.field} 변경',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('수정일시: ${_formatDate(modification.modifiedAt)}'),
                      Text('수정자: ${modification.modifiedBy}'),
                      Text('이전 값: ${modification.oldValue}'),
                      Text('변경 값: ${modification.newValue}'),
                      if (modification.comment != null)
                        Text('비고: ${modification.comment}'),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')} '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  // 전체화면 이미지 표시 메서드 추가
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black87,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Icon(Icons.error, color: Colors.white));
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 상세 이미지용 빌더 메서드 추가
  Widget _buildDetailImage(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.fitWidth,  // 너비에 맞추어 비율 유지
          errorBuilder: (context, error, stackTrace) {
            print('이미지 로드 에러: $error');
            return const Center(child: Icon(Icons.error));
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
} 