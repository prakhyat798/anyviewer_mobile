import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import '../../../models/document_file.dart';
import '../../../core/theme/app_theme.dart';

class DocxParagraph {
  final List<DocxRun> runs;
  final bool isHeading;
  final int headingLevel;
  final String alignment; // left, center, right, justify

  DocxParagraph({
    required this.runs,
    this.isHeading = false,
    this.headingLevel = 0,
    this.alignment = 'left',
  });
}

class DocxRun {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final double? fontSize;
  final Color? color;

  DocxRun({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize,
    this.color,
  });
}

class DocxViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const DocxViewerWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<DocxViewerWidget> createState() => _DocxViewerWidgetState();
}

class _DocxViewerWidgetState extends State<DocxViewerWidget> {
  List<DocxParagraph> _paragraphs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _parseDocx();
  }

  Future<void> _parseDocx() async {
    try {
      final file = File(widget.file.path);
      final bytes = await file.readAsBytes();

      // Decode ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find word/document.xml
      final docXmlFile = archive.findFile('word/document.xml');
      if (docXmlFile == null) {
        throw Exception("Invalid DOCX format. Could not locate document body.");
      }

      final docXmlContent = docXmlFile.content;
      String xmlString;
      try {
        xmlString = String.fromCharCodes(docXmlContent).length == 1
            ? String.fromCharCodes(docXmlContent)
            : systemDecode(docXmlContent);
      } catch (_) {
        xmlString = String.fromCharCodes(docXmlContent);
      }

      final document = xml.XmlDocument.parse(xmlString);

      // Extract all paragraphs (<w:p>)
      final pElements = document.findAllElements('w:p');
      final List<DocxParagraph> list = [];

      for (var p in pElements) {
        final List<DocxRun> runs = [];
        
        // Parse paragraph properties (<w:pPr>)
        final pPr = p.findElements('w:pPr').firstOrNull;
        bool isHeading = false;
        int headingLevel = 0;
        String alignment = 'left';

        if (pPr != null) {
          final pStyle = pPr.findElements('w:pStyle').firstOrNull;
          if (pStyle != null) {
            final styleVal = pStyle.getAttribute('w:val') ?? '';
            if (styleVal.toLowerCase().contains('heading')) {
              isHeading = true;
              headingLevel = int.tryParse(RegExp(r'\d+').stringMatch(styleVal) ?? '1') ?? 1;
            }
          }
          
          final jc = pPr.findElements('w:jc').firstOrNull;
          if (jc != null) {
            alignment = jc.getAttribute('w:val') ?? 'left';
          }
        }

        // Parse runs (<w:r>)
        final rElements = p.findElements('w:r');
        for (var r in rElements) {
          final rPr = r.findElements('w:rPr').firstOrNull;
          bool isBold = false;
          bool isItalic = false;
          bool isUnderline = false;
          double? fontSize;
          Color? color;

          if (rPr != null) {
            isBold = rPr.findElements('w:b').isNotEmpty;
            isItalic = rPr.findElements('w:i').isNotEmpty;
            isUnderline = rPr.findElements('w:u').isNotEmpty;
            
            final sz = rPr.findElements('w:sz').firstOrNull;
            if (sz != null) {
              final val = double.tryParse(sz.getAttribute('w:val') ?? '');
              if (val != null) {
                fontSize = val / 2.0; // half-points to pt
              }
            }

            final colorEl = rPr.findElements('w:color').firstOrNull;
            if (colorEl != null) {
              final val = colorEl.getAttribute('w:val') ?? '';
              if (val.length == 6) {
                color = Color(int.parse('FF$val', radix: 16));
              }
            }
          }

          final tElements = r.findElements('w:t');
          final text = tElements.map((e) => e.innerText).join('');
          if (text.isNotEmpty) {
            runs.add(DocxRun(
              text: text,
              isBold: isBold,
              isItalic: isItalic,
              isUnderline: isUnderline,
              fontSize: fontSize,
              color: color,
            ));
          }
        }

        if (runs.isNotEmpty) {
          list.add(DocxParagraph(
            runs: runs,
            isHeading: isHeading,
            headingLevel: headingLevel,
            alignment: alignment,
          ));
        } else if (p.findAllElements('w:br').isNotEmpty) {
          list.add(DocxParagraph(
            runs: [DocxRun(text: '\n')],
            alignment: alignment,
          ));
        }
      }

      setState(() {
        _paragraphs = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to parse DOCX: $e';
      });
    }
  }

  String systemDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  TextAlign _getTextAlign(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'both':
      case 'justify':
        return TextAlign.justify;
      case 'left':
      default:
        return TextAlign.left;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? Colors.black26 : const Color(0xFFF4F6F9),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _paragraphs.map((p) {
                  if (p.runs.length == 1 && p.runs.first.text == '\n') {
                    return const SizedBox(height: 18);
                  }

                  // Build text spans for runs
                  final List<InlineSpan> spans = [];
                  for (var r in p.runs) {
                    double size = r.fontSize ?? (p.isHeading ? (p.headingLevel == 1 ? 22 : 18) : 15);
                    Color runColor = r.color ?? (isDark ? Colors.white.withOpacity(0.9) : Colors.black87);

                    spans.add(TextSpan(
                      text: r.text,
                      style: TextStyle(
                        fontWeight: r.isBold || p.isHeading ? FontWeight.bold : FontWeight.normal,
                        fontStyle: r.isItalic ? FontStyle.italic : FontStyle.normal,
                        decoration: r.isUnderline ? TextDecoration.underline : TextDecoration.none,
                        fontSize: size,
                        color: runColor,
                        fontFamily: p.isHeading ? 'Outfit' : 'Inter',
                      ),
                    ));
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: p.isHeading ? 16.0 : 10.0,
                      top: p.isHeading ? 12.0 : 0.0,
                    ),
                    child: RichText(
                      textAlign: _getTextAlign(p.alignment),
                      text: TextSpan(
                        children: spans,
                        style: TextStyle(
                          height: p.isHeading ? 1.3 : 1.6,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
