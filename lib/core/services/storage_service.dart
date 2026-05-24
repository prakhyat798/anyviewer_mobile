import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/document_file.dart';

class StorageService {
  static const String _themeKey = 'anyviewer_theme';
  static const String _fontSizeKey = 'anyviewer_fontsize';
  static const String _recentFilesKey = 'anyviewer_recent_files';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Theme Mode
  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'dark';
  }

  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  // Font Size
  double getFontSize() {
    return _prefs.getDouble(_fontSizeKey) ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    await _prefs.setDouble(_fontSizeKey, size);
  }

  // Recent Files
  List<DocumentFile> getRecentFiles() {
    final List<String>? list = _prefs.getStringList(_recentFilesKey);
    if (list == null) return [];
    try {
      return list
          .map((item) => DocumentFile.fromJson(json.decode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecentFiles(List<DocumentFile> files) async {
    final List<String> list = files.map((file) => json.encode(file.toJson())).toList();
    await _prefs.setStringList(_recentFilesKey, list);
  }

  Future<void> clearRecentFiles() async {
    await _prefs.remove(_recentFilesKey);
  }
}
