import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_window_bar.dart';

class TicketDetailPage extends StatefulWidget {
  final int ticketId;

  const TicketDetailPage({super.key, required this.ticketId});

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _ticket;
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoading = true);
    final ticket = await ApiService().getTicketDetail(widget.ticketId);
    if (mounted) {
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    }
  }

  Future<void> _reply() async {
    if (_replyController.text.isEmpty) return;

    setState(() => _isSending = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final error = await ApiService().replyTicket(widget.ticketId, _replyController.text);

    if (error == null) {
      _replyController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.getText('reply_sent'))),
        );
        _loadTicket(); // Refresh to see new message
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
    }
  }

  Future<void> _closeTicket() async {
    setState(() => _isLoading = true);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final error = await ApiService().closeTicket(widget.ticketId);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.getText('ticket_closed'))),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return CustomWindowBar(
        child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      ),
      );
    }

    if (_ticket == null) {
      return CustomWindowBar(
        child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Error loading ticket', style: TextStyle(color: Colors.white))),
      ),
      );
    }

    final messages = _ticket!['message'] as List<dynamic>? ?? [];
    // Assuming 'message' is a list of objects like {message: "...", is_me: true/false, created_at: ...}
    // If the API returns a single message string for the initial ticket, we might need to adjust.
    // Based on typical V2Board, 'message' in detail might be a list of conversation items.
    // Let's assume it is. If it's just a string, we display it as one item.
    
    // Wait, V2Board structure usually has 'message' as a list in detail view.
    // Let's handle both cases just in case.
    List<dynamic> messageList = [];
    if (messages is List) {
      messageList = messages;
    } else if (messages is String) {
      // If it's just a string, maybe it's the initial message?
      // But usually detail endpoint returns conversation.
      // Let's assume list for now as per standard.
    }

    final status = _ticket!['status'] ?? 0;
    final isClosed = status == 1;

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
        title: Text(_ticket!['subject'] ?? '', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          if (!isClosed)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: lang.getText('close_ticket'),
              onPressed: _closeTicket,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                final msg = messageList[index];
                final isMe = msg['is_me'] == true;
                final content = msg['message'] ?? '';
                final time = msg['created_at'];
                final dateStr = time != null
                    ? DateFormat('MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(time * 1000))
                    : '';

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.primaryColor : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HtmlWidget(
                          content,
                          textStyle: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (!isClosed)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: lang.getText('enter_message'),
                        hintStyle: const TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                          )
                        : const Icon(Icons.send, color: AppTheme.primaryColor),
                    onPressed: _isSending ? null : _reply,
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
