// lib/widgets/file_upload_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
import 'dart:io';

class FileUploadCard extends StatefulWidget {
  final bool hasFile;
  final String? fileName;
  final VoidCallback onPickFile;
  final Function(List<int> bytes, String fileName)? onImageCaptured;

  const FileUploadCard({
    required this.hasFile,
    this.fileName,
    required this.onPickFile,
    this.onImageCaptured,
  });

  @override
  _FileUploadCardState createState() => _FileUploadCardState();
}

class _FileUploadCardState extends State<FileUploadCard>
    with TickerProviderStateMixin {
  bool _isDragOver = false;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _handleDragEnter() {
    setState(() {
      _isDragOver = true;
    });
  }

  void _handleDragLeave() {
    setState(() {
      _isDragOver = false;
    });
  }

  void _handleDragOver(dynamic event) {
    if (kIsWeb) {
      event.preventDefault();
    }
  }

  void _handleDrop(dynamic event) {
    if (kIsWeb) {
      event.preventDefault();
      setState(() {
        _isDragOver = false;
      });

      // Handle file drop for web
      final files = event.dataTransfer?.files;
      if (files != null && files.isNotEmpty) {
        final file = files.first;
        final allowedTypes = ['pdf', 'jpg', 'jpeg', 'png'];
        final extension = file.name.split('.').last.toLowerCase();
        
        if (allowedTypes.contains(extension)) {
          // Handle file upload logic here
          widget.onPickFile();
        }
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (photo != null) {
        final File imageFile = File(photo.path);
        final List<int> bytes = await imageFile.readAsBytes();
        final String fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        if (widget.onImageCaptured != null) {
          widget.onImageCaptured!(bytes, fileName);
        }
      }
    } catch (e) {
      // Handle camera error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1F1F28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFF2A2A35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Choose Upload Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 24),
            // Camera option
            if (!kIsWeb)
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                  icon: Icon(Icons.camera_alt_rounded, size: 20),
                  label: Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (!kIsWeb) SizedBox(height: 12),
            // Gallery option
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPickFile();
                },
                icon: Icon(Icons.photo_library_rounded, size: 20),
                label: Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1F1F28),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Color(0xFF2A2A35)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF2A2A35)),
      ),
      child: Column(
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
                    color: Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'PDF, JPG, PNG, JPEG supported',
                      style: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Upload area
          Padding(
            padding: EdgeInsets.all(24),
            child: widget.hasFile ? _buildFileSelected() : _buildUploadArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: () {
        _scaleController.forward().then((_) {
          _scaleController.reverse();
        });
        // Show upload options for mobile, direct file picker for web
        if (kIsWeb) {
          widget.onPickFile();
        } else {
          _showUploadOptions();
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        child: kIsWeb 
          ? _buildWebDragDropArea()
          : Container(
              width: double.infinity,
              height: 200,
            ),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isDragOver 
                      ? Color(0xFF8B5CF6) 
                      : Color(0xFF2A2A35),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
                color: _isDragOver 
                    ? Color(0xFF8B5CF6).withOpacity(0.05) 
                    : Color(0xFF0B0B0F),
              ),
              child: Stack(
                children: [
                  // Animated background
                  if (!_isDragOver)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Color(0xFF8B5CF6).withOpacity(0.02),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isDragOver 
                                ? Color(0xFF8B5CF6).withOpacity(0.2)
                                : Color(0xFF1F1F28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isDragOver 
                                  ? Color(0xFF8B5CF6)
                                  : Color(0xFF2A2A35),
                            ),
                          ),
                          child: Icon(
                            _isDragOver 
                                ? Icons.file_download_rounded
                                : Icons.cloud_upload_rounded,
                            size: 36,
                            color: _isDragOver 
                                ? Color(0xFF8B5CF6)
                                : Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          _isDragOver 
                              ? 'Drop your file here'
                              : kIsWeb 
                                  ? 'Drag & drop or click to upload'
                                  : 'Tap to upload or take photo',
                          style: TextStyle(
                            color: _isDragOver 
                                ? Color(0xFF8B5CF6)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        if (!_isDragOver)
                          Text(
                            'Maximum file size: 10MB',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileSelected() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Color(0xFF10B981).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getFileIcon(widget.fileName!),
                color: Color(0xFF10B981),
                size: 28,
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'File Selected',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.fileName!,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ready to process',
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: widget.onPickFile,
                icon: Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                tooltip: 'Change file',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDragDropArea() {
    return Container(
      width: double.infinity,
      height: 200,
      child: HtmlElementView(
        viewType: 'drag-drop-area',
        onPlatformViewCreated: (int id) {
          // The HTML element will be created by the platform view
        },
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