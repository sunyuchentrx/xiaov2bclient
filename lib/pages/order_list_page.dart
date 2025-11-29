import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_window_bar.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> with WidgetsBindingObserver {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  bool _isPaymentInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchOrders();
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

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final orders = await ApiService().fetchOrders();
    if (mounted) {
      setState(() {
        _orders = orders ?? [];
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder(String tradeNo) async {
    final success = await ApiService().cancelOrder(tradeNo);
    if (success) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled')));
      _fetchOrders(); // Refresh list
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel order')));
    }
  }

  Future<void> _payOrder(String tradeNo) async {
    try {
      // 1. Get Payment Methods
      final methods = await ApiService().getPaymentMethods();
      if (methods == null || methods.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No payment methods available')));
        return;
      }

      if (!mounted) return;

      // 2. Select Payment Method
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _processPayment(String tradeNo, int methodId) async {
    Navigator.pop(context); // Close bottom sheet
    
    try {
      final url = await ApiService().checkoutOrder(tradeNo: tradeNo, methodId: methodId);
      if (url != null) {
        _isPaymentInProgress = true; // Set flag before launching
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get payment URL')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _getStatusText(int status, LanguageProvider lang) {
    switch (status) {
      case 0: return lang.getText('order_status_pending');
      case 1: return lang.getText('order_status_paid');
      case 2: return lang.getText('order_status_cancelled');
      case 3: return lang.getText('order_status_completed');
      default: return lang.getText('order_status_unknown');
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.grey;
      case 3: return Colors.green;
      default: return Colors.white;
    }
  }

  Future<void> _confirmCancelOrder(String tradeNo, LanguageProvider lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(lang.getText('cancel'), style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this order?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _cancelOrder(tradeNo);
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(lang.getText('my_orders'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _orders.isEmpty
              ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return _buildOrderItem(order, lang);
                  },
                ),
      ),
    );
  }

  Widget _buildOrderItem(dynamic order, LanguageProvider lang) {
    final status = order['status'] ?? 0;
    final amount = order['total_amount'] != null ? (order['total_amount'] / 100).toStringAsFixed(2) : '0.00';
    final createdTime = order['created_at'] != null 
        ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order['created_at'] * 1000))
        : '';
    final tradeNo = order['trade_no'] ?? '';
    
    // Try to get plan name, fallback to period, then to 'Unknown Plan'
    String planName = 'Unknown Plan';
    if (order['plan'] != null && order['plan']['name'] != null) {
      planName = order['plan']['name'];
    } else if (order['period'] != null) {
      planName = order['period'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${lang.getText('order_no')}: $tradeNo',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(status, lang),
                style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                planName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$$amount',
                style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            createdTime,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (status == 0) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _confirmCancelOrder(tradeNo, lang),
                  child: Text(lang.getText('cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _payOrder(tradeNo),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(lang.getText('pay_now'), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
