// lib/widgets/file_upload_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Web-specific imports
import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:typed_data';

class FileUploadCard extends StatefulWidget {
  final bool hasFile;
  final String? fileName;
  final VoidCallback onPickFile;
  final Function(List<int> bytes, String fileName)? onImageCaptured;
  // New callback for when a file is dropped on the web
  final Function(List<int> bytes, String fileName)? onFileDropped;

  const FileUploadCard({
    super.key,
    required this.hasFile,
    this.fileName,
    required this.onPickFile,
    this.onImageCaptured,
    this.onFileDropped, // Added to constructor
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

  // A unique key for the platform view
  final String _viewType = 'file-upload-drag-drop-area';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
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

    // Register the platform view factory for web
    if (kIsWeb) {
      _registerViewFactory();
    }
  }

  void _registerViewFactory() {
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final html.DivElement element = html.DivElement()
          ..style.width = '100%'
          ..style.height = '100%';

        // Prevent default browser behavior for drag-and-drop
        element.onDragOver.listen((html.MouseEvent event) {
          event.preventDefault();
          if (!_isDragOver) {
            setState(() {
              _isDragOver = true;
            });
          }
        });

        element.onDragLeave.listen((html.MouseEvent event) {
          event.preventDefault();
          if (_isDragOver) {
            setState(() {
              _isDragOver = false;
            });
          }
        });

        // Handle the file drop
        element.onDrop.listen((html.MouseEvent event) {
          event.preventDefault();
          setState(() {
            _isDragOver = false;
          });

          final files = event.dataTransfer?.files;
          if (files != null && files.isNotEmpty) {
            final file = files.first;
            final allowedTypes = ['pdf', 'jpg', 'jpeg', 'png'];
            final extension = file.name.split('.').last.toLowerCase();
            
            if (allowedTypes.contains(extension)) {
              final reader = html.FileReader();
              reader.readAsArrayBuffer(file);
              reader.onLoadEnd.listen((e) {
                if (widget.onFileDropped != null) {
                  final bytes = reader.result as Uint8List;
                  widget.onFileDropped!(bytes, file.name);
                }
              });
            } else {
               ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Unsupported file type: $extension'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });

        return element;
      },
    );
  }


  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose Upload Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Camera option
            if (!kIsWeb)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (!kIsWeb) const SizedBox(height: 12),
            // Gallery option
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPickFile();
                },
                icon: const Icon(Icons.photo_library_rounded, size: 20),
                label: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F1F28),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF2A2A35)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A2A35)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
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
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.upload_file_rounded,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Column(
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
            padding: const EdgeInsets.all(24),
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
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isDragOver 
                      ? const Color(0xFF8B5CF6) 
                      : const Color(0xFF2A2A35),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
                color: _isDragOver 
                    ? const Color(0xFF8B5CF6).withOpacity(0.05) 
                    : const Color(0xFF0B0B0F),
              ),
              child: Stack(
                children: [
                  // This is now the container for the HtmlElementView on web
                  if (kIsWeb)
                    HtmlElementView(viewType: _viewType),

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
                              color: const Color(0xFF8B5CF6).withOpacity(0.02),
                            ),
                          ),
                        );
                      },
                    ),
                  
                  // Content (visuals only)
                  IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _isDragOver 
                                  ? const Color(0xFF8B5CF6).withOpacity(0.2)
                                  : const Color(0xFF1F1F28),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isDragOver 
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF2A2A35),
                              ),
                            ),
                            child: Icon(
                              _isDragOver 
                                  ? Icons.file_download_rounded
                                  : Icons.cloud_upload_rounded,
                              size: 36,
                              color: _isDragOver 
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _isDragOver 
                                ? 'Drop your file here'
                                : kIsWeb 
                                    ? 'Drag & drop or click to upload'
                                    : 'Tap to upload or take photo',
                            style: TextStyle(
                              color: _isDragOver 
                                  ? const Color(0xFF8B5CF6)
                                  : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_isDragOver)
                            const Text(
                              'Maximum file size: 10MB',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
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
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getFileIcon(widget.fileName!),
                color: const Color(0xFF10B981),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
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
                  const SizedBox(height: 8),
                  Text(
                    widget.fileName!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
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
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: widget.onPickFile,
                icon: const Icon(
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