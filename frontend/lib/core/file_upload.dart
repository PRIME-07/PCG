// lib/widgets/file_upload_card.dart
import 'package:flutter/material.dart';

class FileUploadCard extends StatelessWidget {
  final bool hasFile;
  final String? fileName;
  final VoidCallback onPickFile;

  const FileUploadCard({
    required this.hasFile,
    this.fileName,
    required this.onPickFile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: onPickFile,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasFile ? Color(0xFF4CAF50) : Color(0xFF3A3A3A),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: hasFile ? Color(0xFF4CAF50).withOpacity(0.05) : Color(0xFF0F0F0F),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_rounded,
                        size: 36,
                        color: hasFile ? Color(0xFF4CAF50) : Color(0xFF666666),
                        key: ValueKey(hasFile),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      hasFile ? 'File Selected' : 'Click to upload file',
                      style: TextStyle(
                        color: hasFile ? Color(0xFF4CAF50) : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!hasFile) ...[
                      SizedBox(height: 4),
                      Text(
                        'PDF, JPG, PNG, JPEG',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasFile && fileName != null) ...[
              SizedBox(height: 16),
              AnimatedSlide(
                offset: hasFile ? Offset.zero : Offset(0, -0.5),
                duration: Duration(milliseconds: 300),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF0F0F0F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF2A2A2A)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(fileName!),
                        color: Color(0xFF2196F3),
                        size: 18,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName!,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.description_rounded;
    }
  }
}