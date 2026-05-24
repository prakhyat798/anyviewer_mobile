import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/scan_page.dart';

class ScannerProvider with ChangeNotifier {
  List<ScanPage> _scans = [];
  ScanPage? _activeScan;

  List<ScanPage> get scans => _scans;
  ScanPage? get activeScan => _activeScan;

  void addScan(String path) {
    final newScan = ScanPage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: path,
      filter: 'original',
      timestamp: DateTime.now(),
    );
    _scans.add(newScan);
    _activeScan = newScan;
    notifyListeners();
  }

  void importScanFromGallery(String path) {
    final newScan = ScanPage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: path,
      filter: 'original',
      timestamp: DateTime.now(),
    );
    _scans.add(newScan);
    _activeScan = newScan;
    notifyListeners();
  }

  void selectActiveScan(ScanPage scan) {
    _activeScan = scan;
    notifyListeners();
  }

  void updateActiveScanFilter(String filter) {
    if (_activeScan != null) {
      _activeScan!.filter = filter;
      notifyListeners();
    }
  }

  void removeScan(String id) {
    _scans.removeWhere((s) => s.id == id);
    if (_activeScan?.id == id) {
      _activeScan = _scans.isNotEmpty ? _scans.last : null;
    }
    notifyListeners();
  }

  void clearScans() {
    _scans = [];
    _activeScan = null;
    notifyListeners();
  }

  void cancelActiveScan() {
    if (_activeScan != null) {
      // If we didn't confirm saving it, let's remove it if it was the last page added
      _scans.removeWhere((s) => s.id == _activeScan!.id);
      _activeScan = null;
      notifyListeners();
    }
  }

  void confirmActiveScan() {
    _activeScan = null; // Unsets active scan so viewfinder can resume or gallery show
    notifyListeners();
  }

  // Visual filter logic to render images on screen
  ColorFilter getColorFilter(String filterName) {
    switch (filterName) {
      case 'grayscale':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case 'highcontrast':
        return const ColorFilter.matrix(<double>[
          1.8, 0,   0,   0, -25.5,
          0,   1.8, 0,   0, -25.5,
          0,   0,   1.8, 0, -25.5,
          0,   0,   0,   1, 0,
        ]);
      case 'bw':
        return const ColorFilter.matrix(<double>[
          4.0, 4.0, 4.0, 0, -450.0,
          4.0, 4.0, 4.0, 0, -450.0,
          4.0, 4.0, 4.0, 0, -450.0,
          0,   0,   0,   1, 0,
        ]);
      default:
        return const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  // ─── Direct High Fidelity Offline PDF Compiler ───
  Future<String?> compileToPdf() async {
    if (_scans.isEmpty) return null;

    try {
      final pdf = pw.Document();

      for (var scan in _scans) {
        final file = File(scan.imagePath);
        if (!await file.exists()) continue;

        final rawBytes = await file.readAsBytes();

        // If the scan filter is not original, we process the pixels before adding to the PDF
        List<int> finalImageBytes;
        if (scan.filter != 'original') {
          finalImageBytes = await _applyFilterToImageBytes(rawBytes, scan.filter);
        } else {
          finalImageBytes = rawBytes;
        }

        final pdfImage = pw.MemoryImage(finalImageBytes as Uint8List);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(10),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      final outputDirectory = await getApplicationDocumentsDirectory();
      final outputPath = '${outputDirectory.path}/AnyViewer_Scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      debugPrint('Error compiling PDF: $e');
      return null;
    }
  }

  // Renders the image onto a Flutter canvas with the selected filter,
  // then encodes it as a high-quality PNG for clean PDF compilation.
  Future<List<int>> _applyFilterToImageBytes(List<int> bytes, String filterName) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes as Uint8List);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));
      final paint = Paint()..colorFilter = getColorFilter(filterName);

      canvas.drawImage(image, Offset.zero, paint);
      final picture = recorder.endRecording();
      final filteredImage = await picture.toImage(image.width, image.height);

      final byteData = await filteredImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Error applying filter to bytes: $e');
    }
    return bytes; // Fallback to raw bytes
  }
}
