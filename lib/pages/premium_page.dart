import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'dart:convert';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';
import '../widgets/custom_window_bar.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> with WidgetsBindingObserver {
  int _selectedPlanIndex = -1;
  String? _selectedPeriod; // e.g. 'month_price', 'year_price'
  int _selectedPlanId = -1;
  
  List<dynamic> _plans = [];
  bool _isLoading = true;
  bool _isPaymentInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchPlans();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPaymentInProgress) {
      _isPaymentInProgress = false; // Reset flag
      _showPaymentCompletionDialog();
    }
  }

  Future<void> _showPaymentCompletionDialog() async {
    // Wait a bit for UI to settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Payment Confirmation', style: TextStyle(color: Colors.white)),
        content: const Text(
          'If you have completed the payment, please click OK to return to the home page and refresh your subscription.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to Home Page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPlans() async {
    final plans = await ApiService().fetchPlans();
    if (mounted) {
      setState(() {
        _plans = plans ?? [];
        
        // Filter plans based on shopIds from config
        final shopIds = ConfigService().appConfig?.shopIds ?? [];
        if (shopIds.isNotEmpty) {
          _plans = _plans.where((plan) => shopIds.contains(plan['id'].toString())).toList();
        }

        _isLoading = false;
        if (_plans.isNotEmpty) {
          // Default select first plan and its first available period
          _selectPlan(0);
        }
      });
    }
  }

  void _selectPlan(int index) {
    if (index < 0 || index >= _plans.length) return;
    final plan = _plans[index];
    _selectedPlanIndex = index;
    _selectedPlanId = plan['id'];
    
    // Auto select first available price period if not already selected or invalid
    // For now, just reset to first available
    if (plan['month_price'] != null) _selectedPeriod = 'month_price';
    else if (plan['quarter_price'] != null) _selectedPeriod = 'quarter_price';
    else if (plan['half_year_price'] != null) _selectedPeriod = 'half_year_price';
    else if (plan['year_price'] != null) _selectedPeriod = 'year_price';
    else if (plan['two_year_price'] != null) _selectedPeriod = 'two_year_price';
    else if (plan['three_year_price'] != null) _selectedPeriod = 'three_year_price';
    else if (plan['onetime_price'] != null) _selectedPeriod = 'onetime_price';
    else if (plan['reset_price'] != null) _selectedPeriod = 'reset_price';
  }

  Future<void> _buyPlan() async {
    if (_selectedPlanId == -1 || _selectedPeriod == null) return;

    print('Submitting order: planId=$_selectedPlanId, period=$_selectedPeriod');

    try {
      // 1. Submit Order
      final tradeNo = await ApiService().submitOrder(
        planId: _selectedPlanId,
        period: _selectedPeriod!,
      );

      // 2. Get Payment Methods
      final methods = await ApiService().getPaymentMethods();
      if (methods == null || methods.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payment methods available')));
        return;
      }

      if (!mounted) return;

      // 3. Select Payment Method
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surfaceColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Payment Method', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...methods.map((method) => ListTile(
                title: Text(method['name'], style: const TextStyle(color: Colors.white)),
                leading: const Icon(Icons.payment, color: Colors.white70),
                onTap: () => _processPayment(tradeNo, method['id']),
              )),
            ],
          ),
        ),
      );

    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('未付款') || errorMsg.contains('pending') || errorMsg.contains('order')) {
        // Handle pending order
        print('Pending order detected, attempting to cancel...');
        await _handlePendingOrder();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handlePendingOrder() async {
    // Fetch orders to find the pending one
    final orders = await ApiService().fetchOrders();
    if (orders == null) return;

    // Find pending order (status == 0)
    final pendingOrder = orders.firstWhere(
      (order) => order['status'] == 0,
      orElse: () => null,
    );

    if (pendingOrder != null) {
      final tradeNo = pendingOrder['trade_no'];
      print('Cancelling pending order: $tradeNo');
      final success = await ApiService().cancelOrder(tradeNo);
      if (success) {
        print('Order cancelled successfully. Retrying purchase...');
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cancelled previous pending order. Retrying...')));
           // Retry purchase after a short delay
           Future.delayed(const Duration(milliseconds: 500), _buyPlan);
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel pending order. Please check My Orders.')));
      }
    } else {
       // No pending order found but server complained?
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Server reported pending order but none found.')));
    }
  }

  Future<void> _processPayment(String tradeNo, int methodId) async {
    Navigator.pop(context); // Close bottom sheet
    
    final url = await ApiService().checkoutOrder(tradeNo: tradeNo, methodId: methodId);
    if (url != null) {
      _isPaymentInProgress = true; // Set flag before launching
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get payment URL')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    final shopConfig = ConfigService().appConfig?.shopConfig;
    final topTip = shopConfig?.shopTopTips.isNotEmpty == true ? shopConfig!.shopTopTips.first : null;

    return CustomWindowBar(
      child: Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.getText('shop'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Icon
                    if (topTip != null && topTip.icon.isNotEmpty)
                      Container(
                        height: 100,
                        width: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.network(
                            topTip.icon,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.amber.withOpacity(0.1),
                              child: const Icon(Icons.workspace_premium, size: 60, color: Colors.amber),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          size: 60,
                          color: Colors.amber,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      topTip?.title.isNotEmpty == true ? topTip!.title : lang.getText('premium_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (topTip != null && topTip.content.isNotEmpty)
                      HtmlWidget(
                        topTip.content,
                        textStyle: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                        customStylesBuilder: (element) {
                          if (element.localName == 'p') {
                            return {'margin': '0', 'text-align': 'center'};
                          }
                          return null;
                        },
                      )
                    else
                      Text(
                        lang.getText('premium_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 40),
                    
                    // Plans List
                    if (_plans.isEmpty)
                      const Text('No plans available', style: TextStyle(color: Colors.white54))
                    else
                      ..._plans.asMap().entries.map((entry) {
                        final index = entry.key;
                        final plan = entry.value;
                        return _buildPlanItem(index, plan);
                      }),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _buyPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          lang.getText('subscribe_now'),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildPlanItem(int index, dynamic plan) {
    bool isSelected = _selectedPlanIndex == index;
    // Simple display: just show name and price range or starting price
    // For simplicity, let's show the first available price
    String priceText = 'N/A';
    if (plan['month_price'] != null) priceText = '\$${plan['month_price'] / 100} / Month';
    else if (plan['year_price'] != null) priceText = '\$${plan['year_price'] / 100} / Year';

    return GestureDetector(
      onTap: () => setState(() => _selectPlan(index)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan['name'] ?? 'Unknown Plan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plan['content'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildPlanDescription(plan['content']),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDescription(String content) {
    // Try to parse as JSON list first
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: decoded.map<Widget>((item) {
            if (item is Map && item.containsKey('feature')) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Expanded(child: Text(item['feature'], style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }).toList(),
        );
      }
    } catch (e) {
      // Not JSON, fall through to HTML
    }

    // Render as HTML
    return HtmlWidget(
      content,
      textStyle: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }
}
