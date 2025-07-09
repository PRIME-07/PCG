// lib/pages/ocr_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ocr_document_extractor/core/file_upload.dart';
import 'package:ocr_document_extractor/pipeline.dart';
import 'package:ocr_document_extractor/providers/ocr_provider.dart';


class OcrPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ocrProvider);
    final notifier = ref.read(ocrProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('OCR Document Extractor'),
        actions: [
          if (state.hasFile)
            AnimatedSlide(
              offset: state.hasFile ? Offset.zero : Offset(1, 0),
              duration: Duration(milliseconds: 300),
              child: IconButton(
                icon: Icon(Icons.refresh_rounded),
                onPressed: notifier.clear,
                tooltip: 'Clear',
              ),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 400),
        child: SingleChildScrollView(
          key: ValueKey(state.hasFile),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              // Pipeline visualization
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                child: PipelineCard(state: state),
              ),
              SizedBox(height: 20),

              // File upload
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                child: FileUploadCard(
                  hasFile: state.hasFile,
                  fileName: state.fileName,
                  onPickFile: () => _pickFile(ref),
                ),
              ),
              
              // Process button
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: state.hasFile && !state.isLoading
                    ? Container(
                        margin: EdgeInsets.only(top: 20),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: notifier.processFile,
                          icon: Icon(Icons.auto_fix_high_rounded),
                          label: Text('Process Document'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),

              // Loading indicator
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: state.isLoading
                    ? Container(
                        margin: EdgeInsets.only(top: 30),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Processing document...',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : SizedBox.shrink(),
              ),

              // Error display
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                child: state.hasError
                    ? Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Card(
                          color: Color(0xFF2A1A1A),
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[900]!, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline_rounded, color: Colors.red[400]),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),

              // Results
              AnimatedSize(
                duration: Duration(milliseconds: 400),
                child: state.hasResult
                    ? Container(
                        margin: EdgeInsets.only(top: 20),
                        child: ResultCard(result: state.result!),
                      )
                    : SizedBox.shrink(),
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
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[900],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}


// lib/widgets/result_card.dart

class ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final entities = result['parsed_json']?['entities'] as Map<String, dynamic>?;
    final tables = result['parsed_json']?['tables'] as List?;

    return Card(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Text(
                  'Extracted Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 20),

            // OCR Text
            if (result['ocr_text'] != null) ...[
              _buildSectionHeader('OCR Text'),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF0F0F0F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF2A2A2A)),
                ),
                child: Text(
                  result['ocr_text'],
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey[300],
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],

            // Entities
            if (entities != null && entities.isNotEmpty) ...[
              _buildSectionHeader('Entities'),
              SizedBox(height: 12),
              ...entities.entries.map((entry) {
                final values = entry.value as List?;
                if (values == null || values.isEmpty) return SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: _buildEntityRow(entry.key, values),
                );
              }).toList(),
              SizedBox(height: 20),
            ],

            // Tables
            if (tables != null && tables.isNotEmpty) ...[
              _buildSectionHeader('Tables'),
              SizedBox(height: 12),
              ...tables.asMap().entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: _buildTable(entry.value as Map<String, dynamic>, entry.key + 1),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2196F3),
      ),
    );
  }

  Widget _buildEntityRow(String key, List values) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getEntityIcon(key), size: 14, color: Color(0xFF2196F3)),
              SizedBox(width: 8),
              Text(
                key,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: values.map((value) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Color(0xFF2196F3).withOpacity(0.3)),
                ),
                child: Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[300],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(Map<String, dynamic> table, int tableNumber) {
    final headers = table['headers'] as List? ?? [];
    final rows = table['rows'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, size: 14, color: Colors.grey[400]),
                SizedBox(width: 8),
                Text(
                  'Table $tableNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            ),
          ),
          // Table content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              headingRowHeight: 40,
              dataRowHeight: 36,
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF2196F3),
              ),
              dataTextStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[300],
              ),
              columns: headers.map<DataColumn>((header) {
                return DataColumn(
                  label: Text(header.toString()),
                );
              }).toList(),
              rows: rows.map<DataRow>((row) {
                final rowData = row as List;
                return DataRow(
                  cells: rowData.map<DataCell>((cell) {
                    final cellText = cell.toString();
                    return DataCell(
                      Text(
                        cellText.isEmpty ? '-' : cellText,
                        style: TextStyle(
                          fontSize: 12,
                          color: cellText.isEmpty ? Colors.grey[600] : Colors.grey[300],
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

  IconData _getEntityIcon(String fieldName) {
    final field = fieldName.toLowerCase();
    if (field.contains('name')) return Icons.person_rounded;
    if (field.contains('date')) return Icons.calendar_today_rounded;
    if (field.contains('email')) return Icons.email_rounded;
    if (field.contains('address')) return Icons.location_on_rounded;
    if (field.contains('phone')) return Icons.phone_rounded;
    if (field.contains('amount') || field.contains('price')) return Icons.attach_money_rounded;
    return Icons.label_rounded;
  }
}