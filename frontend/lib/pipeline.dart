// lib/widgets/pipeline_card.dart
import 'package:flutter/material.dart';
import '../models/ocr_state.dart';

class PipelineCard extends StatelessWidget {
  final OcrState state;

  const PipelineCard({required this.state});

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing Pipeline',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Document analysis workflow',
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
          
          // Pipeline steps
          Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PipelineNode(
                        title: 'Upload',
                        subtitle: 'Select file',
                        icon: Icons.upload_file_rounded,
                        isActive: false,
                        isCompleted: state.hasFile,
                      ),
                    ),
                    _buildConnector(state.hasFile),
                    Expanded(
                      child: PipelineNode(
                        title: 'Process',
                        subtitle: 'AI analysis',
                        icon: Icons.psychology_rounded,
                        isActive: state.isLoading,
                        isCompleted: state.hasResult,
                      ),
                    ),
                    _buildConnector(state.hasResult),
                    Expanded(
                      child: PipelineNode(
                        title: 'Results',
                        subtitle: 'Data ready',
                        icon: Icons.data_object_rounded,
                        isActive: false,
                        isCompleted: state.hasResult,
                      ),
                    ),
                  ],
                ),
                
                // Progress bar
                SizedBox(height: 24),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF2A2A35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    width: MediaQuery.of(context).size.width * _getProgress(),
                    decoration: BoxDecoration(
                      color: Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildConnector(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      width: 60,
      height: 3,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isActive ? Color(0xFF6366F1) : Color(0xFF2A2A35),
        borderRadius: BorderRadius.circular(2),
      ),
      child: isActive
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  double _getProgress() {
    if (state.hasResult) return 1.0;
    if (state.isLoading) return 0.6;
    if (state.hasFile) return 0.3;
    return 0.0;
  }

  String _getStatusText() {
    if (state.hasResult) return 'Processing complete';
    if (state.isLoading) return 'Analyzing document...';
    if (state.hasFile) return 'Ready to process';
    return 'Waiting for file upload';
  }
}

class PipelineNode extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;

  const PipelineNode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Color getColor() {
      if (isCompleted) return Color(0xFF10B981);
      if (isActive) return Color(0xFF6366F1);
      return Color(0xFF6B7280);
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.1),
              border: Border.all(
                color: getColor(),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isActive || isCompleted
                  ? [
                      BoxShadow(
                        color: getColor().withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isActive
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: getColor(),
                        ),
                      )
                    : Icon(
                        isCompleted ? Icons.check_rounded : icon,
                        color: getColor(),
                        size: 24,
                        key: ValueKey(isCompleted),
                      ),
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: getColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}