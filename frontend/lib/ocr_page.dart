/// lib/pages/ocr_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ocr_document_extractor/core/file_upload.dart';
import 'package:ocr_document_extractor/pipeline.dart';
import 'package:ocr_document_extractor/providers/ocr_repo.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:typed_data';
// Conditional imports for web
import 'dart:html' as html if (dart.library.io) 'dart:io';

import 'package:ocr_document_extractor/react_flow_pipeline.dart';

class OcrPage extends ConsumerWidget {
  const OcrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ocrProvider);
    final notifier = ref.read(ocrProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_fix_high_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'OCR Document Extractor',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B0B0F),
        elevation: 0,
        actions: [
          if (state.hasFile)
            AnimatedSlide(
              offset: state.hasFile ? Offset.zero : const Offset(1, 0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2A2A35)),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF6366F1), size: 18),
                  ),
                  onPressed: notifier.clear,
                  tooltip: 'Clear',
                ),
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 0.1), end: Offset.zero).chain(
                  CurveTween(curve: Curves.easeOutCubic),
                ),
              ),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          key: ValueKey(state.hasFile),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // In your OCR page, replace PipelineCard with:
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                child: EnhancedPipelineCard(state: state),
              ),

              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                child: PipelineCard(state: state),
              ),
              const SizedBox(height: 32),

              // File upload
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: FileUploadCard(
                  hasFile: state.hasFile,
                  fileName: state.fileName,
                  onPickFile: () => _pickFile(ref),
                  onImageCaptured: (bytes, fileName) =>
                      _handleImageCaptured(ref, bytes, fileName),
                  // Wire up the new onFileDropped callback to the notifier
                  onFileDropped: (bytes, fileName) {
                    ref.read(ocrProvider.notifier)
                       .selectFile(Uint8List.fromList(bytes), fileName);
                  },
                ),
              ),

              // Process button
              AnimatedSize(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                child: state.hasFile && !state.isLoading
                    ? Container(
                        margin: const EdgeInsets.only(top: 40),
                        width: double.infinity,
                        child: AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: notifier.processFile,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Animated icon
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(milliseconds: 800),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: 0.8 + (0.2 * value),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.rocket_launch_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      // Button text
                                      const Text(
                                        'Process Document',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Arrow icon
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Loading indicator
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                child: state.isLoading
                    ? Container(
                        margin: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F28),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF2A2A35)),
                              ),
                              child: const Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  Icon(
                                    Icons.psychology_rounded,
                                    color: Color(0xFF6366F1),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Processing document...',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This may take a few moments',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Error display
              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                child: state.hasError
                    ? Container(
                        margin: const EdgeInsets.only(top: 32),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F1F28),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Processing Error',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.error!,
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Results
              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                child: state.hasResult
                    ? Container(
                        margin: const EdgeInsets.only(top: 32),
                        child: ResultCard(result: state.result!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        ref.read(ocrProvider.notifier).selectFile(
              result.files.single.bytes!,
              result.files.single.name,
            );
      }
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Error: ${e.toString()}'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _handleImageCaptured(WidgetRef ref, List<int> bytes, String fileName) {
    try {
      ref
          .read(ocrProvider.notifier)
          .selectFile(Uint8List.fromList(bytes), fileName);

      // Show success message
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Photo captured successfully!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Error processing photo: ${e.toString()}'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// Result Card Widget
// Result Card Widget
class ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final entities =
        result['parsed_json']?['entities'] as Map<String, dynamic>?;
    final tables = result['parsed_json']?['tables'] as List?;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF2A2A35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF252530),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Extraction Results',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Document processed successfully',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (kIsWeb) _buildExportButton(),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // OCR Text Section (First)
                if (result['ocr_text'] != null) ...[
                  _buildOcrTextSection(result['ocr_text']),
                  SizedBox(height: 32),
                ],

                // Raw JSON Section (Second)
                if (result['parsed_json'] != null) ...[
                  _buildRawJsonSection(result['parsed_json']),
                  SizedBox(height: 32),
                ],

                // Entities (Third)
                if (entities != null && entities.isNotEmpty) ...[
                  _buildEntitiesSection(entities),
                  SizedBox(height: 32),
                ],

                // Tables (Fourth)
                if (tables != null && tables.isNotEmpty) ...[
                  _buildTablesSection(tables),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _exportData(),
        icon: Icon(Icons.download_rounded, size: 16),
        label: Text(
          'Export All',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOcrTextSection(dynamic ocrText) {
    // Parse the OCR text if it's a JSON string
    String displayText;
    try {
      if (ocrText is String) {
        final parsed = jsonDecode(ocrText);
        if (parsed is Map && parsed.containsKey('natural_text')) {
          displayText = parsed['natural_text'];
        } else {
          displayText = ocrText;
        }
      } else {
        displayText = ocrText.toString();
      }
    } catch (e) {
      displayText = ocrText.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: Color(0xFF8B5CF6),
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'OCR Extracted Text',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Spacer(),
            if (kIsWeb)
              IconButton(
                onPressed: () => _downloadText(displayText, 'ocr_text.txt'),
                icon: Icon(Icons.download_rounded, color: Color(0xFF8B5CF6)),
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Download OCR Text',
              ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 300),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF0B0B0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF2A2A35)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              displayText,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                color: Color(0xFFE5E7EB),
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawJsonSection(dynamic parsedJson) {
    final prettyJson = JsonEncoder.withIndent('  ').convert(parsedJson);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.code_rounded,
                color: Color(0xFFEF4444),
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Parsed JSON Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Spacer(),
            if (kIsWeb)
              IconButton(
                onPressed: () => _downloadJson(parsedJson, 'parsed_data.json'),
                icon: Icon(Icons.download_rounded, color: Color(0xFFEF4444)),
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFFEF4444).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                tooltip: 'Download JSON Data',
              ),
          ],
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: 400),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF0B0B0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF2A2A35)),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              prettyJson,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFFE5E7EB),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntitiesSection(Map<String, dynamic> entities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF06B6D4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.label_rounded,
                color: Color(0xFF06B6D4),
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Extracted Entities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: entities.entries.map((entry) {
            final values = entry.value as List?;
            if (values == null || values.isEmpty) return SizedBox.shrink();
            return _buildEntityCard(entry.key, values);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEntityCard(String key, List values) {
    return Container(
      constraints: BoxConstraints(minWidth: 200),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF0B0B0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF2A2A35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEntityIcon(key),
                size: 18,
                color: Color(0xFF06B6D4),
              ),
              SizedBox(width: 8),
              Text(
                _formatEntityName(key),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF06B6D4),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF1F1F28),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF2A2A35)),
                ),
                child: SelectableText(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFE5E7EB),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesSection(List tables) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.table_chart_rounded,
                color: Color(0xFFF59E0B),
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Extracted Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...tables.asMap().entries.map((entry) {
          return Container(
            margin: EdgeInsets.only(bottom: 20),
            child:
                _buildTable(entry.value as Map<String, dynamic>, entry.key + 1),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTable(Map<String, dynamic> table, int tableNumber) {
    final headers = table['headers'] as List? ?? [];
    final rows = table['rows'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0B0B0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF2A2A35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF1F1F28),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.table_chart_rounded,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Table $tableNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                if (kIsWeb)
                  IconButton(
                    onPressed: () => _exportTableToCsv(table, tableNumber),
                    icon:
                        Icon(Icons.download_rounded, color: Color(0xFFF59E0B)),
                    style: IconButton.styleFrom(
                      backgroundColor: Color(0xFFF59E0B).withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    tooltip: 'Download as CSV',
                  ),
              ],
            ),
          ),
          // Table content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.all(20),
            child: DataTable(
              columnSpacing: 32,
              headingRowHeight: 48,
              dataRowHeight: 44,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFFF59E0B),
              ),
              dataTextStyle: TextStyle(
                fontSize: 14,
                color: Color(0xFFE5E7EB),
              ),
              columns: headers.map<DataColumn>((header) {
                return DataColumn(
                  label: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1F1F28),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(header.toString()),
                  ),
                );
              }).toList(),
              rows: rows.map<DataRow>((row) {
                final rowData = row as List;
                return DataRow(
                  cells: rowData.map<DataCell>((cell) {
                    final cellText = cell.toString();
                    return DataCell(
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SelectableText(
                          cellText.isEmpty ? '-' : cellText,
                          style: TextStyle(
                            fontSize: 14,
                            color: cellText.isEmpty
                                ? Color(0xFF6B7280)
                                : Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEntityName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  IconData _getEntityIcon(String fieldName) {
    final field = fieldName.toLowerCase();
    if (field.contains('name')) return Icons.person_rounded;
    if (field.contains('date')) return Icons.calendar_today_rounded;
    if (field.contains('email')) return Icons.email_rounded;
    if (field.contains('address')) return Icons.location_on_rounded;
    if (field.contains('phone')) return Icons.phone_rounded;
    if (field.contains('amount') || field.contains('price'))
      return Icons.attach_money_rounded;
    return Icons.label_rounded;
  }

  void _exportData() {
    if (kIsWeb) {
      final jsonData = jsonEncode(result);
      final blob = html.Blob([jsonData], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'complete_extraction_results.json')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  void _downloadText(String text, String filename) {
    if (kIsWeb) {
      final blob = html.Blob([text], 'text/plain');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  void _downloadJson(dynamic jsonData, String filename) {
    if (kIsWeb) {
      final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  void _exportTableToCsv(Map<String, dynamic> table, int tableNumber) {
    if (kIsWeb) {
      final headers = table['headers'] as List? ?? [];
      final rows = table['rows'] as List? ?? [];

      String csv = headers.join(',') + '\n';
      for (var row in rows) {
        final escapedRow = (row as List).map((cell) {
          final cellStr = cell.toString();
          // Escape CSV special characters
          if (cellStr.contains(',') ||
              cellStr.contains('"') ||
              cellStr.contains('\n')) {
            return '"${cellStr.replaceAll('"', '""')}"';
          }
          return cellStr;
        }).toList();
        csv += escapedRow.join(',') + '\n';
      }

      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'table_$tableNumber.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
