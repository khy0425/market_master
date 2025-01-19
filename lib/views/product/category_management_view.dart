import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

final categoryServiceProvider = Provider((ref) => CategoryService());

class CategoryManagementView extends ConsumerStatefulWidget {
  const CategoryManagementView({super.key});

  @override
  ConsumerState<CategoryManagementView> createState() => _CategoryManagementViewState();
}

class _CategoryManagementViewState extends ConsumerState<CategoryManagementView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedParentId;

  @override
  Widget build(BuildContext context) {
    final categoriesStream = ref.watch(categoryServiceProvider).getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('새 카테고리'),
      ),
      body: StreamBuilder<List<Category>>(
        stream: categoriesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data!;
          final mainCategories = categories.where((c) => c.parentId == null).toList();

          return Column(
            children: [
              // 카테고리 통계
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                child: Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.category,
                      title: '메인 카테고리',
                      value: mainCategories.length.toString(),
                    ),
                    _buildStatCard(
                      icon: Icons.subdirectory_arrow_right,
                      title: '서브 카테고리',
                      value: (categories.length - mainCategories.length).toString(),
                    ),
                    _buildStatCard(
                      icon: Icons.all_inbox,
                      title: '전체 카테고리',
                      value: categories.length.toString(),
                    ),
                  ],
                ),
              ),
              
              // 카테고리 목록
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: mainCategories.length,
                  itemBuilder: (context, index) {
                    final category = mainCategories[index];
                    final subCategories = categories
                        .where((c) => c.parentId == category.id)
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          title: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          leading: const Icon(Icons.category),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${subCategories.length}개',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(Icons.add),
                                      title: Text('서브카테고리 추가'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () {
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () => _showCategoryDialog(context, parentCategory: category),
                                      );
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(Icons.edit),
                                      title: Text('수정'),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () {
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () => _showCategoryDialog(context, category: category),
                                      );
                                    },
                                  ),
                                  PopupMenuItem(
                                    child: const ListTile(
                                      leading: Icon(Icons.delete, color: Colors.red),
                                      title: Text('삭제', style: TextStyle(color: Colors.red)),
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onTap: () {
                                      Future.delayed(
                                        const Duration(milliseconds: 200),
                                        () => _deleteCategory(category),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          children: [
                            if (subCategories.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('서브카테고리가 없습니다'),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subCategories.length,
                                itemBuilder: (context, index) {
                                  final subCategory = subCategories[index];
                                  return ListTile(
                                    leading: const Icon(Icons.subdirectory_arrow_right),
                                    title: Text(subCategory.name),
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          child: const ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('수정'),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                              const Duration(milliseconds: 200),
                                              () => _showCategoryDialog(context, category: subCategory),
                                            );
                                          },
                                        ),
                                        PopupMenuItem(
                                          child: const ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('삭제', style: TextStyle(color: Colors.red)),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onTap: () {
                                            Future.delayed(
                                              const Duration(milliseconds: 200),
                                              () => _deleteCategory(subCategory),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('서브카테고리 추가'),
                                onPressed: () => _showCategoryDialog(
                                  context,
                                  parentCategory: category,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context, {
    Category? category,
    Category? parentCategory,
  }) {
    final isEditing = category != null;
    _nameController.text = isEditing ? category.name : '';
    _selectedParentId = isEditing ? category.parentId : parentCategory?.id;

    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEditing 
                      ? '카테고리 수정' 
                      : parentCategory != null 
                        ? '서브카테고리 추가' 
                        : '메인 카테고리 추가',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 카테고리 정보 입력 폼
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카테고리명 입력
                    const Text(
                      '카테고리명',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '카테고리명을 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        prefixIcon: const Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '카테고리명을 입력하세요';
                        }
                        return null;
                      },
                      autofocus: true,
                    ),

                    // 상위 카테고리 선택 (새 메인 카테고리 추가시에만 표시)
                    if (!isEditing && parentCategory == null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        '상위 카테고리',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Category>>(
                        stream: ref.read(categoryServiceProvider).getMainCategories(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const LinearProgressIndicator();
                          }

                          final mainCategories = snapshot.data!;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonFormField<String?>(
                              value: _selectedParentId,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                prefixIcon: Icon(Icons.folder_open),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('없음 (최상위)'),
                                ),
                                ...mainCategories.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                )),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedParentId = value);
                              },
                            ),
                          );
                        },
                      ),
                    ],

                    // 부가 정보 표시
                    if (parentCategory != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '상위 카테고리: ${parentCategory.name}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 액션 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (isEditing) {
                          await ref.read(categoryServiceProvider).updateCategory(
                            category.id,
                            {
                              'name': _nameController.text,
                              'parentId': _selectedParentId,
                            },
                          );
                        } else {
                          final newCategory = Category(
                            id: '',
                            name: _nameController.text,
                            parentId: _selectedParentId ?? parentCategory?.id,
                            order: 999999,
                            createdAt: DateTime.now(),
                          );
                          await ref.read(categoryServiceProvider).addCategory(newCategory);
                        }
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isEditing ? Icons.save : Icons.add),
                        const SizedBox(width: 8),
                        Text(isEditing ? '수정' : '추가'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('${category.name} 카테고리를 삭제하시겠습니까?\n하위 카테고리도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(categoryServiceProvider).deleteCategory(category.id);
    }
  }

  Future<void> _reorderCategories(List<Category> categories, int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final categoryIds = categories.map((c) => c.id).toList();
    final item = categoryIds.removeAt(oldIndex);
    categoryIds.insert(newIndex, item);
    
    await ref.read(categoryServiceProvider).reorderCategories(categoryIds);
  }
} 