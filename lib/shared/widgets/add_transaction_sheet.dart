import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/finance_providers.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../features/history/audit_log_screen.dart';

import '../../data/models/transaction_model.dart';
import '../../data/models/split_model.dart';
import 'split_transaction_sheet.dart';
class AddTransactionSheet extends ConsumerStatefulWidget {
  final String? initialType;
  final TransactionModel? transactionToEdit;

  const AddTransactionSheet({
    super.key,
    this.initialType,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _tagsController = TextEditingController();

  String _type = 'expense';
  List<String> _tags = [];
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _receiptPath;
  List<SplitModel> _splits = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      final tx = widget.transactionToEdit!;
      _type = tx.type;
      _selectedCategoryId = tx.categoryId;
      _selectedDate = tx.date;
      _titleController.text = tx.title;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note ?? '';
      _tags = List.from(tx.tags);
      _splits = tx.splits != null ? List.from(tx.splits!) : [];
      _receiptPath = tx.receiptPath;
    } else {
      _type = widget.initialType ?? 'expense';
    }

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _type == 'income' ? 1 : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _type = _tabController.index == 0 ? 'expense' : 'income';
          _selectedCategoryId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.tealPrimary,
            surface: AppColors.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptPath = pickedFile.path;
      });
      _processReceiptText(pickedFile.path);
    }
  }

  Future<void> _processReceiptText(String path) async {
    setState(() => _isLoading = true);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      // Simple logic to find the largest double as amount
      double? maxAmount;
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text;
          // Look for numbers like 12.34 or $12.34
          final match = RegExp(r'\$?\s*(\d+\.\d{2})').firstMatch(text);
          if (match != null) {
            final amt = double.tryParse(match.group(1)!);
            if (amt != null) {
              if (maxAmount == null || amt > maxAmount) {
                maxAmount = amt;
              }
            }
          }
        }
      }
      
      if (maxAmount != null && _amountController.text.isEmpty) {
        setState(() {
          _amountController.text = maxAmount!.toStringAsFixed(2);
        });
      }
      textRecognizer.close();
    } catch (e) {
      debugPrint('OCR Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null && _splits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category or split the transaction'),
          margin: EdgeInsets.fromLTRB(20, 0, 20, 110),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    if (widget.transactionToEdit != null) {
      final updatedTx = widget.transactionToEdit!.copyWith(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        categoryId: _splits.isNotEmpty ? _splits.first.categoryId : _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        tags: _tags,
        receiptPath: _receiptPath,
        splits: _splits.isNotEmpty ? _splits : null,
      );
      await ref.read(transactionsProvider.notifier).update(updatedTx);
    } else {
      await ref.read(transactionsProvider.notifier).add(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        categoryId: _splits.isNotEmpty ? _splits.first.categoryId : _selectedCategoryId!,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        tags: _tags,
        receiptPath: _receiptPath,
        splits: _splits.isNotEmpty ? _splits : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final filteredCats = categories.where((c) => c.type == _type || c.type == 'both').toList();
    final isExpense = _type == 'expense';
    final accentColor = isExpense ? AppColors.expense : AppColors.income;
    final currencySymbol = ref.watch(settingsProvider)['currencySymbol'] as String;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (widget.transactionToEdit != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuditLogScreen(transactionId: widget.transactionToEdit!.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.all(3),
                labelColor: AppColors.bgDeep,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field (big)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            currencySymbol,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                filled: false,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Enter amount';
                                if (double.tryParse(v) == null) return 'Invalid amount';
                                if (double.parse(v) <= 0) return 'Must be > 0';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.edit_rounded, size: 20),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
                    ),
                    const SizedBox(height: 16),
                    // Date
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                color: AppColors.textSecondary, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.textMuted, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Categories
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredCats.map((cat) {
                        final isSelected = _selectedCategoryId == cat.id;
                        final catColor = AppColors.categoryColors[
                            cat.colorIndex % AppColors.categoryColors.length];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = cat.id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? catColor.withOpacity(0.2) : AppColors.bgSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? catColor : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconData(int.tryParse(cat.icon) ?? 0xe8b8,
                                      fontFamily: 'MaterialIcons'),
                                  size: 16,
                                  color: isSelected ? catColor : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: isSelected ? catColor : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Note
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.note_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Splits
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Splits', style: Theme.of(context).textTheme.titleMedium),
                        TextButton.icon(
                          onPressed: () async {
                            final double? totalAmt = double.tryParse(_amountController.text);
                            final result = await showModalBottomSheet<List<SplitModel>>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => SplitTransactionSheet(
                                totalAmount: totalAmt,
                                initialSplits: _splits,
                                transactionType: _type,
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _splits = result;
                              });
                            }
                          },
                          icon: const Icon(Icons.call_split, color: AppColors.tealPrimary, size: 20),
                          label: Text(
                            _splits.isEmpty ? 'Split Transaction' : '${_splits.length} Splits',
                            style: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (_splits.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.tealPrimary.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: _splits.map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Split: \$${s.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary)),
                                if (s.note != null && s.note!.isNotEmpty)
                                  Text(s.note!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Tags
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._tags.map((tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.bgCard,
                              side: const BorderSide(color: AppColors.border),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _tags.remove(tag);
                                });
                              },
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Add a tag',
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () {
                            if (_tagsController.text.trim().isNotEmpty) {
                              setState(() {
                                _tags.add(_tagsController.text.trim());
                                _tagsController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      onFieldSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          setState(() {
                            _tags.add(v.trim());
                            _tagsController.clear();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Receipt Attachment
                    Text(
                      'Receipt',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickReceipt,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _receiptPath != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.file(
                                      File(_receiptPath!),
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => _receiptPath = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate_rounded, color: AppColors.textSecondary, size: 32),
                                  SizedBox(height: 8),
                                  Text('Attach a receipt', style: TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bgDeep),
                              )
                            : Text(
                                widget.transactionToEdit != null
                                    ? 'Save Changes'
                                    : (isExpense ? 'Add Expense' : 'Add Income'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
