import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:market_master/views/product/product_list_view.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';

class ProductEditDialog extends ConsumerStatefulWidget {
  final Product product;

  const ProductEditDialog({super.key, required this.product});

  @override
  ConsumerState<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends ConsumerState<ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockQuantityController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _originalPriceController = TextEditingController(text: widget.product.originalPrice.toString());
    _sellingPriceController = TextEditingController(text: widget.product.sellingPrice.toString());
    _stockQuantityController = TextEditingController(text: widget.product.stockQuantity.toString());
    _isActive = widget.product.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('상품 정보 수정'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      validator: (value) => value?.isEmpty ?? true ? '정가를 입력하세요' : null,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockQuantityController,
                decoration: const InputDecoration(
                  labelText: '재고수량',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? '재고수량을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('판매 상태'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _updateProduct,
          child: const Text('저장'),
        ),
      ],
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final adminUser = ref.read(authStateProvider).value;
        if (adminUser == null) return;

        final updatedProduct = widget.product.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          originalPrice: int.parse(_originalPriceController.text),
          sellingPrice: int.parse(_sellingPriceController.text),
          discountRate: ((int.parse(_originalPriceController.text) - 
                         int.parse(_sellingPriceController.text)) / 
                         int.parse(_originalPriceController.text) * 100).round(),
          stockQuantity: int.parse(_stockQuantityController.text),
          isActive: _isActive,
          updatedAt: DateTime.now(),
          updatedBy: adminUser.email ?? '',
        );

        await ref.read(productServiceProvider).updateProduct(updatedProduct);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품 정보가 수정되었습니다')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
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
} 