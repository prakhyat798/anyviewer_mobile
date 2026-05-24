import 'package:flutter/foundation.dart';
import '../core/services/storage_service.dart';
import '../models/document_file.dart';

class AppStateProvider with ChangeNotifier {
  final StorageService _storageService;

  String _currentPage = 'home';
  DocumentFile? _currentFile;
  List<DocumentFile> _recentFiles = [];
  String _searchQuery = '';
  double _fontSize = 16.0;
  String _themeMode = 'dark';
  String _selectedCategory = 'All';

  AppStateProvider(this._storageService) {
    _loadFromStorage();
  }

  // Getters
  String get currentPage => _currentPage;
  DocumentFile? get currentFile => _currentFile;
  List<DocumentFile> get recentFiles => _recentFiles;
  String get searchQuery => _searchQuery;
  double get fontSize => _fontSize;
  String get themeMode => _themeMode;
  String get selectedCategory => _selectedCategory;

  void _loadFromStorage() {
    _recentFiles = _storageService.getRecentFiles();
    _fontSize = _storageService.getFontSize();
    _themeMode = _storageService.getThemeMode();
    notifyListeners();
  }

  // Navigation
  void navigate(String page) {
    _currentPage = page;
    _searchQuery = '';
    if (page != 'viewer') {
      _currentFile = null;
    }
    notifyListeners();
  }

  // Category Filtering Selection
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // File Handlers
  void toggleStarFile(DocumentFile file) {
    final idx = _recentFiles.indexWhere((f) => f.path == file.path);
    if (idx != -1) {
      _recentFiles[idx].isStarred = !_recentFiles[idx].isStarred;
      _storageService.saveRecentFiles(_recentFiles);
      notifyListeners();
    }
  }

  void addTagToFile(DocumentFile file, String tag) {
    final idx = _recentFiles.indexWhere((f) => f.path == file.path);
    if (idx != -1) {
      if (!_recentFiles[idx].tags.contains(tag)) {
        _recentFiles[idx].tags = List.from(_recentFiles[idx].tags)..add(tag);
        _storageService.saveRecentFiles(_recentFiles);
        notifyListeners();
      }
    }
  }

  void removeTagFromFile(DocumentFile file, String tag) {
    final idx = _recentFiles.indexWhere((f) => f.path == file.path);
    if (idx != -1) {
      if (_recentFiles[idx].tags.contains(tag)) {
        _recentFiles[idx].tags = List.from(_recentFiles[idx].tags)..remove(tag);
        _storageService.saveRecentFiles(_recentFiles);
        notifyListeners();
      }
    }
  }

  // File Handling
  void openFile(DocumentFile file) {
    _currentFile = file;
    _currentPage = 'viewer';
    _searchQuery = '';

    // Check if the file is already in recent list, preserving its star and tags!
    final existingIdx = _recentFiles.indexWhere((f) => f.path == file.path);
    bool isStarred = false;
    List<String> tags = [];
    if (existingIdx != -1) {
      isStarred = _recentFiles[existingIdx].isStarred;
      tags = _recentFiles[existingIdx].tags;
      _recentFiles.removeAt(existingIdx);
    }

    final updatedFile = DocumentFile(
      name: file.name,
      path: file.path,
      size: file.size,
      extension: file.extension,
      openedAt: DateTime.now(),
      isStarred: isStarred,
      tags: tags,
    );
    _recentFiles.insert(0, updatedFile);
    if (_recentFiles.length > 20) {
      _recentFiles = _recentFiles.sublist(0, 20);
    }
    _storageService.saveRecentFiles(_recentFiles);
    notifyListeners();
  }

  void closeFile() {
    _currentFile = null;
    _currentPage = 'home';
    notifyListeners();
  }

  // Search Query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Theme Toggler
  void toggleTheme() {
    _themeMode = _themeMode == 'dark' ? 'light' : 'dark';
    _storageService.setThemeMode(_themeMode);
    notifyListeners();
  }

  // Set Font Size
  void setFontSize(double size) {
    _fontSize = size;
    _storageService.setFontSize(size);
    notifyListeners();
  }

  // Clear Recents
  void clearRecentFiles() {
    _recentFiles = [];
    _storageService.clearRecentFiles();
    notifyListeners();
  }

  // Filtered recent files by search query AND active category tag
  List<DocumentFile> get filteredRecentFiles {
    List<DocumentFile> list = _recentFiles;

    // Filter by Category
    if (_selectedCategory == 'Starred') {
      list = list.where((f) => f.isStarred).toList();
    } else if (_selectedCategory != 'All') {
      list = list.where((f) => f.tags.contains(_selectedCategory)).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((file) => file.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }
}

