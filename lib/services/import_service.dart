import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../data/models/transaction_model.dart';
import '../data/providers/finance_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ImportService {
  static Future<int> importTransactionsFromCSV(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) {
      return 0; // User canceled
    }

    File file = File(result.files.single.path!);
    final input = await file.readAsString();
    List<List<dynamic>> rows = Csv().decode(input);

    if (rows.isEmpty || rows.length == 1) return 0;

    int importedCount = 0;
    
    // Assuming the format matches our export: 
    // ID, Date, Title, Amount, Type, Category ID, Wallet ID, Note, Tags
    // We skip the first row (headers)
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 6) continue; // Minimum required columns

      try {
        final dateStr = row[1].toString();
        final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateStr);
        final title = row[2].toString();
        final amount = double.tryParse(row[3].toString()) ?? 0.0;
        final type = row[4].toString();
        final categoryId = row[5].toString();
        final walletId = row.length > 6 && row[6].toString().isNotEmpty ? row[6].toString() : null;
        final note = row.length > 7 && row[7].toString().isNotEmpty ? row[7].toString() : null;
        
        List<String> tags = [];
        if (row.length > 8 && row[8].toString().isNotEmpty) {
          tags = row[8].toString().split(',').map((e) => e.trim()).toList();
        }

        if (amount > 0 && title.isNotEmpty && categoryId.isNotEmpty) {
          await ref.read(transactionsProvider.notifier).add(
            title: title,
            amount: amount,
            type: type,
            categoryId: categoryId,
            date: date,
            note: note,
            walletId: walletId,
            tags: tags,
          );
          importedCount++;
        }
      } catch (e) {
        // Skip malformed rows
        continue;
      }
    }

    return importedCount;
  }
}
