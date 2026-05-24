import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/document_file.dart';

class PptxViewerWidget extends StatefulWidget {
  final DocumentFile file;
  const PptxViewerWidget({super.key, required this.file});

  @override
  State<PptxViewerWidget> createState() => _PptxViewerWidgetState();
}

class _PptxViewerWidgetState extends State<PptxViewerWidget> {
  late final WebViewController _controller;
  bool _isUploading = true;
  bool _isLoadingWebView = false;
  String? _errorMessage;
  String? _publicUrl;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    if (widget.file.path.startsWith('http')) {
      setState(() {
        _publicUrl = widget.file.path;
        _isUploading = false;
        _isLoadingWebView = true;
      });
      _initWebView();
      return;
    }
    await _uploadToProxy();
  }

  Future<void> _uploadToProxy() async {
    try {
      setState(() {
        _isUploading = true;
        _errorMessage = null;
      });

      // Try file.io with the correct trailing slash to avoid 301 redirect
      const primaryUrl = 'https://file.io/';
      
      final request = http.MultipartRequest('POST', Uri.parse(primaryUrl));
      // Add expiry for 1 hour
      request.fields['expires'] = '1h';
      request.files.add(await http.MultipartFile.fromPath('file', widget.file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final link = data['link'] as String;

        if (mounted) {
          setState(() {
            _publicUrl = link;
            _isUploading = false;
            _isLoadingWebView = true;
          });
          _initWebView();
        }
      } else if (response.statusCode == 301 || response.statusCode == 302) {
        // Handle redirect manually if necessary, or try alternative
        final newLocation = response.headers['location'];
        if (newLocation != null) {
           await _uploadToUrl(newLocation);
        } else {
           await _uploadToFallback();
        }
      } else {
        await _uploadToFallback();
      }
    } catch (e) {
      await _uploadToFallback();
    }
  }

  Future<void> _uploadToUrl(String url) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('file', widget.file.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final link = data['link'] as String;
        if (mounted) {
          setState(() {
            _publicUrl = link;
            _isUploading = false;
            _isLoadingWebView = true;
          });
          _initWebView();
        }
      } else {
        await _uploadToFallback();
      }
    } catch (_) {
      await _uploadToFallback();
    }
  }

  Future<void> _uploadToFallback() async {
    try {
      // Use tmpfiles.org as a highly reliable fallback
      final request = http.MultipartRequest('POST', Uri.parse('https://tmpfiles.org/api/v1/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', widget.file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // tmpfiles.org returns "url": "https://tmpfiles.org/XXXX/file.pptx"
        // Google Docs Viewer needs the direct download link: "https://tmpfiles.org/dl/XXXX/file.pptx"
        String rawUrl = data['data']['url'] as String;
        String directLink = rawUrl.replaceFirst('https://tmpfiles.org/', 'https://tmpfiles.org/dl/');

        if (mounted) {
          setState(() {
            _publicUrl = directLink;
            _isUploading = false;
            _isLoadingWebView = true;
          });
          _initWebView();
        }
      } else {
        throw Exception('Secondary proxy also failed.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Unable to render presentation. Please check your internet connection.';
        });
      }
    }
  }

  void _initWebView() {
    if (_publicUrl == null) return;

    final encodedUrl = Uri.encodeComponent(_publicUrl!);
    final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100 && mounted) setState(() => _isLoadingWebView = false);
          },
          onPageStarted: (String url) {
            if (mounted) setState(() => _isLoadingWebView = true);
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingWebView = false);
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoadingWebView = false;
                _errorMessage = 'Renderer Error: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          if (_publicUrl != null) WebViewWidget(controller: _controller),
          
          if (_isUploading)
            _buildStatusOverlay('Preparing high-fidelity slides...', 'Using Google rendering engine'),
          
          if (_isLoadingWebView && !_isUploading)
            _buildStatusOverlay('Rendering...', 'Almost there'),

          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: Colors.grey, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _initFlow,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB7472A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB7472A)),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
