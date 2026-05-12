import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await AgentService.getSessions();
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startNewChat() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = ChatSession(
      id: sessionId,
      title: 'New conversation',
      createdAt: DateTime.now(),
      lastMessage: '',
    );
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(session: session)));
    _loadSessions();
  }

  Future<void> _openChat(ChatSession session) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(session: session)));
    _loadSessions();
  }

  Future<void> _deleteSession(ChatSession session) async {
    await AgentService.deleteSession(session.id);
    _loadSessions();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final flavor = AppConfig.current;
    final primary = Color(flavor.primaryColor);
    final bg = Color(flavor.backgroundColor);
    final surface = Color(flavor.surfaceColor);
    final border = Color(flavor.borderColor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Text('Ask CM Vijay', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1A1A1A))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: border, height: 1),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _EmptyState(primary: primary, flavor: flavor, onStart: _startNewChat)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Dismissible(
                      key: Key(session.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(color: Colors.red[400], borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteSession(session),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: border),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.chat_bubble_outline_rounded, color: primary, size: 20),
                          ),
                          title: Text(session.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF1A1A1A)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: session.lastMessage.isNotEmpty
                              ? Text(session.lastMessage, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF666666)), maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Text(_formatDate(session.createdAt), style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
                          onTap: () => _openChat(session),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: Text('Ask ${flavor.leaderName.split(' ')[0]}', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color primary;
  final FlavorConfig flavor;
  final VoidCallback onStart;
  const _EmptyState({required this.primary, required this.flavor, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 44, color: primary),
            ),
            const SizedBox(height: 20),
            Text('Chat with ${flavor.leaderName.split(' ')[0]}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text('Ask about policies, schemes, or anything you want your CM to know.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666), height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text('Start a Conversation', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
