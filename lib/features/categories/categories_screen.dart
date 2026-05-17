import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import '../../data/models/category_model.dart';
import '../../core/utils/icon_helper.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet({CategoryModel? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(editing: editing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final expenseCats = categories.where((c) => c.type == 'expense' || c.type == 'both').toList();
    final incomeCats = categories.where((c) => c.type == 'income' || c.type == 'both').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_fab',
        onPressed: () => _showAddCategorySheet(),
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            floating: true,
            toolbarHeight: 70,
            title: Text('Categories', style: Theme.of(context).textTheme.headlineLarge),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: AppColors.tealGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(3),
                      labelColor: AppColors.bgDeep,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle:
                          const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                            text:
                                'Expense (${expenseCats.length})'),
                        Tab(
                            text:
                                'Income (${incomeCats.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoryGrid(expenseCats),
                _buildCategoryGrid(incomeCats),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(List<CategoryModel> cats) {
    if (cats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, color: AppColors.textMuted, size: 56),
            SizedBox(height: 16),
            Text('No categories yet',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cats.length,
      itemBuilder: (context, i) {
        final cat = cats[i];
        final color =
            AppColors.categoryColors[cat.colorIndex % AppColors.categoryColors.length];
        return GestureDetector(
          onTap: () => _showAddCategorySheet(editing: cat),
          onLongPress: cat.isDefault
              ? null
              : () => _confirmDelete(context, cat),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    IconHelper.getIcon(cat.icon),
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!cat.isDefault)
                  const SizedBox(height: 2),
                if (!cat.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Custom',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CategoryModel cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete "${cat.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(categoriesProvider.notifier).delete(cat.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.expense)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Category Form Sheet
// ──────────────────────────────────────────────────────────

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final CategoryModel? editing;
  const _CategoryFormSheet({this.editing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  String _type = 'expense';
  int _selectedColorIndex = 0;
  String _selectedIcon = '0xe8b8';

  final List<String> _icons = [
    '0xe56c', '0xe531', '0xe59c', '0xe40e', '0xe3f3', '0xe318',
    '0xe5c0', '0xe80c', '0xe227', '0xe8f9', '0xe8dc', '0xe8b8',
    '0xe332', '0xe1bc', '0xe55f', '0xe7f4', '0xe7f5', '0xe30d',
    '0xe544', '0xe86c', '0xe7ee', '0xe149', '0xe84f', '0xe26e',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameController.text = widget.editing!.name;
      _type = widget.editing!.type;
      _selectedColorIndex = widget.editing!.colorIndex;
      _selectedIcon = widget.editing!.icon;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    const uuid = Uuid();

    final cat = CategoryModel(
      id: widget.editing?.id ?? uuid.v4(),
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      colorIndex: _selectedColorIndex,
      type: _type,
      isDefault: false,
    );

    if (widget.editing != null) {
      await ref.read(categoriesProvider.notifier).update(cat);
    } else {
      await ref.read(categoriesProvider.notifier).add(cat);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.editing != null ? 'Edit Category' : 'New Category',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.label_rounded, size: 20)),
            ),
            const SizedBox(height: 16),
            // Type
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: ['expense', 'income', 'both'].map((t) {
                final isSelected = _type == t;
                final color = t == 'expense'
                    ? AppColors.expense
                    : t == 'income'
                        ? AppColors.income
                        : AppColors.tealPrimary;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            // Color
            Text('Color', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(AppColors.categoryColors.length, (i) {
                final isSelected = _selectedColorIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.categoryColors[i],
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppColors.categoryColors[i]
                                      .withOpacity(0.5),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Icon
            Text('Icon', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _icons.map((iconCode) {
                final isSelected = _selectedIcon == iconCode;
                final color =
                    AppColors.categoryColors[_selectedColorIndex];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconCode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.2)
                          : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              isSelected ? color : AppColors.border),
                    ),
                    child: Icon(
                      IconHelper.getIcon(iconCode),
                      color: isSelected ? color : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(widget.editing != null ? 'Update Category' : 'Create Category'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
