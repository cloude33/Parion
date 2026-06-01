import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/data_service.dart';
import 'add_transaction_screen.dart';

class OcrScanScreen extends StatefulWidget {
  const OcrScanScreen({super.key});

  @override
  State<OcrScanScreen> createState() => _OcrScanScreenState();
}

class _OcrScanScreenState extends State<OcrScanScreen> {
  final OcrService _ocrService = OcrService();
  final ImagePicker _picker = ImagePicker();
  final DataService _dataService = DataService();

  Uint8List? _imageBytes;
  String? _imagePath;
  OcrResult? _result;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, maxWidth: 1920);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _imagePath = picked.path;
        _processing = true;
        _error = null;
        _result = null;
      });

      final result = await _ocrService.processImageBytes(bytes);
      if (mounted) {
        setState(() {
          _result = result;
          _processing = false;
          if (result.rawText.isEmpty) {
            _error = 'Metin okunamadı. Fatura görüntüsünü tekrar deneyin.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = 'Görüntü işlenemedi. Lütfen farklı bir fotoğraf deneyin.';
        });
      }
    }
  }

  Future<void> _saveAsTransaction() async {
    if (_result == null) return;
    final amount = _result!.amount;
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutar okunamadı, lütfen manuel girin.')),
      );
      return;
    }

    final wallets = await _dataService.getWallets();
    final categories = await _dataService.getCategories();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          wallets: wallets,
          categories: categories,
          defaultType: 'expense',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Fatura / Makbuz Oku')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_imageBytes!, height: 250, fit: BoxFit.cover, width: double.infinity),
              ),
              const SizedBox(height: 16),
            ],
            if (_processing) ...[
              const Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 8), Text('Görüntü işleniyor...')])),
            ],
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(children: [Icon(Icons.warning, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(_error!))]),
              ),
              const SizedBox(height: 16),
            ],
            if (_result != null && _result!.rawText.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Okunan Bilgiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _resultField('Tutar', _result!.amount != null ? '₺${_result!.amount!.toStringAsFixed(2)}' : 'Tespit edilemedi'),
                      _resultField('Tarih', _result!.date != null ? dateFormat.format(_result!.date!) : 'Tespit edilemedi'),
                      _resultField('Firma', _result!.merchant ?? 'Tespit edilemedi'),
                      if (_result!.taxNumber != null) _resultField('Vergi No', _result!.taxNumber!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ham Metin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_result!.rawText, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _result?.amount != null ? _saveAsTransaction : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Harcama Olarak Kaydet'),
                ),
              ),
            ],
            if (_imageBytes == null && !_processing) ...[
              const SizedBox(height: 40),
              Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Fatura veya makbuz fotoğrafı çekin', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              Text('Tutar, tarih ve firma adı otomatik okunur', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Fotoğraf Çek'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeriden Seç'),
                ),
              ),
            ],
            if (_imageBytes != null && !_processing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tekrar Çek'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: value == 'Tespit edilemedi' ? Colors.orange : null)),
        ],
      ),
    );
  }
}
