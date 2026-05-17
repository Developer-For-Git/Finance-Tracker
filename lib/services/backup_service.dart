import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static Future<void> createLocalBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      
      // Look for .hive files
      final hiveFiles = appDir.listSync().where((entity) {
        return entity is File && entity.path.endsWith('.hive');
      }).cast<File>().toList();

      if (hiveFiles.isEmpty) return;

      // For simplicity, we can create a temporary directory and copy the files,
      // or we can just share the transactions.hive file directly for now.
      final backupDir = await getTemporaryDirectory();
      final backupDate = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFolder = Directory('${backupDir.path}/Backup_$backupDate');
      await backupFolder.create();

      List<XFile> filesToShare = [];

      for (var file in hiveFiles) {
        final fileName = file.uri.pathSegments.last;
        final copyPath = '${backupFolder.path}/$fileName';
        await file.copy(copyPath);
        filesToShare.add(XFile(copyPath));
      }

      await Share.shareXFiles(
        filesToShare,
        text: 'My Finance Tracker Local Backup',
      );
      
    } catch (e) {
      debugPrint('Backup failed: $e');
    }
  }
}
