// lib/widgets/react_flow_pipeline.dart
import 'package:flutter/material.dart';
import '../models/ocr_state.dart';

class EnhancedPipelineCard extends StatefulWidget {
  final OcrState state;

  const EnhancedPipelineCard({required this.state});

  @override
  _EnhancedPipelineCardState createState() => _EnhancedPipelineCardState();
}

class _EnhancedPipelineCardState extends State<EnhancedPipelineCard> {
  // Node positions (can be dragged)
  Offset inputNodePos = Offset(50, 100);
  Offset processingNodePos = Offset(300, 100);
  Offset outputNodePos = Offset(550, 100);
  
  // Canvas transform
  Offset canvasOffset = Offset.zero;
  double canvasScale = 1.0;
  
  // Interaction state
  String? draggedNode;
  Offset? lastPanPoint;

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
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_tree_rounded,
                    color: Color(0xFF6366F1),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive Pipeline Canvas',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Drag nodes • Pan canvas • Zoom with scroll',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Canvas controls
                Row(
                  children: [
                    _buildControlButton(
                      Icons.zoom_in_rounded,
                      'Zoom In',
                      () => setState(() => canvasScale = (canvasScale * 1.2).clamp(0.5, 3.0)),
                    ),
                    SizedBox(width: 8),
                    _buildControlButton(
                      Icons.zoom_out_rounded,
                      'Zoom Out',
                      () => setState(() => canvasScale = (canvasScale / 1.2).clamp(0.5, 3.0)),
                    ),
                    SizedBox(width: 8),
                    _buildControlButton(
                      Icons.center_focus_strong_rounded,
                      'Reset View',
                      () => setState(() {
                        canvasScale = 1.0;
                        canvasOffset = Offset.zero;
                        inputNodePos = Offset(50, 100);
                        processingNodePos = Offset(300, 100);
                        outputNodePos = Offset(550, 100);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Interactive Canvas
          Container(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  width: double.infinity,
                  color: Color(0xFF0B0B0F),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(canvasScale)
                      ..translate(canvasOffset.dx, canvasOffset.dy),
                    child: Stack(
                      children: [
                        // Grid background
                        CustomPaint(
                          painter: GridPainter(),
                          size: Size.infinite,
                        ),
                        
                        // Connections
                        CustomPaint(
                          painter: ConnectionPainter(
                            widget.state,
                            inputNodePos,
                            processingNodePos,
                            outputNodePos,
                          ),
                          size: Size.infinite,
                        ),
                        
                        // Input Node
                        Positioned(
                          left: inputNodePos.dx,
                          top: inputNodePos.dy,
                          child: DraggableFlowNode(
                            nodeId: 'input',
                            title: 'Input',
                            subtitle: 'PDF/Image Upload',
                            icon: Icons.upload_file_rounded,
                            isActive: false,
                            isCompleted: widget.state.hasFile,
                            color: Color(0xFF06B6D4),
                            onDragStart: () => draggedNode = 'input',
                            onDragUpdate: (delta) => setState(() => inputNodePos += delta),
                            onDragEnd: () => draggedNode = null,
                            onTap: () => _onNodeTapped('input'),
                          ),
                        ),
                        
                        // Processing Node
                        Positioned(
                          left: processingNodePos.dx,
                          top: processingNodePos.dy,
                          child: DraggableFlowNode(
                            nodeId: 'processing',
                            title: 'Processing',
                            subtitle: 'OlmOCR Extraction',
                            icon: Icons.psychology_rounded,
                            isActive: widget.state.isLoading,
                            isCompleted: widget.state.hasResult,
                            color: Color(0xFF6366F1),
                            onDragStart: () => draggedNode = 'processing',
                            onDragUpdate: (delta) => setState(() => processingNodePos += delta),
                            onDragEnd: () => draggedNode = null,
                            onTap: () => _onNodeTapped('processing'),
                          ),
                        ),
                        
                        // Output Node
                        Positioned(
                          left: outputNodePos.dx,
                          top: outputNodePos.dy,
                          child: DraggableFlowNode(
                            nodeId: 'output',
                            title: 'Output',
                            subtitle: 'JSON Data',
                            icon: Icons.data_object_rounded,
                            isActive: false,
                            isCompleted: widget.state.hasResult,
                            color: Color(0xFF10B981),
                            onDragStart: () => draggedNode = 'output',
                            onDragUpdate: (delta) => setState(() => outputNodePos += delta),
                            onDragEnd: () => draggedNode = null,
                            onTap: () => _onNodeTapped('output'),
                          ),
                        ),
                        
                        // Connection handles
                        _buildConnectionHandle(inputNodePos.dx + 150, inputNodePos.dy + 35, widget.state.hasFile),
                        _buildConnectionHandle(processingNodePos.dx - 8, processingNodePos.dy + 35, widget.state.hasFile),
                        _buildConnectionHandle(processingNodePos.dx + 158, processingNodePos.dy + 35, widget.state.hasResult),
                        _buildConnectionHandle(outputNodePos.dx - 8, outputNodePos.dy + 35, widget.state.hasResult),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Status section
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF252530),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatusIndicator('Input', widget.state.hasFile, Color(0xFF06B6D4)),
                    _buildStatusIndicator('Processing', widget.state.isLoading, Color(0xFF6366F1)),
                    _buildStatusIndicator('Output', widget.state.hasResult, Color(0xFF10B981)),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Color(0xFF1F1F28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFF2A2A35)),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Color(0xFF9CA3AF)),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildConnectionHandle(double left, double top, bool isActive) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF6366F1) : Color(0xFF6B7280),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
          boxShadow: isActive
              ? [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.4), blurRadius: 4)]
              : null,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isActive, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Color(0xFF6B7280),
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)]
                : null,
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? color : Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (draggedNode == null) {
      lastPanPoint = details.localPosition;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (draggedNode == null && lastPanPoint != null) {
      setState(() {
        canvasOffset += (details.localPosition - lastPanPoint!) / canvasScale;
        lastPanPoint = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    lastPanPoint = null;
  }

  void _onNodeTapped(String nodeId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nodeId node clicked'),
        duration: Duration(seconds: 1),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }

  String _getStatusText() {
    if (widget.state.hasResult) return 'Pipeline completed successfully';
    if (widget.state.isLoading) return 'Processing through OlmOCR extraction...';
    if (widget.state.hasFile) return 'Ready to start pipeline';
    return 'Upload PDF or image to begin';
  }
}

class DraggableFlowNode extends StatelessWidget {
  final String nodeId;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final Color color;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;

  const DraggableFlowNode({
    required this.nodeId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    required this.color,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getStatusColor() {
      if (isCompleted) return Color(0xFF10B981);
      if (isActive) return color;
      return Color(0xFF6B7280);
    }

    return GestureDetector(
      onPanStart: (_) => onDragStart(),
      onPanUpdate: (details) => onDragUpdate(details.delta),
      onPanEnd: (_) => onDragEnd(),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 150,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xFF252530),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: getStatusColor(),
            width: isActive || isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: getStatusColor().withOpacity(0.3),
              blurRadius: isActive || isCompleted ? 12 : 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isActive && !isCompleted
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: getStatusColor(),
                        ),
                      )
                    : Icon(
                        isCompleted ? Icons.check_rounded : icon,
                        color: getStatusColor(),
                        size: 16,
                      ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: getStatusColor(),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF2A2A35).withOpacity(0.3)
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ConnectionPainter extends CustomPainter {
  final OcrState state;
  final Offset inputPos;
  final Offset processingPos;
  final Offset outputPos;

  ConnectionPainter(this.state, this.inputPos, this.processingPos, this.outputPos);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Input to Processing connection
    final path1 = Path();
    final start1 = Offset(inputPos.dx + 150, inputPos.dy + 35);
    final end1 = Offset(processingPos.dx, processingPos.dy + 35);
    final control1 = Offset(start1.dx + (end1.dx - start1.dx) * 0.5, start1.dy);
    
    path1.moveTo(start1.dx, start1.dy);
    path1.quadraticBezierTo(control1.dx, control1.dy, end1.dx, end1.dy);
    
    paint.color = state.hasFile ? Color(0xFF6366F1) : Color(0xFF2A2A35);
    canvas.drawPath(path1, paint);

    // Processing to Output connection
    final path2 = Path();
    final start2 = Offset(processingPos.dx + 150, processingPos.dy + 35);
    final end2 = Offset(outputPos.dx, outputPos.dy + 35);
    final control2 = Offset(start2.dx + (end2.dx - start2.dx) * 0.5, start2.dy);
    
    path2.moveTo(start2.dx, start2.dy);
    path2.quadraticBezierTo(control2.dx, control2.dy, end2.dx, end2.dy);
    
    paint.color = state.hasResult ? Color(0xFF10B981) : Color(0xFF2A2A35);
    canvas.drawPath(path2, paint);

    // Animated data flow
    if (state.isLoading) {
      _drawDataFlow(canvas, path1, Color(0xFF6366F1));
      _drawDataFlow(canvas, path2, Color(0xFF8B5CF6));
    }
  }

  void _drawDataFlow(Canvas canvas, Path path, Color color) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final metrics = path.computeMetrics().first;
    final length = metrics.length;
    
    for (int i = 0; i < 2; i++) {
      final distance = (DateTime.now().millisecondsSinceEpoch / 800.0 * 100 + i * length / 2) % length;
      final tangent = metrics.getTangentForOffset(distance);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}