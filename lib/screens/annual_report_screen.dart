import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_service.dart';
import '../services/pdf_export_service.dart';
import '../services/excel_export_service.dart';
import '../models/export_filter.dart';
import '../models/user.dart';

class AnnualReportScreen extends StatefulWidget {
  const AnnualReportScreen({super.key});

  @override
  State<AnnualReportScreen> createState() => _AnnualReportScreenState();
}

class _AnnualReportScreenState extends State<AnnualReportScreen> {
  final DataService _dataService = DataService();
  final PdfExportService _pdfService = PdfExportService();

  User? _currentUser;
  int _selectedYear = DateTime.now().year;
  bool _loading = false;
  String? _exportError;
  String? _exportSuccess;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _dataService.getCurrentUser();
    if (mounted) setState(() => _currentUser = user);
  }

  Future<void> _exportPdf() async {
    setState(() {
      _loading = true;
      _exportError = null;
      _exportSuccess = null;
    });
    try {
      final allTransactions = await _dataService.getTransactions();
      final yearTransactions = allTransactions
          .where((t) => t.date.year == _selectedYear)
          .toList();

      if (yearTransactions.isEmpty) {
        setState(() {
          _loading = false;
          _exportError = '$_selectedYear yılına ait işlem bulunamadı.';
        });
        return;
      }

      final currencySymbol = _currentUser?.currencySymbol ?? '₺';
      final start = DateTime(_selectedYear, 1, 1);
      final end = DateTime(_selectedYear, 12, 31);

      final file = await _pdfService.exportToPdf(
        transactions: yearTransactions,
        dateRange: DateRange(start: start, end: end),
        currencySymbol: currencySymbol,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Parion $_selectedYear Yıllık Raporu',
        ),
      );

      setState(() {
        _loading = false;
        _exportSuccess = 'PDF raporu oluşturuldu.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _exportError = 'Hata: $e';
      });
    }
  }

  Future<void> _exportExcel() async {
    setState(() {
      _loading = true;
      _exportError = null;
      _exportSuccess = null;
    });
    try {
      final allTransactions = await _dataService.getTransactions();
      final yearTransactions = allTransactions
          .where((t) => t.date.year == _selectedYear)
          .toList();

      if (yearTransactions.isEmpty) {
        setState(() {
          _loading = false;
          _exportError = '$_selectedYear yılına ait işlem bulunamadı.';
        });
        return;
      }

      final excelService = ExcelExportService();
      final file = await excelService.exportToExcel(
        transactions: yearTransactions,
        currencySymbol: _currentUser?.currencySymbol ?? '₺',
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: 'Parion $_selectedYear Excel Raporu',
        ),
      );

      setState(() {
        _loading = false;
        _exportSuccess = 'Excel raporu oluşturuldu.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _exportError = 'Hata: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$_selectedYear Yıllık Rapor')),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Rapor oluşturuluyor...'),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rapor Yılı', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _selectedYear > 2020
                                    ? () => setState(() => _selectedYear--)
                                    : null,
                              ),
                              Text(
                                _selectedYear.toString(),
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _selectedYear < DateTime.now().year
                                    ? () => setState(() => _selectedYear++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('İçerik', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _reportItem(Icons.trending_up, 'Yıllık Gelir/Gider Özeti'),
                          _reportItem(Icons.category, 'Kategori Bazında Dağılım'),
                          _reportItem(Icons.timeline, 'Aylık Karşılaştırma'),
                          _reportItem(Icons.credit_card, 'Kredi Kartı Harcamaları'),
                          _reportItem(Icons.account_balance, 'KMH Faiz Özeti'),
                          _reportItem(Icons.trending_down, 'En Çok Harcama Yapılan Günler'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_exportError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_exportError!, style: TextStyle(color: Colors.red.shade800)),
                    ),
                  if (_exportSuccess != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(_exportSuccess!, style: TextStyle(color: Colors.green.shade800)),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF Olarak Dışa Aktar'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_chart),
                      label: const Text('Excel Olarak Dışa Aktar'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _reportItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
