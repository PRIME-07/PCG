// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocr_document_extractor/ocr_page.dart';
import 'package:ocr_document_extractor/core/colors.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Document Extractor',
      theme: AppTheme.darkTheme,
      home: OcrPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

