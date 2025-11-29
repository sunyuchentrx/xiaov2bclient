import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_window_bar.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';

class TrafficPage extends StatefulWidget {
  const TrafficPage({super.key});

  @override
  State<TrafficPage> createState() => _TrafficPageState();
}

class _TrafficPageState extends State<TrafficPage> {
  List<dynamic> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await ApiService().getTrafficLog();
    if (mounted) {
      setState(() {
        _logs = logs ?? [];
        print('Traffic Logs: $_logs'); // Debug print
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
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
        title: Text(lang.getText('traffic_log'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _logs.isEmpty
              ? const Center(child: Text('No traffic logs found', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    // Assuming log structure: { 'log_time': timestamp, 'u': upload_bytes, 'd': download_bytes }
                    // Adjust based on actual API response if needed.
                    // Use record_at and format as yyyy-MM-dd
                    final timestamp = log['record_at'];
                    
                    final time = timestamp != null 
                        ? DateFormat('yyyy-MM-dd').format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000))
                        : 'Unknown Time';
                    final upload = log['u'] ?? 0;
                    final download = log['d'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(time, style: const TextStyle(color: Colors.white70)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  Text(_formatBytes(upload), style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.arrow_downward, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  Text(_formatBytes(download), style: const TextStyle(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
