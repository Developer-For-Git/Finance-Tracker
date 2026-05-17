import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static Future<void> exportTransactionsToCSV(List<TransactionModel> transactions) async {
    List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add([
      'ID',
      'Date',
      'Title',
      'Amount',
      'Type',
      'Category ID',
      'Wallet ID',
      'Note',
      'Tags',
    ]);

    // Add data rows
    for (var tx in transactions) {
      rows.add([
        tx.id,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.date),
        tx.title,
        tx.amount,
        tx.type,
        tx.categoryId,
        tx.walletId ?? '',
        tx.note ?? '',
        tx.tags.join(', '),
      ]);
    }
    String csvData = Csv().encode(rows);

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/transactions_export.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(path)],
      text: 'My Finance Transactions Export',
    );
  }

  static Future<void> exportTransactionsToPDF(List<TransactionModel> transactions) async {
    final pdf = pw.Document();

    final headers = ['Date', 'Title', 'Type', 'Amount', 'Category ID'];
    final data = transactions.map((tx) {
      return [
        DateFormat('MMM d, yyyy').format(tx.date),
        tx.title,
        tx.type.toUpperCase(),
        '\$${tx.amount.toStringAsFixed(2)}',
        tx.categoryId,
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Ather Wallet - Transactions Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: data,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/transactions_report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(path)],
      text: 'My Finance PDF Report',
    );
  }
}
