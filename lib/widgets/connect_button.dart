import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class ConnectButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isConnected;

  const ConnectButton({
    super.key,
    required this.onPressed,
    required this.isConnected,
  });

  @override
  State<ConnectButton> createState() => _ConnectButtonState();
}

class _ConnectButtonState extends State<ConnectButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return GestureDetector(
      onTap: widget.onPressed,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple Effect
          if (widget.isConnected)
            AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Container(
                  width: 160 + (_rippleAnimation.value * 60),
                  height: 160 + (_rippleAnimation.value * 60),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor.withOpacity(0.15 * (1 - _rippleAnimation.value)),
                  ),
                );
              },
            ),
          // Main Button
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isConnected ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isConnected
                          ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)]
                          : [AppTheme.surfaceColor, AppTheme.surfaceColor.withOpacity(0.8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isConnected
                            ? AppTheme.primaryColor.withOpacity(0.4)
                            : Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.power_settings_new_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.isConnected ? lang.getText('stop') : lang.getText('start'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
