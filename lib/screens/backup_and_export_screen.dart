// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import '../services/data_service.dart';
import '../services/backup_service.dart';
import '../services/excel_export_service.dart';
import '../services/csv_export_service.dart';
import '../services/pdf_export_service.dart';
import '../models/export_filter.dart';
import '../models/user.dart';
import 'user_selection_screen.dart';

class BackupAndExportScreen extends StatefulWidget {
  const BackupAndExportScreen({super.key});

  @override
  State<BackupAndExportScreen> createState() => _BackupAndExportScreenState();
}

class _BackupAndExportScreenState extends State<BackupAndExportScreen> {
  final DataService _dataService = DataService();
  final BackupService _backupService = BackupService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _handleExport(String format) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions = await _dataService.getTransactions();
      
      late final String filePath;
      switch (format) {
        case 'excel':
          final excelService = ExcelExportService();
          final file = await excelService.exportToExcel(
            transactions: transactions,
            currencySymbol: _currentUser?.currencySymbol ?? '₺',
          );
          filePath = file.path;
          break;

        case 'csv':
          final csvService = CsvExportService();
          final file = await csvService.exportToCsv(
            transactions: transactions,
          );
          filePath = file.path;
          break;

        case 'pdf':
          final pdfService = PdfExportService();
          DateTime start = DateTime(2024);
          DateTime end = DateTime.now();
          if (transactions.isNotEmpty) {
             final dates = transactions.map((t) => t.date).toList();
             dates.sort();
             start = dates.first;
             end = dates.last;
          }
          
          final file = await pdfService.exportToPdf(
            transactions: transactions,
            dateRange: DateRange(start: start, end: end),
            currencySymbol: _currentUser?.currencySymbol ?? '₺',
          );
          filePath = file.path;
          break;
      }
      
      if (mounted) {
         Navigator.pop(context);
         
         await SharePlus.instance.share(
            ShareParams(
              files: [XFile(filePath)],
              subject: 'Parion $format Export',
            ),
         );
      }

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dışa aktarma başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await _backupService.shareBackup();

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Yedek başarıyla oluşturuldu' : 'Yedekleme başarısız',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Yükle'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut tüm veriler silinecek ve yedekten geri yüklenecek. Devam etmek istiyor musunuz?',
            ),
            SizedBox(height: 16),
            Text(
              '📱 Platform Desteği:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '✅ Android yedekleri iPhone\'a yüklenebilir',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            Text(
              '✅ iPhone yedekleri Android\'e yüklenebilir',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
            SizedBox(height: 8),
            Text(
              'Yedek dosyası (.mbk) formatında olmalıdır.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Geri Yükle',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mbk', 'zip'],
    );

    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final backupFile = File(result.files.single.path!);
      
      // Metadata kontrol et
      final metadata = await _backupService.getBackupMetadata(backupFile);
      
      if (metadata != null && mounted) {
        final platformInfo = metadata.isAndroidBackup
            ? '🤖 Android'
            : metadata.isIOSBackup
            ? '🍎 iOS'
            : '❓ Bilinmeyen';
            
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Yedek Bilgisi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Platform: $platformInfo'),
                Text('Cihaz: ${metadata.deviceModel}'),
                Text('Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(metadata.createdAt)}'),
                const SizedBox(height: 8),
                Text('İşlemler: ${metadata.transactionCount}'),
                Text('Cüzdanlar: ${metadata.walletCount}'),
                const SizedBox(height: 12),
                if (metadata.isAndroidBackup && Platform.isIOS)
                  const Text(
                    '✅ Android yedeği iPhone\'a yüklenecek',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  )
                else if (metadata.isIOSBackup && Platform.isAndroid)
                  const Text(
                    '✅ iOS yedeği Android\'e yüklenecek',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Devam Et'),
              ),
            ],
          ),
        );
        
        if (shouldContinue != true) {
          if (mounted) Navigator.pop(context);
          return;
        }
      }
      
      if (!mounted) return;
      
      // Dialog is strictly managed, ensure it's closed before navigation? 
      // Actually we are in a dialog (loading). We should NOT close it yet.
      
      await _backupService.restoreFromBackup(backupFile);

      if (mounted) {
        Navigator.pop(context); // Close loading

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veriler başarıyla geri yüklendi'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const UserSelectionScreen(),
            ),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Geri yükleme başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yedekle & Dışa Aktar'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Colors.black, // Adjust based on theme if needed, but keeping simple
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'DIŞA AKTARMA SEÇENEKLERİ',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildOptionCard(
            children: [
              _buildSettingItem(
                icon: Icons.picture_as_pdf,
                title: 'PDF olarak dışa aktar',
                subtitle: '',
                iconColor: Colors.red,
                onTap: () => _handleExport('pdf'),
              ),
              _buildSettingItem(
                icon: Icons.table_chart,
                title: 'Excel olarak dışa aktar',
                subtitle: '',
                iconColor: Colors.green,
                onTap: () => _handleExport('excel'),
              ),
              _buildSettingItem(
                icon: Icons.text_snippet,
                title: 'CSV olarak dışa aktar',
                subtitle: '',
                iconColor: Colors.blue,
                onTap: () => _handleExport('csv'),
              ),
            ]
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'YEDEKLEME VE GERİ YÜKLEME',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.5,
              ),
            ),
          ),
          _buildOptionCard(
            children: [
              _buildSettingItem(
                icon: Icons.cloud_upload_outlined,
                title: 'Yedek Oluştur',
                subtitle: 'Tüm verilerinizi içeren bir dosya oluşturun (.mbk)',
                iconColor: Colors.purple,
                onTap: _handleBackup,
              ),
              _buildSettingItem(
                icon: Icons.restore_page_outlined,
                title: 'Yedekten Geri Yükle',
                subtitle: 'Daha önceki bir yedeği geri yükleyin',
                iconColor: Colors.teal,
                onTap: _handleRestore,
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({required List<Widget> children}) {
     return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
     );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
      ) : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF8E8E93),
      ),
      onTap: onTap,
    );
  }
}
