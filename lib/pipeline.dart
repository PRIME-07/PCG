// lib/widgets/pipeline_card.dart
import 'package:flutter/material.dart';
import '../models/ocr_state.dart';

class PipelineCard extends StatelessWidget {
  final OcrState state;

  const PipelineCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_tree_rounded, color: Color(0xFF2196F3), size: 20),
                SizedBox(width: 8),
                Text(
                  'Processing Pipeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: PipelineNode(
                    title: 'Upload',
                    icon: Icons.upload_file_rounded,
                    isActive: false,
                    isCompleted: state.hasFile,
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  width: 40,
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: state.hasFile ? Color(0xFF2196F3) : Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: PipelineNode(
                    title: 'Process',
                    icon: Icons.psychology_rounded,
                    isActive: state.isLoading,
                    isCompleted: state.hasResult,
                  ),
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  width: 40,
                  height: 2,
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: state.hasResult ? Color(0xFF2196F3) : Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: PipelineNode(
                    title: 'Results',
                    icon: Icons.data_object_rounded,
                    isActive: false,
                    isCompleted: state.hasResult,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PipelineNode extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;

  const PipelineNode({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (isCompleted) return Color(0xFF4CAF50);
      if (isActive) return Color(0xFF2196F3);
      return Color(0xFF666666);
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.1),
              border: Border.all(color: getColor(), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isActive
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: getColor(),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : icon,
                        color: getColor(),
                        size: 20,
                        key: ValueKey(isCompleted),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: getColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}