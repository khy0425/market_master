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
import 'package:market_master/views/product/category_management_view.dart';
import 'package:market_master/services/category_service.dart';
import '../../models/category.dart';

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

// 선택된 카테고리 상태 프로바이더 추가
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class ProductListView extends ConsumerStatefulWidget {
  final String? initialProductId;  // 초기 선택될 상품 ID

  const ProductListView({
    super.key,
    this.initialProductId,
  });

  @override
  ConsumerState<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends ConsumerState<ProductListView> {
  // 상수로 분리
  static const double _gridPadding = 16.0;
  static const int _gridCrossAxisCount = 4;
  static const double _gridChildAspectRatio = 0.7;
  static const double _gridSpacing = 16.0;

  // 캐시 키 생성 함수 추가
  String _getCacheKey(Product product) => 
    '${product.id}_${product.updatedAt?.millisecondsSinceEpoch}';

  final _scrollController = ScrollController();
  String? _highlightedProductId;

  @override
  void initState() {
    super.initState();
    // 초기 상품 ID가 있으면 해당 상품으로 스크롤
    if (widget.initialProductId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToProduct(widget.initialProductId!);
      });
    }
  }

  // 특정 상품으로 스크롤하고 하이라이트 표시
  void _scrollToProduct(String productId) {
    // 상품 목록에서 해당 상품 찾기
    final products = ref.read(productServiceProvider).getProducts();
    products.listen((productList) {
      final index = productList.indexWhere((p) => p.id == productId);
      if (index != -1) {
        // 해당 상품으로 스크롤
        _scrollController.animateTo(
          index * 100.0,  // 예상 아이템 높이
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        
        // 해당 상품 하이라이트 (옵션)
        setState(() {
          _highlightedProductId = productId;
        });
        
        // 3초 후 하이라이트 제거
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _highlightedProductId = null;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: Column(
        children: [
          // 검색 영역
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
                ref.watch(filteredProductsProvider).when(
                  data: (products) => Text(
                    '검색결과: ${products.length}개',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // 카테고리 필터 영역 추가
          Container(
            alignment: Alignment.centerLeft,  // 좌측 정렬
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: StreamBuilder<List<Category>>(
              stream: ref.watch(categoryServiceProvider).getCategories(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final categories = snapshot.data!;
                final selectedCategory = ref.watch(selectedCategoryProvider);

                // 메인 카테고리와 서브 카테고리 분리
                final mainCategories = categories
                    .where((c) => c.parentId == null)
                    .whereType<Category>()
                    .toList();
                final subCategories = categories
                    .where((c) => c.parentId != null)
                    .whereType<Category>()
                    .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 전체 카테고리 칩
                      FilterChip(
                        label: const Text('전체'),
                        selected: selectedCategory == null,
                        onSelected: (selected) {
                          if (selected) {
                            ref.read(selectedCategoryProvider.notifier).state = null;
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      
                      // 메인 카테고리 칩들
                      ...mainCategories.map((category) {
                        if (category.name == null) return const SizedBox.shrink();

                        final isMainSelected = selectedCategory == category.name;
                        final relatedSubs = subCategories
                            .where((sub) => sub.parentId == category.id)
                            .where((sub) => sub.name != null)
                            .toList();

                        return Row(
                          children: [
                            FilterChip(
                              label: Text(category.name!),
                              selected: isMainSelected,
                              onSelected: (selected) {
                                ref.read(selectedCategoryProvider.notifier).state = 
                                  selected ? category.name : null;
                              },
                            ),
                            if (relatedSubs.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              ...relatedSubs.map((sub) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(sub.name!),
                                  selected: selectedCategory == sub.name,
                                  onSelected: (selected) {
                                    ref.read(selectedCategoryProvider.notifier).state = 
                                      selected ? sub.name : null;
                                  },
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              )),
                              const SizedBox(width: 8),
                            ],
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // 상품 목록 (필터링 적용)
          Expanded(
            child: ref.watch(filteredProductsProvider).when(
              data: (products) {
                final selectedCategory = ref.watch(selectedCategoryProvider);
                final filteredProducts = selectedCategory == null 
                  ? products
                  : products.where((p) => 
                      p.mainCategory == selectedCategory || 
                      p.subCategory == selectedCategory).toList();

                return filteredProducts.isEmpty
                    ? const Center(child: Text('검색 결과가 없습니다'))
                    : GridView.builder(
                        padding: EdgeInsets.all(_gridPadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridCrossAxisCount,
                          childAspectRatio: _gridChildAspectRatio,
                          crossAxisSpacing: _gridSpacing,
                          mainAxisSpacing: _gridSpacing,
                        ),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: true,
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return KeyedSubtree(
                            key: ValueKey(_getCacheKey(product)),
                            child: _buildProductCard(context, product),
                          );
                        },
                      );
              },
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
      elevation: 0,  // 그림자 제거
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),  // 테두리 추가
      ),
      child: InkWell(
        onTap: () => _navigateToDetail(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  child: Image.network(
                    product.productImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.error));
                    },
                  ),
                ),
              ),
            ),
            
            // 상품 정보 영역
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품명
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // 가격 정보
                  Row(
                    children: [
                      if (product.discountRate > 0) ...[
                        Text(
                          '${product.discountRate}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        FormatUtils.formatPrice(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (product.discountRate > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      FormatUtils.formatPrice(product.originalPrice),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  
                  // 재고 및 상태 정보
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '재고: ${product.stockQuantity}개',
                        style: TextStyle(
                          fontSize: 13,
                          color: _getStockStatusColor(product),
                        ),
                      ),
                      if (!product.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '판매중지',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
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
  Widget _buildProductImage(String? imageUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
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
            )
          : const Center(child: Icon(Icons.image_not_supported)),
    );
  }

  // 상품 상세 이미지 목록 표시
  Widget _buildDetailImages(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상세 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (images.isEmpty)
          const Text('등록된 상세 이미지가 없습니다')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.map((url) => _buildDetailImage(url)).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailImage(String url) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('상세 이미지 로드 에러: $error');
            return const Center(child: Icon(Icons.error));
          },
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

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('상품 관리'),
      actions: [
        IconButton(
          icon: const Icon(Icons.category),
          tooltip: '카테고리 관리',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CategoryManagementView(),
              ),
            );
          },
        ),
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
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 상품 상세 페이지로 이동
  void _navigateToDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailView(product: product),
      ),
    ).then((deleted) {
      // 상품이 삭제되었다면 스낵바 표시
      if (deleted == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품이 삭제되었습니다')),
        );
      }
    });
  }
} 