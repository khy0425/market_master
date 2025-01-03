import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_master/views/product/product_detail_view.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:transparent_image/transparent_image.dart';
import '../../utils/format_utils.dart';
import 'package:market_master/views/product/add_product_view.dart';

// 상품 서비스 프로바이더
final productServiceProvider = Provider((ref) => ProductService());

// 검색어 상태 프로바이더 추가
final searchQueryProvider = StateProvider<String>((ref) => '');

// 필터링된 상품 목록 프로바이더
final filteredProductsProvider = StreamProvider<List<Product>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return ref.watch(productServiceProvider).getProducts();
  } else {
    return ref.watch(productServiceProvider).searchProducts(query);
  }
});

class ProductListView extends ConsumerWidget {
  const ProductListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(filteredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '새 상품 등록',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProductView(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 및 필터 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '상품명 또는 상품코드로 검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 검색 결과 카운트 표시
                productsAsyncValue.when(
                  data: (products) => Text(
                    '검색결과: ${products.length}개',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // 상품 목록 그리드
          Expanded(
            child: productsAsyncValue.when(
              data: (products) => products.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return _buildProductCard(context, product);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('오류가 발생했습니다: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상품 카드 위젯
  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(product: product),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: _buildProductImage(product.productImageUrl),
                  ),
                  if (!product.isActive)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Text(
                          '판매중지',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 상품 정보
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatUtils.formatPrice(product.sellingPrice),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.discountRate > 0)
                      Text(
                        FormatUtils.formatPrice(product.originalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    if (product.discountRate > 0)
                      Text(
                        '${product.discountRate}% 할인',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '재고: ${product.stockQuantity}개',
                      style: TextStyle(
                        color: _getStockStatusColor(product),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상품 상세 정보 다이얼로그
  void _showProductDetailDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (product.productImageUrl.isNotEmpty)
                Image.network(
                  product.productImageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              _detailRow('상품코드', product.productCode),
              _detailRow('카테고리', '${product.mainCategory} > ${product.subCategory}'),
              _detailRow('판매가', '${product.sellingPrice}원'),
              if (product.discountRate > 0)
                _detailRow('정가', '${product.originalPrice}원 (${product.discountRate}% 할인)'),
              _detailRow('재고수량', '${product.stockQuantity}개'),
              const SizedBox(height: 8),
              const Text('상품 설명:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(product.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditProductDialog(context, ref, product);
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 상품 수정 다이얼로그
  Future<void> _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) async {
    final formKey = GlobalKey<FormState>();
    final productCodeController = TextEditingController(text: product.productCode);
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final originalPriceController = TextEditingController(text: product.originalPrice.toString());
    final sellingPriceController = TextEditingController(text: product.sellingPrice.toString());
    final stockQuantityController = TextEditingController(text: product.stockQuantity.toString());
    String mainCategory = product.mainCategory;
    String subCategory = product.subCategory;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 정보 수정'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: productCodeController,
                  decoration: const InputDecoration(
                    labelText: '상품 코드',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '상품 코드를 입력하세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '상품명',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? '상품명을 입력하세요' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: '상품 설명',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: originalPriceController,
                        decoration: const InputDecoration(
                          labelText: '정가',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? '정가를 입력하세요' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: '판매가',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? '판매가를 입력하세요' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: stockQuantityController,
                  decoration: const InputDecoration(
                    labelText: '재고수량',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? '재고수량을 입력하세요' : null,
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
              if (formKey.currentState!.validate()) {
                try {
                  final updatedProduct = product.copyWith(
                    productCode: productCodeController.text,
                    name: nameController.text,
                    description: descriptionController.text,
                    originalPrice: int.parse(originalPriceController.text),
                    sellingPrice: int.parse(sellingPriceController.text),
                    stockQuantity: int.parse(stockQuantityController.text),
                    mainCategory: mainCategory,
                    subCategory: subCategory,
                    updatedAt: DateTime.now(),
                  );

                  await ref
                      .read(productServiceProvider)
                      .updateProduct(updatedProduct);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('상품 정보가 수정되었습니다')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류 발생: $e')),
                  );
                }
              }
            },
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  // 상품 삭제 확인 다이얼로그
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 삭제'),
        content: Text('정말로 "${product.name}" 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productServiceProvider).deleteProduct(product.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  // 엑셀 파일 임트 다이얼로그
  Future<void> _showExcelImportDialog(BuildContext context, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('엑셀 파일로 상품 일괄 등록'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('엑셀 파일 형식:'),
            const SizedBox(height: 8),
            const Text('''
• A열: 상품코드
• B열: 상품명
• C열: 상품설명
• D열: 정가
• E열: 판매가
• F열: 할인율
• G열: 대분류
• H열: 소분류
• I열: 상품이미지 URL
• J열: 상세이미지 URL
• K열: 재고수량
            '''),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // TODO: 파일 선택 및 업로드 구현
                // FilePickerResult? result = await FilePicker.platform.pickFiles(
                //   type: FileType.custom,
                //   allowedExtensions: ['xlsx', 'xls'],
                // );
                // if (result != null) {
                //   final bytes = result.files.first.bytes!;
                //   final results = await ref
                //       .read(productServiceProvider)
                //       .importProductsFromExcel(bytes);
                //   // 결과 처리
                // }
              },
              child: const Text('파일 선택'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // 상품 이미지 젯
  Widget _buildProductImage(String imageUrl) {
    return imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            headers: const {
              'Accept': 'image/gif,image/jpeg,image/png,*/*',
            },
            errorBuilder: (context, error, stackTrace) {
              developer.log(
                'Image loading error: $imageUrl',
                error: error,
                name: 'ProductImage',
              );
              // GIF 로딩 실패 시 일반 이미지로 재시도
              if (imageUrl.toLowerCase().endsWith('.gif')) {
                return Image.network(
                  imageUrl.replaceAll('.gif', '.jpg'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              }
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              );
            },
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
          );
  }

  // 재고 상태에 따른 색상 결정 메서드 수정
  Color _getStockStatusColor(Product product) {
    if (product.stockQuantity <= 0) {
      return Colors.red;
    } else if (product.stockQuantity < 10) {  // 임의의 기준값 사용
      return Colors.orange;
    }
    return Colors.black;
  }

  // 재고 상태 텍스트 반환 메서드 수정
  String _getStockStatusText(Product product) {
    if (product.stockQuantity <= 0) {
      return '품절';
    } else if (product.stockQuantity < 10) {  // 임의의 기준값 사용
      return '재고 부족';
    }
    return '정상';
  }
} 