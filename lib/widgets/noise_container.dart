import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class NoiseContainer extends StatelessWidget {
  final Widget child;
  final double opacity;

  const NoiseContainer({
    super.key,
    required this.child,
    this.opacity = 0.02, // Very subtle noise
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NoisePainter(opacity: opacity),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random();

  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // We draw small points or rectangles to simulate noise.
    // Drawing pixel by pixel is too slow in Dart.
    // A better approach for performance is to use a shader or a small pattern.
    // Since we can't easily add assets, we'll try a simplified approach:
    // Draw a few thousand random small dots.
    
    // Optimization: Draw points in batch
    final List<Offset> points = [];
    final int density = (size.width * size.height * 0.05).toInt().clamp(0, 5000); // Limit points for performance

    for (int i = 0; i < density; i++) {
      points.add(Offset(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
      ));
    }

    paint.color = Colors.white.withOpacity(opacity);
    paint.strokeWidth = 1;
    canvas.drawPoints(ui.PointMode.points, points, paint);
    
    paint.color = Colors.black.withOpacity(opacity);
    canvas.drawPoints(ui.PointMode.points, points.map((e) => Offset(e.dx + 1, e.dy + 1)).toList(), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
