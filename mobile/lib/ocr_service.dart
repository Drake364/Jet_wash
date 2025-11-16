import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Lê texto de uma imagem e tenta extrair padrões de placa (simples regex)
  Future<String?> scanPlate(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    try {
      final result = await _textRecognizer.processImage(inputImage);
      final text = result.text;
      // Normalize text and try multiple regexes for Brazilian plates
      final cleaned = text.replaceAll('\n', ' ').replaceAll(RegExp(r'[^A-Za-z0-9\- ]'), ' ');

      final patterns = [
        RegExp(r"[A-Z]{3}[ -]?[0-9][0-9A-Z]{3}", caseSensitive: false), // Mercosul/antiga
        RegExp(r"[A-Z]{3}[ -]?[0-9]{4}", caseSensitive: false),
        RegExp(r"[A-Z]{3}[ -]?[0-9A-Z]{1,4}", caseSensitive: false),
      ];

      for (final p in patterns) {
        final m = p.firstMatch(cleaned);
        if (m != null) {
          return m.group(0)?.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
        }
      }

      // Fallback: check each line separately and prefer longest match
      String? best;
      for (final block in cleaned.split(' ')) {
        for (final p in patterns) {
          final m = p.firstMatch(block);
          if (m != null) {
            final cand = m.group(0)!.replaceAll(' ', '').replaceAll('-', '').toUpperCase();
            if (best == null || cand.length > best.length) best = cand;
          }
        }
      }
      return best;
    } catch (e) {
      print('Erro OCR: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
