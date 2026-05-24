import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/format_viewers/pdf_viewer_widget.dart';
import '../widgets/format_viewers/image_viewer_widget.dart';
import '../widgets/format_viewers/text_viewer_widget.dart';
import '../widgets/format_viewers/pptx_viewer_widget.dart';
import '../widgets/format_viewers/docx_viewer_widget.dart';
import '../widgets/format_viewers/spreadsheet_viewer_widget.dart';
import '../widgets/format_viewers/native_viewer_widget.dart';

class ViewerScreen extends StatelessWidget {
  const ViewerScreen({Key? key}) : super(key: key);

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  void _shareDocument(BuildContext context, String path, String name) {
    try {
      Share.shareXFiles([XFile(path)], text: 'Check out this document: $name');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final file = appState.currentFile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontScale = appState.fontSize / 16.0;

    if (file == null) {
      return const Center(child: Text('No active document'));
    }

    final ext = file.extension.toLowerCase().trim();
    Widget viewerWidget;

    // Route extension to the correct in-app viewer
    if (ext == 'pdf') {
      viewerWidget = PdfViewerWidget(file: file);
    } else if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
      viewerWidget = ImageViewerWidget(file: file);
    } else if (['txt', 'md', 'json', 'xml'].contains(ext)) {
      viewerWidget = TextViewerWidget(file: file);
    } else if (['ppt', 'pptx'].contains(ext)) {
      viewerWidget = PptxViewerWidget(file: file);
    } else if (['doc', 'docx'].contains(ext)) {
      viewerWidget = DocxViewerWidget(file: file);
    } else if (['xls', 'xlsx', 'csv'].contains(ext)) {
      viewerWidget = SpreadsheetViewerWidget(file: file);
    } else {
      // Fallback: open natively for truly unsupported formats
      viewerWidget = NativeViewerWidget(file: file);
    }

    return WillPopScope(
      onWillPop: () async {
        appState.closeFile();
        return false;
      },
      child: Column(
        children: [
          // Elegant Header Toolbar Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: AppTheme.glassDecoration(
                isDark: isDark,
                borderRadius: 14,
                borderOpacity: 0.1,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: appState.closeFile,
                    tooltip: 'Back to Home',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * fontScale,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ext.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            if (file.size > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatSize(file.size),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Font Size Action for Text files
                  if (['txt', 'md'].contains(ext)) ...[
                    IconButton(
                      icon: const Icon(Icons.text_fields),
                      onPressed: () {
                        // Toggle base font size: 14 -> 16 -> 18 -> 14
                        final current = appState.fontSize;
                        var next = 16.0;
                        if (current == 14.0) next = 16.0;
                        if (current == 16.0) next = 18.0;
                        if (current == 18.0) next = 14.0;
                        appState.setFontSize(next);
                      },
                      tooltip: 'Change Font Size',
                    ),
                  ],
                  // Share / export action
                  IconButton(
                    icon: const Icon(Icons.ios_share),
                    onPressed: () => _shareDocument(context, file.path, file.name),
                    tooltip: 'Share / Export File',
                  ),
                ],
              ),
            ),
          ),

          // Main Viewer canvas
          Expanded(
            child: viewerWidget,
          ),
        ],
      ),
    );
  }
}

