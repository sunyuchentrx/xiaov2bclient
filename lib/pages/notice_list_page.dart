import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_window_bar.dart';

class NoticeListPage extends StatefulWidget {
  const NoticeListPage({super.key});

  @override
  State<NoticeListPage> createState() => _NoticeListPageState();
}

class _NoticeListPageState extends State<NoticeListPage> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  Future<void> _fetchNotices() async {
    setState(() => _isLoading = true);
    final notices = await ApiService().fetchNotices();
    if (mounted) {
      setState(() {
        _notices = notices ?? [];
        _isLoading = false;
      });
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
        title: Text(
          lang.getText('notices'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _notices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      Text(
                        lang.getText('no_notices'),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotices,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notices.length,
                    itemBuilder: (context, index) {
                      final notice = _notices[index];
                      return _buildNoticeCard(notice);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildNoticeCard(Map<String, dynamic> notice) {
    final title = notice['title'] ?? 'No Title';
    final content = notice['content'] ?? '';
    final createdAt = notice['created_at'];
    
    String dateStr = '';
    if (createdAt != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      dateStr = DateFormat('yyyy-MM-dd HH:mm').format(date);
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (dateStr.isNotEmpty)
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}
