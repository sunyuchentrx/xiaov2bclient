import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_window_bar.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key});

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  List<dynamic> _inviteCodes = [];
  bool _isLoading = true;
  String? _inviteUrlPrefix;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Load invite codes
    final inviteData = await ApiService().getInviteData();
    if (inviteData != null && inviteData['codes'] != null) {
      _inviteCodes = inviteData['codes'];
    }

    // Load invite URL prefix from config
    final config = ConfigService().appConfig;
    if (config != null) {
      _inviteUrlPrefix = config.inviteUrl;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onCodeTap(String code) {
    if (_inviteUrlPrefix == null || _inviteUrlPrefix!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Provider.of<LanguageProvider>(context, listen: false).getText('invite_url_error'))),
      );
      return;
    }

    // Construct full URL: https://qq.com/#/register?code=CODE
    // Ensure prefix doesn't end with / and suffix starts with /
    String baseUrl = _inviteUrlPrefix!;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    final fullUrl = '$baseUrl/#/register?code=$code';

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: fullUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Provider.of<LanguageProvider>(context, listen: false).getText('link_copied'))),
    );

    // Show QR Code Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Invite QR Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: fullUrl,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              fullUrl,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.getText('invite'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Generate Invite Code',
            onPressed: _generateCode,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _inviteCodes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No invite codes found', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _generateCode,
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                        label: Text(
                          lang.getText('generate_invite_code'),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 4,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _inviteCodes.length,
                  itemBuilder: (context, index) {
                    final codeData = _inviteCodes[index];
                    final code = codeData['code'] ?? '';
                    // You might want to show other info like created_at or status if available
                    
                    return Card(
                      color: AppTheme.surfaceColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () => _onCodeTap(code),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code, color: Colors.white70, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      code,
                                      style: const TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      lang.getText('click_to_copy'),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    final error = await ApiService().generateInviteCode();
    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code generated successfully')));
        _loadData(); // Refresh list
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }
}
