import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/document_file.dart';
import '../../models/scan_page.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _showGallery = false;
  int _cameraIndex = 0; // 0 for back, 1 for front

  // Scanning animation sweep controller
  late AnimationController _sweepController;
  late Animation<double> _sweepAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();

    // Initialize scanner line sweeping animation
    _sweepController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _sweepAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sweepController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sweepController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    // App state changed (background/foreground)
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onCameraSelected(cameraController.description);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _onCameraSelected(_cameras[_cameraIndex]);
      }
    } catch (e) {
      debugPrint('Error finding cameras: $e');
    }
  }

  Future<void> _onCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _cameraController = cameraController;

    try {
      await cameraController.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isCameraInitialized = false;
      _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    });
    await _onCameraSelected(_cameras[_cameraIndex]);
  }

  Future<void> _captureFrame(ScannerProvider scanner) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _mockCapture(scanner); // Fallback mock capture for emulator
      return;
    }

    if (controller.value.isTakingPicture) return;

    try {
      final XFile rawImageFile = await controller.takePicture();
      scanner.addScan(rawImageFile.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
      _mockCapture(scanner);
    }
  }

  void _mockCapture(ScannerProvider scanner) {
    // Scaffold feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera unavailable. Triggering mock document template...'),
        duration: Duration(milliseconds: 1500),
      ),
    );
    // Write a mock image or select a placeholder
    // We can select gallery image instead or load dummy path.
    _importFromGallery(scanner);
  }

  Future<void> _importFromGallery(ScannerProvider scanner) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        scanner.importScanFromGallery(image.path);
      }
    } catch (e) {
      debugPrint('Gallery import error: $e');
    }
  }

  Future<void> _exportCompiledPdf(ScannerProvider scanner, AppStateProvider appState) async {
    // Show spinner modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Compiling PDF offline...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    final path = await scanner.compileToPdf();
    Navigator.of(context).pop(); // Dismiss spinner

    if (path != null) {
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF Compiled successfully: ${path.split('/').last}'),
          backgroundColor: Colors.greenAccent,
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.black,
            onPressed: () {
              Share.shareXFiles([XFile(path)], text: 'Compiled Scan PDF');
            },
          ),
        ),
      );

      // Save PDF to recents
      final file = File(path);
      final size = await file.length();
      final docFile = DocumentFile(
        name: path.split('/').last,
        path: path,
        size: size,
        extension: 'pdf',
        openedAt: DateTime.now(),
      );
      appState.openFile(docFile);
      scanner.clearScans();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to compile PDF document.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanner = Provider.of<ScannerProvider>(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final fontScale = appState.fontSize / 16.0;

    // VIEW 1: Active Preview / Configuration Mode (Image captured, selecting filters)
    if (scanner.activeScan != null) {
      final activeScan = scanner.activeScan!;
      return Column(
        children: [
          // Header Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: scanner.cancelActiveScan,
                    tooltip: 'Retake / Back',
                  ),
                  Text(
                    'Preview Scan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * fontScale),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: scanner.confirmActiveScan,
                    tooltip: 'Save Scan Page',
                  ),
                ],
              ),
            ),
          ),

          // Render captured image with ColorFilter applied
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Container(
                decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: InteractiveViewer(
                    child: ColorFiltered(
                      colorFilter: scanner.getColorFilter(activeScan.filter),
                      child: Image.file(
                        File(activeScan.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filters Horizontal Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildFilterOption('original', 'Original', activeScan, scanner),
                  _buildFilterOption('grayscale', 'Grayscale', activeScan, scanner),
                  _buildFilterOption('highcontrast', 'High Contrast', activeScan, scanner),
                  _buildFilterOption('bw', 'Black & White', activeScan, scanner),
                ],
              ),
            ),
          ),

          // Confirmation Buttons Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: scanner.cancelActiveScan,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Retake', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: scanner.confirmActiveScan,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Save Page'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // VIEW 2: Scan Gallery View (reviewing multiple scans captured)
    if (_showGallery) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showGallery = false),
                    tooltip: 'Back to Camera',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan Gallery (${scanner.scans.length} pages)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * fontScale),
                  ),
                  const Spacer(),
                  if (scanner.scans.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () => _exportCompiledPdf(scanner, appState),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Export PDF', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Grid View
          Expanded(
            child: scanner.scans.isEmpty
                ? const Center(child: Text('No scans captured yet.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(20.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: scanner.scans.length,
                    itemBuilder: (context, index) {
                      final scan = scanner.scans[index];
                      return Container(
                        decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColorFiltered(
                                  colorFilter: scanner.getColorFilter(scan.filter),
                                  child: Image.file(
                                    File(scan.imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Page Number Badge
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Page ${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              // Delete Button overlay
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black54,
                                    hoverColor: Colors.redAccent,
                                  ),
                                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
                                  onPressed: () => scanner.removeScan(scan.id),
                                  tooltip: 'Delete page',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // VIEW 3: Camera Viewfinder View (Capturing pages)
    return Column(
      children: [
        // Camera Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => appState.navigate('home'),
                  tooltip: 'Close Scanner',
                ),
                const SizedBox(width: 8),
                Text(
                  'Document Scanner',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15 * fontScale),
                ),
                const Spacer(),
                if (scanner.scans.isNotEmpty)
                  IconButton.filledTonal(
                    icon: Badge(
                      label: Text('${scanner.scans.length}'),
                      child: const Icon(Icons.collections),
                    ),
                    onPressed: () => setState(() => _showGallery = true),
                    tooltip: 'Show Gallery',
                  ),
              ],
            ),
          ),
        ),

        // Live Viewfinder / Mock Overlay
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Container(
              decoration: AppTheme.glassDecoration(isDark: isDark, borderRadius: 24, borderOpacity: 0.15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Camera feed
                    Positioned.fill(
                      child: _isCameraInitialized && _cameraController != null
                          ? CameraPreview(_cameraController!)
                          : Container(
                              color: Colors.black,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt, size: 64, color: Colors.white24),
                                    const SizedBox(height: 16),
                                    const Text('Live Viewfinder Ready', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 40.0),
                                      child: Text(
                                        'No camera detected. You can import documents directly from your photo library.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.white30, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    FilledButton.icon(
                                      onPressed: () => _importFromGallery(scanner),
                                      icon: const Icon(Icons.photo_library),
                                      label: const Text('Import from Photos'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),

                    // Neon Scanning Guides Frame Overlay
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.darkPrimary.withOpacity(0.4), width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              // Neon Corner indicators
                              _buildCorner(Alignment.topLeft, 12, 0, 0, 12),
                              _buildCorner(Alignment.topRight, 0, 12, 0, 12),
                              _buildCorner(Alignment.bottomLeft, 12, 0, 12, 0),
                              _buildCorner(Alignment.bottomRight, 0, 12, 12, 0),
                              
                              // Sweeping Scanning Animation Line
                              AnimatedBuilder(
                                animation: _sweepAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: (MediaQuery.of(context).size.height * 0.5) * _sweepAnimation.value,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.darkPrimary.withOpacity(0.8),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                        color: AppTheme.darkPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Custom Viewfinder Capture Controls Bar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Import Image
              IconButton.filledTonal(
                icon: const Icon(Icons.photo_library),
                onPressed: () => _importFromGallery(scanner),
                tooltip: 'Import from Gallery',
              ),
              // Capture Shutter Button
              GestureDetector(
                onTap: () => _captureFrame(scanner),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.black87, size: 28),
                    ),
                  ),
                ),
              ),
              // Switch Front/Back lenses
              IconButton.filledTonal(
                icon: const Icon(Icons.switch_camera),
                onPressed: _cameras.length > 1 ? _switchCamera : null,
                tooltip: 'Switch Camera',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(Alignment align, double tl, double tr, double bl, double br) {
    return Align(
      alignment: align,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppTheme.darkPrimary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(tl),
            topRight: Radius.circular(tr),
            bottomLeft: Radius.circular(bl),
            bottomRight: Radius.circular(br),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String id, String name, ScanPage activeScan, ScannerProvider scanner) {
    final isSelected = activeScan.filter == id;
    final file = File(activeScan.imagePath);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: GestureDetector(
        onTap: () => scanner.updateActiveScanFilter(id),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppTheme.darkPrimary : Colors.white24,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColorFiltered(
                  colorFilter: scanner.getColorFilter(id),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.darkPrimary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


