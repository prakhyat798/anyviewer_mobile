import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/app_state_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document_file.dart';
import '../widgets/bouncy_tap_detector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size % 1 == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  IconData _getFileIcon(String ext) {
    final cleanExt = ext.toLowerCase().trim();
    if (cleanExt == 'pdf') return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(cleanExt)) return Icons.description_outlined;
    if (['xls', 'xlsx', 'csv'].contains(cleanExt)) return Icons.table_chart_outlined;
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(cleanExt)) return Icons.image_outlined;
    if (['ppt', 'pptx'].contains(cleanExt)) return Icons.slideshow_outlined;
    if (['txt', 'md', 'json', 'xml'].contains(cleanExt)) return Icons.article_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _getFileColor(String ext) {
    final cleanExt = ext.toLowerCase().trim();
    if (cleanExt == 'pdf') return const Color(0xFFEF4444); // Soft Red
    if (['doc', 'docx'].contains(cleanExt)) return const Color(0xFF3B82F6); // Soft Blue
    if (['xls', 'xlsx', 'csv'].contains(cleanExt)) return const Color(0xFF10B981); // Soft Green
    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(cleanExt)) return const Color(0xFFF59E0B); // Soft Amber
    if (['ppt', 'pptx'].contains(cleanExt)) return const Color(0xFFEC4899); // Soft Pink
    return const Color(0xFF06B6D4); // Soft Cyan
  }

  Future<void> _pickDocument(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        final platformFile = result.files.single;
        final extension = platformFile.extension ?? 
            platformFile.path!.split('.').last.toLowerCase();
        
        final docFile = DocumentFile(
          name: platformFile.name,
          path: platformFile.path!,
          size: platformFile.size,
          extension: extension,
          openedAt: DateTime.now(),
        );
        appState.openFile(docFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting file: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showTagSelector(BuildContext context, AppStateProvider appState, DocumentFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111022) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categorize Document',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Add tags to easily filter documents on your dashboard.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTagPillOption(context, appState, file, 'Work', Colors.blueAccent),
                  _buildTagPillOption(context, appState, file, 'Personal', Colors.tealAccent),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagPillOption(
    BuildContext context,
    AppStateProvider appState,
    DocumentFile file,
    String tag,
    Color color,
  ) {
    final hasTag = file.tags.contains(tag);
    return BouncyTapDetector(
      onTap: () {
        if (hasTag) {
          appState.removeTagFromFile(file, tag);
        } else {
          appState.addTagToFile(file, tag);
        }
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: hasTag ? color.withOpacity(0.16) : Colors.transparent,
          border: Border.all(color: hasTag ? color : Colors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              hasTag ? Icons.check_circle : Icons.add_circle_outline,
              color: hasTag ? color : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              tag,
              style: TextStyle(
                color: hasTag ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final fontScale = appState.fontSize / 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // OxygenOS styled Dynamic Branding
          Text(
            'AnyViewer',
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 34 * fontScale,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              foreground: Paint()
                ..shader = AppTheme.brandGradient.createShader(
                  const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0),
                ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fluid offline document engines & visual scanning captures.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),

          // Material You squircle Search Bar
          Container(
            decoration: AppTheme.glassDecoration(
              isDark: isDark,
              borderRadius: 24,
              borderOpacity: 0.12,
            ),
            child: TextField(
              onChanged: appState.setSearchQuery,
              style: TextStyle(fontSize: 15 * fontScale),
              decoration: InputDecoration(
                hintText: 'Search offline files...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 15 * fontScale,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Grid Buttons with Bouncy Feedback and Squircle Card structures
          Row(
            children: [
              Expanded(
                child: BouncyTapDetector(
                  onTap: () => _pickDocument(context),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    height: 144,
                    decoration: AppTheme.glassDecoration(
                      isDark: isDark,
                      borderRadius: 28,
                      borderOpacity: 0.16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.file_open_outlined, color: Colors.blueAccent, size: 24),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Open Document',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PDF, Docx, Spreadsheet',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BouncyTapDetector(
                  onTap: () => appState.navigate('scanner'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    height: 144,
                    decoration: AppTheme.glassDecoration(
                      isDark: isDark,
                      borderRadius: 28,
                      borderOpacity: 0.16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.document_scanner_outlined, color: Colors.deepPurpleAccent, size: 24),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Start Scanner',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16 * fontScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan pages to PDF',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Categories Horizontal Filter Bar (Material You & OxygenOS dynamic pills)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryPill(context, appState, 'All'),
                _buildCategoryPill(context, appState, 'Starred'),
                _buildCategoryPill(context, appState, 'Work'),
                _buildCategoryPill(context, appState, 'Personal'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Recent Files Title Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Entries',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 18 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (appState.recentFiles.isNotEmpty)
                BouncyTapDetector(
                  onTap: appState.clearRecentFiles,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Files List View with Squircle Cards, Starring and Tagging
          Expanded(
            child: appState.filteredRecentFiles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 48,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appState.searchQuery.isEmpty ? 'No recent documents found' : 'No matching entries found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 14 * fontScale,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: appState.filteredRecentFiles.length,
                    itemBuilder: (context, index) {
                      final file = appState.filteredRecentFiles[index];
                      final dateString = DateFormat('MMM dd • HH:mm').format(file.openedAt);
                      final fileColor = _getFileColor(file.extension);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: BouncyTapDetector(
                          onTap: () => appState.openFile(file),
                          child: Container(
                            decoration: AppTheme.glassDecoration(
                              isDark: isDark,
                              borderRadius: 24,
                              borderOpacity: 0.08,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: fileColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: fileColor.withOpacity(0.2)),
                                ),
                                child: Icon(
                                  _getFileIcon(file.extension),
                                  color: fileColor,
                                  size: 24,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontSize: 14 * fontScale,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_formatSize(file.size)} • $dateString',
                                    style: TextStyle(
                                      fontSize: 11 * fontScale,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                  // Rendering tags if present
                                  if (file.tags.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      children: file.tags.map((tag) {
                                        final isWork = tag == 'Work';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isWork ? Colors.blueAccent : Colors.tealAccent).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isWork ? Colors.blueAccent : Colors.tealAccent,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Add Tag Trigger
                                  IconButton(
                                    icon: const Icon(Icons.label_outline, size: 18),
                                    onPressed: () => _showTagSelector(context, appState, file),
                                    tooltip: 'Add tag',
                                  ),
                                  // Star Favorite Button
                                  BouncyTapDetector(
                                    onTap: () => appState.toggleStarFile(file),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        file.isStarred ? Icons.star : Icons.star_border,
                                        color: file.isStarred ? Colors.amber : Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(BuildContext context, AppStateProvider appState, String category) {
    final isSelected = appState.selectedCategory == category;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: BouncyTapDetector(
        onTap: () => appState.setSelectedCategory(category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.darkPrimary
                : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppTheme.darkPrimary.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

