
// lib/models/ocr_state.dart
import 'dart:typed_data';

class OcrState {
  final Uint8List? fileBytes;
  final String? fileName;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? result;

  OcrState({
    this.fileBytes,
    this.fileName,
    this.isLoading = false,
    this.error,
    this.result,
  });

  OcrState copyWith({
    Uint8List? fileBytes,
    String? fileName,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? result,
  }) {
    return OcrState(
      fileBytes: fileBytes ?? this.fileBytes,
      fileName: fileName ?? this.fileName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }

  bool get hasFile => fileBytes != null;
  bool get hasResult => result != null;
  bool get hasError => error != null;
}