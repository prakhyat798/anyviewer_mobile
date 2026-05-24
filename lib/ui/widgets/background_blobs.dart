import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';


class BackgroundBlobs extends StatefulWidget {
  final Widget child;

  const BackgroundBlobs({Key? key, required this.child}) : super(key: key);

  @override
  State<BackgroundBlobs> createState() => _BackgroundBlobsState();
}

class _BackgroundBlobsState extends State<BackgroundBlobs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Subtle looping animation for the visual blobs
    _controller = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background Base Gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? AppTheme.darkBackgroundGradient
                : AppTheme.lightBackgroundGradient,
          ),
        ),

        // Animated Blobs (only in Dark Mode for heavy glowing effect, or subtle in Light Mode)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value = _controller.value * 2 * math.pi;

            // Blob 1 coordinates (circular path)
            final blob1X = size.width * 0.2 + (50 * math.sin(value));
            final blob1Y = size.height * 0.2 + (50 * math.cos(value));

            // Blob 2 coordinates
            final blob2X = size.width * 0.7 + (60 * math.cos(value + 1.0));
            final blob2Y = size.height * 0.6 + (60 * math.sin(value + 1.0));

            // Blob 3 coordinates
            final blob3X = size.width * 0.4 + (40 * math.sin(value + 2.0));
            final blob3Y = size.height * 0.8 + (40 * math.cos(value + 2.0));

            return Stack(
              children: [
                // Blob 1: Glowing Violet
                Positioned(
                  left: blob1X - 150,
                  top: blob1Y - 150,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkPrimary.withOpacity(isDark ? 0.15 : 0.06),
                    ),
                  ),
                ),
                // Blob 2: Glowing Ocean Blue
                Positioned(
                  left: blob2X - 200,
                  top: blob2Y - 200,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.darkSecondary.withOpacity(isDark ? 0.15 : 0.06),
                    ),
                  ),
                ),
                // Blob 3: Glowing Rose/Pink accent
                Positioned(
                  left: blob3X - 120,
                  top: blob3Y - 120,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEC4899).withOpacity(isDark ? 0.08 : 0.03),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Backdrop Filter to blur the blobs beautifully
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.expand(),
          ),
        ),

        // Child Content
        Positioned.fill(
          child: widget.child,
        ),
      ],
    );
  }
}


