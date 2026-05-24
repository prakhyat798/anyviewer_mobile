import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/document_file.dart';

class ImageViewerWidget extends StatefulWidget {
  final DocumentFile file;

  const ImageViewerWidget({Key? key, required this.file}) : super(key: key);

  @override
  State<ImageViewerWidget> createState() => _ImageViewerWidgetState();
}

class _ImageViewerWidgetState extends State<ImageViewerWidget> {
  int _rotationQuarter = 0; // 0, 1, 2, 3 representing 0, 90, 180, 270 degrees

  void _rotate() {
    setState(() {
      _rotationQuarter = (_rotationQuarter + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.file.path);

    return Column(
      children: [
        // Subtle rotate button overlay
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.rotate_right),
                onPressed: _rotate,
                tooltip: 'Rotate Image',
              ),
            ],
          ),
        ),
        // Interactive Image Canvas
        Expanded(
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: RotatedBox(
                quarterTurns: _rotationQuarter,
                child: Image.file(
                  imageFile,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 8),
                          Text('Could not load image: $error'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
