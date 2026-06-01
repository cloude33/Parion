import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final String rawText;
  final double? amount;
  final DateTime? date;
  final String? merchant;
  final String? taxNumber;

  OcrResult({
    required this.rawText,
    this.amount,
    this.date,
    this.merchant,
    this.taxNumber,
  });
}

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer();

  Future<OcrResult> processImageBytes(Uint8List bytes) async {
    try {
      final inputImage = await _bytesToInputImage(bytes);
      final recognizedText = await _recognizer.processImage(inputImage);

      final text = recognizedText.text;
      debugPrint('OcrService: Raw text: $text');

      final amount = _extractAmount(text);
      final date = _extractDate(text);
      final merchant = _extractMerchant(text);
      final taxNumber = _extractTaxNumber(text);

      return OcrResult(
        rawText: text,
        amount: amount,
        date: date,
        merchant: merchant,
        taxNumber: taxNumber,
      );
    } on FormatException catch (_) {
      debugPrint('OcrService: Image format not supported');
      return OcrResult(rawText: '');
    } catch (e) {
      debugPrint('OcrService: Error processing image: $e');
      return OcrResult(rawText: '');
    }
  }

  /// Kept for backward compatibility
  Future<OcrResult> processImage(File imageFile) async {
    try {
      final inputImage = await _bytesInputImage(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);

      final text = recognizedText.text;
      debugPrint('OcrService: Raw text: $text');

      final amount = _extractAmount(text);
      final date = _extractDate(text);
      final merchant = _extractMerchant(text);
      final taxNumber = _extractTaxNumber(text);

      return OcrResult(
        rawText: text,
        amount: amount,
        date: date,
        merchant: merchant,
        taxNumber: taxNumber,
      );
    } on FormatException catch (_) {
      debugPrint('OcrService: Image format not supported');
      return OcrResult(rawText: '');
    } catch (e) {
      debugPrint('OcrService: Error processing image: $e');
      return OcrResult(rawText: '');
    }
  }

  Future<InputImage> _bytesToInputImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1920);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    codec.dispose();

    if (byteData == null) {
      throw FormatException('Failed to decode image bytes');
    }

    return InputImage.fromBitmap(
      bitmap: byteData.buffer.asUint8List(),
      width: image.width,
      height: image.height,
    );
  }

  Future<InputImage> _bytesInputImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return await _bytesToInputImage(bytes);
    } catch (e) {
      debugPrint('OcrService: Bitmap input failed, falling back: $e');
    }
    return InputImage.fromFilePath(file.path);
  }

  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:TOPLAM|GENEL\s*TOPLAM|ÖDENECEK\s*TUTAR|TUTAR|BANKAYA\s*ÖDENECEK)\s*[:：]?\s*(?:₺|TL|TRY)?\s*([0-9]+[.,]?[0-9]*)', caseSensitive: false, multiLine: true),
      RegExp(r'([0-9]+[.,][0-9]{2})\s*(?:₺|TL|TRY)?', multiLine: true),
      RegExp(r'(?:₺|TL|TRY)\s*([0-9]+[.,]?[0-9]*)', multiLine: true),
    ];

    final candidates = <double>[];
    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final value = match.group(1);
        if (value != null) {
          final cleaned = value.replaceAll('.', '').replaceFirst(',', '.');
          final amount = double.tryParse(cleaned);
          if (amount != null && amount > 0) {
            candidates.add(amount);
          }
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.compareTo(a));
    return candidates.first;
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{2})[./](\d{2})[./](\d{4})'),
      RegExp(r'(\d{4})[./](\d{2})[./](\d{2})'),
      RegExp(r'(\d{2})[./](\d{2})[./](\d{2})(?=\D)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.groupCount == 3) {
            final g1 = int.parse(match.group(1)!);
            final g2 = int.parse(match.group(2)!);
            final g3 = int.parse(match.group(3)!);

            if (g1 > 31) {
              return DateTime(g1, g2, g3);
            } else if (g3 > 31) {
              return DateTime(g3, g2, g1);
            } else {
              final now = DateTime.now();
              final year = g3 > 100 ? g3 : (2000 + g3);
              if (year <= now.year && year >= 2000) {
                return DateTime(year, g2, g1);
              }
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  String? _extractMerchant(String text) {
    final patterns = [
      RegExp(r'(?:FATURA\s*NO|FATURA\s*TARİHİ|İRSALİYE\s*NO)\s*[:：]?\s*\S+\s*\n\s*(.+)', caseSensitive: false),
      RegExp(r'^(.+)\s*(?:VERGİ\s*DAİRESİ|FATURA|İRSALİYE)', caseSensitive: false, multiLine: true),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 2 && name.length < 100) {
          return name;
        }
      }
    }

    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.length > 3 && l.length < 80).toList();
    if (lines.length >= 2) {
      return lines[0];
    }

    return null;
  }

  String? _extractTaxNumber(String text) {
    final pattern = RegExp(r'(?:VERGİ\s*NO|VNO|TC\s*KİMLİK)\s*[:：]?\s*(\d{10,11})', caseSensitive: false);
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  void dispose() {
    _recognizer.close();
  }
}
