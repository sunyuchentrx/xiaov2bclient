import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vpn_ui_demo/pages/welcome_page.dart';
import 'package:vpn_ui_demo/theme/app_theme.dart';
import 'package:vpn_ui_demo/providers/language_provider.dart';
import 'package:vpn_ui_demo/widgets/noise_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(375, 700),
      minimumSize: Size(375, 700),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: '春秋VPN',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const VPNApp(),
    ),
  );
}

class VPNApp extends StatelessWidget {
  const VPNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '春秋VPN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return NoiseContainer(child: child!); // Apply noise globally
      },
      home: const WelcomePage(),
    );
  }
}
