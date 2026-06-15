import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/services/gemini_service.dart';
import '../core/services/firestore_service.dart';
import '../core/theme/app_theme.dart';
import '../core/models/models.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chatId = 'main';
  List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final msgs = await FirestoreService.getChatHistory(_chatId);
    if (mounted) {
      setState(() {
        _messages = msgs;
        if (_messages.isEmpty) {
          _messages.add(ChatMessage(
            id: 'template',
            role: 'assistant',
            content: "Hey, I am StudyBot AI. How can I assist you with your studies today?",
            timestamp: DateTime.now(),
          ));
        }
      });
    }
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    _ctrl.clear();
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _loading = true;
    });
    _scrollToBottom();

    try {
      final reply = await GeminiService.chat(
        _messages.where((m) => m.role != 'user' || m.id != userMsg.id).toList(),
        text,
      );

      final assistantMsg = ChatMessage(
        id: const Uuid().v4(),
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _loading = false;
        });
      }
      await FirestoreService.saveChatMessages(_chatId, _messages);
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text("Delete Chat", style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        content: const Text("Clear conversation history?", style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() => _messages = []);
              FirestoreService.saveChatMessages(_chatId, []);
              Navigator.pop(context);
              _loadHistory();
            },
            child: const Text("Delete", style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Resize to avoid bottom inset is crucial for keyboard handling
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF0D0D0D) : AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('STUDYBOT AI',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _messages.isEmpty ? null : _confirmDelete,
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index], isDark),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          _buildRigMasterInput(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // Use a percentage of screen width to prevent bubble overflow
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isUser
              ? null
              : Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1),
        ),
        child: Text(
          msg.content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildRigMasterInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end, // Allows input to grow vertically
          children: [
            // CRITICAL: Expanded forces the TextField to occupy only the available space
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent),
                ),
                child: TextField(
                  controller: _ctrl,
                  // Use maxLines: null and keyboardType: multiline to prevent horizontal overflow
                  maxLines: 5,
                  minLines: 1,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    hintText: "Ask StudyBot...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Standalone Send Button
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: _send,
                child: Icon(Icons.send_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
