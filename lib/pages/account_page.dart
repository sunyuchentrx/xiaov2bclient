
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_window_bar.dart';
import '../widgets/custom_text_field.dart';
import 'package:vpn_ui_demo/theme/app_theme.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _remindExpire = false;
  bool _remindTraffic = false;
  bool _isLoading = false;
  bool _isSavingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final userInfo = await ApiService().getUserInfo();
      if (userInfo != null) {
        setState(() {
          _remindExpire = (userInfo['remind_expire'] as int?) == 1;
          _remindTraffic = (userInfo['remind_traffic'] as int?) == 1;
        });
      }
    } catch (e) {
      // Handle error silently or show snackbar
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() => _isSavingSettings = true);
    
    // Optimistic update
    final oldValue = key == 'remind_expire' ? !_remindExpire : !_remindTraffic;
    setState(() {
      if (key == 'remind_expire') _remindExpire = value;
      else _remindTraffic = value;
    });

    final success = await ApiService().updateUserInfo({
      'remind_expire': _remindExpire ? 1 : 0,
      'remind_traffic': _remindTraffic ? 1 : 0,
    });

    if (!success) {
      // Revert on failure
      if (mounted) {
        setState(() {
          if (key == 'remind_expire') _remindExpire = oldValue;
          else _remindTraffic = oldValue;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update settings')),
        );
      }
    }

    if (mounted) setState(() => _isSavingSettings = false);
  }

  Future<void> _changePassword() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.getText('password_mismatch'))),
      );
      return;
    }

    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);
    final error = await ApiService().changePassword(
      _oldPasswordController.text,
      _newPasswordController.text,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.getText('password_changed'))),
        );
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.getText('my_account'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(lang.getText('settings')),
            SwitchListTile(
              title: Text(lang.getText('remind_expire'), style: const TextStyle(color: Colors.white)),
              value: _remindExpire,
              onChanged: (val) => _updateSetting('remind_expire', val),
              activeColor: AppTheme.primaryColor,
            ),
            SwitchListTile(
              title: Text(lang.getText('remind_traffic'), style: const TextStyle(color: Colors.white)),
              value: _remindTraffic,
              onChanged: (val) => _updateSetting('remind_traffic', val),
              activeColor: AppTheme.primaryColor,
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(lang.getText('change_password')),
            CustomTextField(
              controller: _oldPasswordController,
              hintText: lang.getText('old_password'),
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newPasswordController,
              hintText: lang.getText('new_password'),
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: lang.getText('confirm_password'),
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        lang.getText('confirm'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.deepPurpleAccent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
