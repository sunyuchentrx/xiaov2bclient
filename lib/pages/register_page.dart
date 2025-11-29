import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_text_field.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import 'home_page.dart';
import 'login_page.dart';
import '../widgets/custom_window_bar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _emailCodeController = TextEditingController();

  bool _isLoading = false;
  bool _isConfigLoading = true;
  
  // Config flags
  bool _isEmailVerify = false;
  bool _isInviteCode = false;
  
  // Email Suffix
  List<String> _emailSuffixes = [];
  String? _selectedSuffix;
  
  // Timer for email code
  int _countdown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await ApiService().getWebsiteConfig();
    print('Register Config: $config'); // Debug print
    if (mounted) {
      setState(() {
        _isConfigLoading = false;
        if (config != null) {
          _isEmailVerify = config['is_email_verify'] == 1 || config['is_email_verify'] == true;
          _isInviteCode = config['is_invite_code'] == 1 || config['is_invite_code'] == true;
          
          if (config['email_whitelist_suffix'] != null && config['email_whitelist_suffix'] is List) {
             final rawSuffixes = List<String>.from(config['email_whitelist_suffix']);
             _emailSuffixes = rawSuffixes.map((s) => s.startsWith('@') ? s : '@$s').toList();
             print('Email Suffixes: $_emailSuffixes'); // Debug print
             if (_emailSuffixes.isNotEmpty) {
               _selectedSuffix = _emailSuffixes.first;
             }
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _inviteCodeController.dispose();
    _emailCodeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String _generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _showCaptchaDialog() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email first')),
      );
      return;
    }

    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final captcha = _generateCaptcha();
    final captchaController = TextEditingController();

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(lang.getText('security_check'), style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                captcha,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captchaController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: lang.getText('enter_captcha'),
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.getText('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (captchaController.text.toUpperCase() == captcha) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.getText('incorrect_code'))),
                );
              }
            },
            child: Text(lang.getText('confirm'), style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );

    if (verified == true) {
      _sendEmailCode();
    }
  }
  
  String get _fullEmail {
    if (_emailSuffixes.isNotEmpty && _selectedSuffix != null) {
      return '${_emailController.text}$_selectedSuffix';
    }
    return _emailController.text;
  }

  Future<void> _sendEmailCode() async {
    setState(() => _isLoading = true);
    final error = await ApiService().sendEmailVerify(_fullEmail);
    setState(() => _isLoading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code sent successfully')),
      );
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('password_mismatch'))),
      );
      return;
    }
    if (_isEmailVerify && _emailCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final error = await ApiService().register(
      _fullEmail,
      _passwordController.text,
      inviteCode: _inviteCodeController.text.isNotEmpty ? _inviteCodeController.text : null,
      emailCode: _isEmailVerify ? _emailCodeController.text : null,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return CustomWindowBar(
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isConfigLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      lang.getText('create_account_title'),
                      style: Theme.of(context).textTheme.displayLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lang.getText('sign_up_subtitle'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 40),
                    
                    // Email Input
                    if (_emailSuffixes.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.inputFillColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Icon(Icons.email_outlined, color: AppTheme.textSecondaryColor),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: lang.getText('email'),
                                  hintStyle: const TextStyle(color: AppTheme.textSecondaryColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  isDense: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'@')),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.only(right: 8),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedSuffix,
                                  dropdownColor: AppTheme.inputFillColor,
                                  borderRadius: BorderRadius.circular(12),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
                                  isDense: true,
                                  menuMaxHeight: 300,
                                  alignment: AlignmentDirectional.centerEnd,
                                  items: _emailSuffixes.map((String suffix) {
                                    return DropdownMenuItem<String>(
                                      value: suffix,
                                      child: Text(suffix),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedSuffix = newValue;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      CustomTextField(
                        controller: _emailController,
                        hintText: lang.getText('email'),
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Email Verify Code (if enabled)
                    if (_isEmailVerify) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _emailCodeController,
                              hintText: lang.getText('email_code'),
                              icon: Icons.verified_user_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 50,
                            width: 120,
                            child: ElevatedButton(
                              onPressed: _countdown > 0 || _isLoading ? null : _showCaptchaDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.surfaceColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                _countdown > 0 ? '${_countdown}s' : lang.getText('send_code'),
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Password
                    CustomTextField(
                      controller: _passwordController,
                      hintText: lang.getText('password'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    
                    // Confirm Password
                    CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: lang.getText('confirm_password'),
                      icon: Icons.lock_outline,
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),

                    // Invite Code
                    CustomTextField(
                      controller: _inviteCodeController,
                      hintText: lang.getText('invite_code'),
                      icon: Icons.card_giftcard,
                    ),
                    
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                lang.getText('sign_up'),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lang.getText('already_have_account'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          child: Text(
                            lang.getText('login'),
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
