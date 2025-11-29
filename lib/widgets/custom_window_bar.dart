import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../theme/app_theme.dart';

class CustomWindowBar extends StatelessWidget {
  final Widget child;
  final bool showControls;

  const CustomWindowBar({
    super.key,
    required this.child,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 32,
          color: AppTheme.backgroundColor, // Match app background
          child: Row(
            children: [
              // Window Controls (MacOS Style)
              if (showControls)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Row(
                    children: [
                      _buildWindowButton(
                        color: const Color(0xFFFF5F57), // Red (Close)
                        onTap: () => windowManager.close(),
                      ),
                      const SizedBox(width: 8),
                      _buildWindowButton(
                        color: const Color(0xFFFFBD2E), // Yellow (Minimize)
                        onTap: () => windowManager.minimize(),
                      ),
                      const SizedBox(width: 8),
                      _buildWindowButton(
                        color: const Color(0xFF28C93F), // Green (Maximize)
                        onTap: () async {
                          if (await windowManager.isMaximized()) {
                            windowManager.unmaximize();
                          } else {
                            windowManager.maximize();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              // Drag Area
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) {
                    windowManager.startDragging();
                  },
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildWindowButton({required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
