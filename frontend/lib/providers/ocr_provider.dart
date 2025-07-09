// lib/providers/ocr_notifier.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/ocr_state.dart';
import 'package:logger/logger.dart';

class OcrNotifier extends StateNotifier<OcrState> {
  OcrNotifier() : super(OcrState());

  static const String baseUrl = 'https://cdbd23f642e6.ngrok-free.app';
  final Logger logger = Logger();

  void selectFile(Uint8List bytes, String name) {
    state = state.copyWith(
      fileBytes: bytes,
      fileName: name,
      error: null,
      result: null,
    );
  }

  Future<void> processFile() async {
    if (state.fileBytes == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/full-pipeline'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          state.fileBytes!,
          filename: state.fileName,
        ),
      );
      request.fields['page_num'] = '1';
      logger.d('Sending request to $baseUrl/full-pipeline with page_num=1');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: $responseBody');

      if (response.statusCode == 200) {
        final result = json.decode(responseBody);
        state = state.copyWith(isLoading: false, result: result);
      } else if (response.statusCode == 422) {
        logger.d('422 Error response: $responseBody');
        state = state.copyWith(
          isLoading: false,
          error: 'Validation error: $responseBody',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Processing failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      logger.d('Network error: ${e.toString()}');
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
    }
  }

  void clear() {
    state = OcrState();
  }
}

final ocrProvider = StateNotifierProvider<OcrNotifier, OcrState>(
  (ref) => OcrNotifier(),
);