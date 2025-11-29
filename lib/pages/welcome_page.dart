import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_page.dart';
import 'register_page.dart';
import '../widgets/custom_window_bar.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initConfig();
  }

  String? _appDescription;

  Future<void> _initConfig() async {
    final configService = ConfigService();
    await configService.init();
    
    // Fetch guest config for app description
    if (configService.currentApiUrl != null) {
      try {
        final guestConfig = await ApiService().getWebsiteConfig();
        if (guestConfig != null && guestConfig['app_description'] != null) {
          _appDescription = guestConfig['app_description'];
        }
      } catch (e) {
        print('Failed to fetch guest config: $e');
      }
    }
    
    if (mounted) {
      // Check for auto-login before stopping loading
      await _checkLoginStatus();
      
      setState(() => _isLoading = false);
      _checkUpdate();
    }
  }

  Future<void> _checkLoginStatus() async {
    final token = await ApiService().getToken();
    if (token != null && token.isNotEmpty) {
      // Validate token and fetch latest subscription data
      final subData = await ApiService().getSubscribe();
      if (subData != null && mounted) {
        // Token is valid and data fetched, navigate to Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Token invalid or expired, clear it
        await ApiService().logout();
      }
    }
  }

  Future<void> _checkUpdate() async {
    final downloadUrl = await ConfigService().checkUpdate();
    if (downloadUrl != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('New Version Available', style: TextStyle(color: Colors.white)),
          content: Text(
            ConfigService().appConfig?.updateNotes ?? 'Please update to the latest version.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              child: const Text('Update Now'),
              onPressed: () {
                launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    if (_isLoading) {
      return CustomWindowBar(
        child: Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    return CustomWindowBar(
      child: Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.language, color: Colors.white),
                onPressed: () => _showLanguageDialog(context, lang, Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Illustration / Logo
                  // Illustration / Logo
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Texts
                  Text(
                    '春秋VPN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (_appDescription != null && _appDescription!.isNotEmpty)
                        ? _appDescription!
                        : '错误代码404',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(flex: 3),
                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginPage()),
                        );
                      },
                      child: Text(
                        lang.getText('login'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        lang.getText('create_account'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider lang, Color textColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(lang.getText('language'), style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: TextStyle(color: textColor)),
              leading: Radio<String>(
                value: 'en',
                groupValue: lang.currentLocale.languageCode,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  lang.changeLanguage(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                lang.changeLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('中文', style: TextStyle(color: textColor)),
              leading: Radio<String>(
                value: 'zh',
                groupValue: lang.currentLocale.languageCode,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) {
                  lang.changeLanguage(const Locale('zh'));
                  Navigator.pop(context);
                },
              ),
              onTap: () {
                lang.changeLanguage(const Locale('zh'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
