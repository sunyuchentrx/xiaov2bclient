import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../pages/settings_page.dart';
import '../pages/premium_page.dart';
import '../pages/order_list_page.dart';
import '../pages/account_page.dart';
import '../pages/welcome_page.dart';
import '../providers/language_provider.dart';
import '../services/config_service.dart';
import '../services/api_service.dart';
import '../pages/invite_page.dart';
import '../pages/gift_card_page.dart';
import '../pages/traffic_page.dart';
import '../models/app_config.dart';
import '../pages/ticket_list_page.dart';

class AppNavigationDrawer extends StatefulWidget {
  const AppNavigationDrawer({super.key});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  String _email = '...';
  bool _showWebsite = false;
  String? _websiteUrl;
  AppConfig? _config;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkConfig();
    _loadWebsiteConfig();
  }

  Future<void> _loadWebsiteConfig() async {
    if (!_showWebsite) return;
    final config = await ApiService().getWebsiteConfig();
    if (config != null && mounted) {
      setState(() {
        _websiteUrl = config['app_url'];
      });
    }
  }

  Future<void> _loadUserData() async {
    final userInfo = await ApiService().getUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _email = userInfo['email'] ?? 'User';
      });
    }
  }

  void _checkConfig() {
    final config = ConfigService().appConfig;
    if (config != null) {
      setState(() {
        _config = config;
        _showWebsite = config.uiControl.goWebsite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: [
          // User Header
          Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
            color: AppTheme.surfaceColor,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.getText('dear_user'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _email,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Shop Banner
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PremiumPage()),
              );
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.getText('shop'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        lang.getText('get_unlimited'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(context, Icons.person_outline, lang.getText('my_account'), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountPage()),
                  );
                }),
                _buildMenuItem(context, Icons.list_alt, lang.getText('my_orders'), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OrderListPage()),
                  );
                }),
                _buildMenuItem(context, Icons.card_giftcard, lang.getText('invite'), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InvitePage()),
                  );
                }),
                if (_config?.uiControl.goGiftCard == true)
                  _buildMenuItem(context, Icons.card_giftcard, lang.getText('gift_card'), () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GiftCardPage()),
                    );
                  }),
                if (_config?.uiControl.goTraffic == true)
                  _buildMenuItem(context, Icons.data_usage, lang.getText('traffic_log'), () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrafficPage()),
                    );
                  }),
                if (_showWebsite)
                  _buildMenuItem(context, Icons.language, lang.getText('official_website'), _launchWebsite),
                
                const Divider(color: Colors.white10),
                
                _buildMenuItem(context, Icons.settings_outlined, lang.getText('settings'), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                }),
                _buildMenuItem(context, Icons.support_agent, lang.getText('contact_us'), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TicketListPage()),
                  );
                }),
                _buildMenuItem(context, Icons.info_outline, lang.getText('about'), () {}),
              ],
            ),
          ),
          
          // Logout
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text(
                lang.getText('logout'),
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await ApiService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (route) => false,
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              hoverColor: Colors.redAccent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      hoverColor: Colors.white10,
    );
  }

  Future<void> _showAccountInfo(BuildContext context) async {
    final userInfo = await ApiService().getUserInfo();
    if (!mounted) return;
    
    if (userInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load account info')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('My Account', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Email', userInfo['email']),
            _infoRow('Balance', '${(userInfo['balance'] ?? 0) / 100}'),
            _infoRow('Commission', '${(userInfo['commission_balance'] ?? 0) / 100}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }


  void _launchWebsite() {
    if (_websiteUrl != null) {
      launchUrl(Uri.parse(_websiteUrl!), mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
