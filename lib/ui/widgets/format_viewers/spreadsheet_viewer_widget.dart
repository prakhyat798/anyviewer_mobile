import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import '../../../models/document_file.dart';
import '../../../core/theme/app_theme.dart';

class SpreadsheetViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const SpreadsheetViewerWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<SpreadsheetViewerWidget> createState() => _SpreadsheetViewerWidgetState();
}

class _SpreadsheetViewerWidgetState extends State<SpreadsheetViewerWidget> {
  Map<String, List<List<dynamic>>> _sheets = {};
  List<String> _sheetNames = [];
  String? _selectedSheet;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpreadsheet();
  }

  Future<void> _loadSpreadsheet() async {
    try {
      final file = File(widget.file.path);
      final bytes = await file.readAsBytes();

      final cleanExt = widget.file.extension.toLowerCase().trim();
      final Map<String, List<List<dynamic>>> parsedSheets = {};

      if (cleanExt == 'csv') {
        final content = String.fromCharCodes(bytes);
        final List<List<dynamic>> rows = [];
        final lines = content.split('\n');
        for (var line in lines) {
          if (line.trim().isEmpty) continue;
          rows.add(line.split(',').map((cell) => cell.trim().replaceAll('"', '')).toList());
        }
        parsedSheets['Sheet1'] = rows;
      } else {
        final excel = Excel.decodeBytes(bytes);
        for (var tableKey in excel.tables.keys) {
          final sheet = excel.tables[tableKey]!;
          final List<List<dynamic>> rows = [];
          for (var row in sheet.rows) {
            rows.add(row.map((cell) => cell?.value ?? '').toList());
          }
          if (rows.isNotEmpty) {
            parsedSheets[tableKey] = rows;
          }
        }
      }

      if (parsedSheets.isEmpty) {
        throw Exception("No data could be read from this spreadsheet.");
      }

      setState(() {
        _sheets = parsedSheets;
        _sheetNames = parsedSheets.keys.toList();
        _selectedSheet = _sheetNames.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load spreadsheet: $e';
      });
    }
  }

  String _getColumnLabel(int index) {
    var label = '';
    var temp = index;
    while (temp >= 0) {
      label = String.fromCharCode((temp % 26) + 65) + label;
      temp = (temp ~/ 26) - 1;
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawRows = _sheets[_selectedSheet] ?? [];

    // Normalize all rows to the same column count to prevent Table widget crash
    final int maxCols = rawRows.fold<int>(0, (max, row) => row.length > max ? row.length : max);
    final activeRows = rawRows.map((row) {
      if (row.length < maxCols) {
        return [...row, ...List.filled(maxCols - row.length, '')];
      }
      return row;
    }).toList();

    const excelGreen = Color(0xFF217346);

    return Container(
      color: isDark ? Colors.black26 : const Color(0xFFF4F6F9),
      child: Column(
        children: [
          // Elegant top bar with excel info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.table_view_rounded, color: excelGreen, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: excelGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${activeRows.length} Rows × ${activeRows.isNotEmpty ? activeRows.first.length : 0} Cols',
                    style: const TextStyle(
                      color: excelGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Spreadsheet scrollable grid (horizontal & vertical)
          Expanded(
            child: activeRows.isEmpty
                ? const Center(
                    child: Text(
                      'This spreadsheet contains no row data.',
                      style: TextStyle(fontSize: 14, color: Colors.white30),
                    ),
                  )
                : InteractiveViewer(
                    constrained: false,
                    scaleEnabled: true,
                    minScale: 0.5,
                    maxScale: 2.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Table(
                            defaultColumnWidth: const FixedColumnWidth(100),
                            // Borders for standard excel cells grid
                            border: TableBorder.all(
                              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
                              width: 0.8,
                            ),
                            children: [
                              // Row 0: Column Letters Header (A, B, C...)
                              TableRow(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2E2E3A) : const Color(0xFFEFEFEF),
                                ),
                                children: [
                                  // Top-left corner cell (empty indicator column for row numbers)
                                  TableCell(
                                    verticalAlignment: TableCellVerticalAlignment.middle,
                                    child: Container(
                                      height: 36,
                                      color: excelGreen.withOpacity(0.1),
                                      child: const Center(
                                        child: Icon(Icons.grid_4x4_rounded, size: 12, color: excelGreen),
                                      ),
                                    ),
                                  ),
                                  // Remaining columns headers
                                  ...List.generate(activeRows.first.length, (colIdx) {
                                    return TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: Container(
                                        height: 36,
                                        child: Center(
                                          child: Text(
                                            _getColumnLabel(colIdx),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),

                              // Dynamic data rows with Row Index Headers (1, 2, 3...) on the left!
                              ...List.generate(activeRows.length, (rowIdx) {
                                final rowData = activeRows[rowIdx];
                                final isAlternate = rowIdx % 2 == 1;

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: isAlternate
                                        ? (isDark ? Colors.white10.withOpacity(0.03) : const Color(0xFFF9FBFD))
                                        : null,
                                  ),
                                  children: [
                                    // Row index header on the left
                                    TableCell(
                                      verticalAlignment: TableCellVerticalAlignment.middle,
                                      child: Container(
                                        height: 40,
                                        color: isDark ? const Color(0xFF2E2E3A) : const Color(0xFFEFEFEF),
                                        child: Center(
                                          child: Text(
                                            '${rowIdx + 1}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Cell data rendering
                                    ...List.generate(rowData.length, (colIdx) {
                                      final cellVal = rowData[colIdx]?.toString() ?? '';
                                      return TableCell(
                                        verticalAlignment: TableCellVerticalAlignment.middle,
                                        child: Container(
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                          child: Center(
                                            child: Text(
                                              cellVal,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Sheets Switcher Bar (Excel Tab Layout!)
          if (_sheetNames.length > 1)
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _sheetNames.length,
                itemBuilder: (context, index) {
                  final name = _sheetNames[index];
                  final isSelected = name == _selectedSheet;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSheet = name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? excelGreen.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? excelGreen : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tab,
                              size: 14,
                              color: isSelected ? excelGreen : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? excelGreen : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
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
}
