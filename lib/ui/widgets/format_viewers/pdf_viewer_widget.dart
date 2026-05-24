import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../../models/document_file.dart';

class PdfViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const PdfViewerWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  late PdfController _pdfController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  void _initPdf() {
    try {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.file.path),
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load PDF: $e';
      });
    }
  }

  @override
  void dispose() {
    if (!_isLoading && _errorMessage == null) {
      _pdfController.dispose();
    }
    super.dispose();
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

    return PdfPageNumber(
      controller: _pdfController,
      builder: (context, loadingState, page, pagesCount) {
        return Stack(
          children: [
            PdfView(
              controller: _pdfController,
              scrollDirection: Axis.vertical,
              physics: const BouncingScrollPhysics(),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Page $page of ${pagesCount ?? 0}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
