import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final fontScale = appState.fontSize / 16.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Settings ⚙️',
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 28 * fontScale,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure your offline document viewer preferences.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 14 * fontScale,
            ),
          ),
          const SizedBox(height: 24),

          // Setting Options Card
          Container(
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 16, borderOpacity: 0.1),
            child: Column(
              children: [
                // Theme Option
                ListTile(
                  leading: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: isDark ? Colors.deepPurpleAccent : Colors.amber,
                  ),
                  title: Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isDark ? 'Dark Theme (Deep space)' : 'Light Theme (Clean White)',
                    style: TextStyle(fontSize: 12 * fontScale),
                  ),
                  trailing: Switch(
                    value: isDark,
                    onChanged: (_) => appState.toggleTheme(),
                    activeColor: Colors.deepPurpleAccent,
                  ),
                ),
                const Divider(height: 1, indent: 56),

                // Font Size Option
                ListTile(
                  leading: const Icon(Icons.text_fields, color: Colors.blueAccent),
                  title: Text(
                    'Text Font Size',
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Adjust document reader typography sizing.',
                    style: TextStyle(fontSize: 12 * fontScale),
                  ),
                  trailing: DropdownButton<double>(
                    value: appState.fontSize,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 14.0, child: Text('Small (14)')),
                      DropdownMenuItem(value: 16.0, child: Text('Medium (16)')),
                      DropdownMenuItem(value: 18.0, child: Text('Large (18)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        appState.setFontSize(val);
                      }
                    },
                  ),
                ),
                const Divider(height: 1, indent: 56),

                // Reset Option
                ListTile(
                  onTap: () {
                    _showResetConfirm(context, appState);
                  },
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: Text(
                    'Clear Recents Cache',
                    style: TextStyle(
                      fontSize: 15 * fontScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Delete local file metadata and opened history.',
                    style: TextStyle(fontSize: 12 * fontScale),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 16, borderOpacity: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About AnyViewer',
                  style: TextStyle(
                    fontSize: 15 * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'AnyViewer unifies PDFs, text documents, PowerPoint slides, spreadsheets, and physical scanning captures in a cohesive local interface. 100% offline. Zero telemetry.',
                  style: TextStyle(
                    fontSize: 12 * fontScale,
                    height: 1.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Version 1.0.0 (Local React Engine Port)',
                  style: TextStyle(
                    fontSize: 11 * fontScale,
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirm(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear recent history?'),
        content: const Text(
          'This will remove all document paths and history entries from your offline dashboard. The original files on your device will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.clearRecentFiles();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recent files history cleared.')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

