import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../providers/providers.dart';
import '../../widgets/excel_upload_widget.dart';
import 'package:file_picker/file_picker.dart';

/// 상품 등록 화면
class AddProductView extends ConsumerStatefulWidget {
  const AddProductView({super.key});

  @override
  ConsumerState<AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends ConsumerState<AddProductView> {
  final _formKey = GlobalKey<FormState>();
  final _productCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _discountRateController = TextEditingController();
  final _mainCategoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _stockQuantityController = TextEditingController();
  String _productImageUrl = '';
  String _productDetailImage = '';

  @override
  void dispose() {
    _productCodeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _discountRateController.dispose();
    _mainCategoryController.dispose();
    _subCategoryController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 상품 등록'),
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: const Text('등록'),
          ),
        ],
      ),
      body: Column(
        children: [
          const Card(
            margin: EdgeInsets.all(16),
            child: ExcelUploadWidget(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _productCodeController,
                      decoration: const InputDecoration(
                        labelText: '상품 코드',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => 
                        value?.isEmpty ?? true ? '상품 코드를 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: '상품명',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => 
                        value?.isEmpty ?? true ? '상품명을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '상품 설명',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => 
                        value?.isEmpty ?? true ? '상품 설명을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _originalPriceController,
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
                            controller: _sellingPriceController,
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
                      controller: _discountRateController,
                      decoration: const InputDecoration(
                        labelText: '할인율 (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => 
                        value?.isEmpty ?? true ? '할인율을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mainCategoryController,
                            decoration: const InputDecoration(
                              labelText: '메인 카테고리',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => 
                              value?.isEmpty ?? true ? '메인 카테고리를 입력하세요' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _subCategoryController,
                            decoration: const InputDecoration(
                              labelText: '서브 카테고리',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => 
                              value?.isEmpty ?? true ? '서브 카테고리를 입력하세요' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockQuantityController,
                      decoration: const InputDecoration(
                        labelText: '재고 수량',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => 
                        value?.isEmpty ?? true ? '재고 수량을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildImageUploadSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final product = Product(
          id: '', // Firestore에서 자동 생성
          productCode: _productCodeController.text,
          name: _nameController.text,
          description: _descriptionController.text,
          originalPrice: int.parse(_originalPriceController.text),
          sellingPrice: int.parse(_sellingPriceController.text),
          discountRate: int.parse(_discountRateController.text),
          mainCategory: _mainCategoryController.text,
          subCategory: _subCategoryController.text,
          productImageUrl: _productImageUrl,
          productDetailImage: _productDetailImage,
          stockQuantity: int.parse(_stockQuantityController.text),
          createdAt: DateTime.now(),
        );

        await ref.read(productServiceProvider).addProduct(product);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 등록되었습니다')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  // 이미지 업로드 위젯
  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상품 이미지', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('대표 이미지'),
                  const SizedBox(height: 8),
                  _buildImageUploadField(
                    imageUrl: _productImageUrl,
                    onUpload: (url) => setState(() => _productImageUrl = url),
                    type: 'main',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('상세 이미지'),
                  const SizedBox(height: 8),
                  _buildImageUploadField(
                    imageUrl: _productDetailImage,
                    onUpload: (url) => setState(() => _productDetailImage = url),
                    type: 'detail',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadField({
    required String imageUrl,
    required Function(String) onUpload,
    required String type,
  }) {
    return Column(
      children: [
        if (imageUrl.isNotEmpty)
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => onUpload(''),
                  color: Colors.red,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => _pickAndUploadImage(type, onUpload),
          child: Text(imageUrl.isEmpty ? '이미지 업로드' : '이미지 변경'),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(String type, Function(String) onUpload) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('파일을 읽을 수 없습니다.');
      }

      // 이미지 크기 체크 (10MB 제한)
      if (file.size > 10 * 1024 * 1024) {
        throw Exception('이미지 크기는 10MB를 초과할 수 없습니다.');
      }

      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadImage(
        'products/$type',
        file.bytes!,
        '${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );

      if (downloadUrl != null) {
        onUpload(downloadUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e')),
        );
      }
    }
  }
} 