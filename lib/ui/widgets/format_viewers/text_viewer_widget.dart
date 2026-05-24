import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../models/document_file.dart';

class TextViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const TextViewerWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<TextViewerWidget> createState() => _TextViewerWidgetState();
}

class _TextViewerWidgetState extends State<TextViewerWidget> {
  String _content = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadText();
  }

  Future<void> _loadText() async {
    try {
      final file = File(widget.file.path);
      final text = await file.readAsString();
      setState(() {
        _content = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to read text file: $e';
      });
    }
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

    final isMarkdown = widget.file.extension.toLowerCase() == 'md';

    if (isMarkdown) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        child: Markdown(
          data: _content,
          selectable: true,
          physics: const BouncingScrollPhysics(),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: SelectableText(
        _content,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.4,
        ),
      ),
    );
  }
}
