import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_core/core.dart';

// Import our files
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'providers/scanner_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/viewer_screen.dart';
import 'ui/screens/scanner_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/widgets/background_blobs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register Syncfusion license
  SyncfusionLicense.registerLicense('Mgo+DSMBaFt/QHRqVVhjVFpFdEBBXHxAd1p/VWJYdVt5flBPcDwsT3RfQF5jS35SdkVjXH9ceH1RRQ==');
  
  // Initialize SharedPreferences offline storage service
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final StorageService storageService = StorageService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppStateProvider(storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ScannerProvider(),
        ),
      ],
      child: const AnyViewerApp(),
    ),
  );
}

class AnyViewerApp extends StatelessWidget {
  const AnyViewerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.themeMode == 'dark';

    return MaterialApp(
      title: 'AnyViewer Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getThemeData(isDark, appState.fontSize),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({Key? key}) : super(key: key);

  Widget _renderScreen(String page) {
    switch (page) {
      case 'home':
        return const HomeScreen();
      case 'viewer':
        return const ViewerScreen();
      case 'scanner':
        return const ScannerScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isDark = appState.themeMode == 'dark';
    final page = appState.currentPage;
    final isViewerActive = page == 'viewer';

    return Scaffold(
      body: BackgroundBlobs(
        child: SafeArea(
          bottom: !isViewerActive, // Give viewer maximum real estate
          child: Column(
            children: [
              // Show a custom top title header bar ONLY if not viewing a file
              if (!isViewerActive)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 12.0, top: 12.0, bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Mini logo brand mark
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: AppTheme.brandGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AnyViewer',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      // Theme Switcher Button
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark ? Colors.amber : Colors.indigo,
                        ),
                        onPressed: appState.toggleTheme,
                        tooltip: 'Toggle Theme Mode',
                      ),
                    ],
                  ),
                ),
              
              // Master screen content panel with animated transitions
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.03),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _renderScreen(page),
                ),
              ),

              // Elegant Floating Glass Bottom Nav Bar placed inside the gradient flow!
              if (!isViewerActive)
                Padding(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 16.0, top: 4.0),
                  child: Container(
                    height: 64,
                    decoration: AppTheme.glassDecoration(
                      isDark: isDark,
                      borderRadius: 20,
                      borderOpacity: 0.1,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(
                          context: context,
                          pageId: 'home',
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          activeColor: Colors.blueAccent,
                          appState: appState,
                        ),
                        _buildNavItem(
                          context: context,
                          pageId: 'scanner',
                          icon: Icons.camera_outlined,
                          activeIcon: Icons.camera_rounded,
                          label: 'Scanner',
                          activeColor: Colors.deepPurpleAccent,
                          appState: appState,
                        ),
                        _buildNavItem(
                          context: context,
                          pageId: 'settings',
                          icon: Icons.settings_outlined,
                          activeIcon: Icons.settings_rounded,
                          label: 'Settings',
                          activeColor: Colors.tealAccent,
                          appState: appState,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String pageId,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required Color activeColor,
    required AppStateProvider appState,
  }) {
    final isActive = appState.currentPage == pageId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => appState.navigate(pageId),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive
                  ? activeColor
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 24,
            ),
            const SizedBox(height: 5),
            // Sleek dynamic glowing line below the active icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

