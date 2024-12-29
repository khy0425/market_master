import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/product.dart';
import '../../services/storage_service.dart';
import '../../services/product_service.dart';
import 'dart:developer' as developer;
import '../../utils/format_utils.dart';

// 프로바이더 추가
final productServiceProvider = Provider((ref) => ProductService());

class ProductEditView extends ConsumerStatefulWidget {
  final Product product;

  const ProductEditView({super.key, required this.product});

  @override
  ConsumerState<ProductEditView> createState() => _ProductEditViewState();
}

class _ProductEditViewState extends ConsumerState<ProductEditView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockQuantityController;
  String? _mainImageUrl;
  String? _detailImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _originalPriceController = TextEditingController(text: widget.product.originalPrice.toString());
    _sellingPriceController = TextEditingController(text: widget.product.sellingPrice.toString());
    _stockQuantityController = TextEditingController(text: widget.product.stockQuantity.toString());
    _mainImageUrl = widget.product.productImageUrl;
    _detailImageUrl = widget.product.productDetailImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isMainImage) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() => _isLoading = true);

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('파일을 읽을 수 없습니다.');
      }

      final storageService = StorageService();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = isMainImage ? 'products/main' : 'products/detail';
      
      final downloadUrl = await storageService.uploadImage(
        path, 
        file.bytes!, 
        fileName,
      );
      
      if (downloadUrl != null) {
        setState(() {
          if (isMainImage) {
            _mainImageUrl = downloadUrl;
          } else {
            _detailImageUrl = downloadUrl;
          }
        });
      }
    } catch (e) {
      developer.log(
        'Error picking image',
        error: e,
        name: 'ProductEditView',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 가격 입력 시 자동으로 천 단위 구분자 적용
  String _formatPriceInput(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll(',', '')) ?? 0;
    return FormatUtils.formatNumber(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: const Text('저장'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지 섹션
                    _buildImageSection(),
                    const SizedBox(height: 24),
                    
                    // 기본 정보 섹션
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    
                    // 가격 정보 섹션
                    _buildPriceSection(),
                    const SizedBox(height: 24),
                    
                    // 재고 정보 섹션
                    _buildStockSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // 이미지 섹션 위젯
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('상품 이미지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text('메인 이미지'),
                  const SizedBox(height: 8),
                  _buildImagePicker(true, _mainImageUrl),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  const Text('상세 이미지'),
                  const SizedBox(height: 8),
                  _buildImagePicker(false, _detailImageUrl),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 이미지 피커 위젯
  Widget _buildImagePicker(bool isMainImage, String? imageUrl) {
    return InkWell(
      onTap: () => _pickImage(isMainImage),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.error_outline, color: Colors.grey),
                    );
                  },
                ),
              )
            : const Center(
                child: Icon(Icons.add_photo_alternate, color: Colors.grey),
              ),
      ),
    );
  }

  // 기본 정보 섹션 위젯
  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('기본 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '상품명',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? '상품명을 입력하세요' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: '상품 설명',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) => value?.isEmpty ?? true ? '상품 설명을 입력하세요' : null,
        ),
      ],
    );
  }

  // 가격 정보 섹션 위젯
  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('가격 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _originalPriceController,
                decoration: const InputDecoration(
                  labelText: '정가',
                  border: OutlineInputBorder(),
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final formatted = _formatPriceInput(value);
                  if (formatted != value) {
                    _originalPriceController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) return '정가를 입력하세요';
                  final number = int.tryParse(value!.replaceAll(',', ''));
                  if (number == null || number <= 0) return '올바른 가격을 입력하세요';
                  return null;
                },
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
                validator: (value) => value?.isEmpty ?? true ? '판매가를 입력하세요' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 재고 정보 섹션 위젯
  Widget _buildStockSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('재고 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _stockQuantityController,
          decoration: const InputDecoration(
            labelText: '재고 수량',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (value) => value?.isEmpty ?? true ? '재고 수량을 입력하세요' : null,
        ),
      ],
    );
  }

  // 변경사항 저장
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        originalPrice: int.parse(_originalPriceController.text),
        sellingPrice: int.parse(_sellingPriceController.text),
        stockQuantity: int.parse(_stockQuantityController.text),
        productImageUrl: _mainImageUrl ?? widget.product.productImageUrl,
        productDetailImage: _detailImageUrl ?? widget.product.productDetailImage,
        updatedAt: DateTime.now(),
      );

      await ref.read(productServiceProvider).updateProduct(
        widget.product.id,
        updatedProduct.toMap(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상품이 수정되었습니다')),
        );
      }
    } catch (e) {
      developer.log(
        'Error saving product',
        error: e,
        name: 'ProductEditView',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
} 