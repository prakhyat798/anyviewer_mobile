import 'package:flutter/material.dart';
import '../../../models/document_file.dart';
import '../../../core/theme/app_theme.dart';

class NativeViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const NativeViewerWidget({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<NativeViewerWidget> createState() => _NativeViewerWidgetState();
}

class _NativeViewerWidgetState extends State<NativeViewerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ext = widget.file.extension.toLowerCase().trim();

    // Map style variables based on file extension
    IconData formatIcon;
    Color themeColor;
    String formatName;

    if (['doc', 'docx'].contains(ext)) {
      formatIcon = Icons.description_rounded;
      themeColor = const Color(0xFF2B579A);
      formatName = 'Word Document';
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      formatIcon = Icons.table_view_rounded;
      themeColor = const Color(0xFF217346);
      formatName = 'Excel Spreadsheet';
    } else if (['ppt', 'pptx'].contains(ext)) {
      formatIcon = Icons.slideshow_rounded;
      themeColor = const Color(0xFFB7472A);
      formatName = 'PowerPoint Presentation';
    } else {
      formatIcon = Icons.insert_drive_file_rounded;
      themeColor = Colors.blueAccent;
      formatName = '${ext.toUpperCase()} File';
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Floating, pulsing, glowing document card
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: themeColor.withOpacity(0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Icon(
                  formatIcon,
                  size: 70,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Info card
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(20.0),
              decoration: AppTheme.glassDecoration(
                isDark: isDark,
                borderRadius: 20,
                borderOpacity: 0.15,
              ),
              child: Column(
                children: [
                  Text(
                    widget.file.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: themeColor.withOpacity(0.3), width: 1),
                        ),
                        child: Text(
                          formatName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(widget.file.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28, thickness: 0.8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_top_rounded,
                        size: 16,
                        color: themeColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'In-app viewer coming soon for this format.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                'Native rendering for this format is not yet available. Support is coming in a future update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
