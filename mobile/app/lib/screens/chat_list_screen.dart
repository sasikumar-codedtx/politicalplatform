import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_strings.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/device_session.dart';
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
    // Hard gate — must be logged in to enter chat list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _loadSessions();
    });
  }

  Future<void> _loadSessions() async {
    // Cache-first: show the last-known list instantly (~5 ms), then refresh
    // from the backend in the background.
    final cached = await AgentService.getCachedSessions();
    if (cached.isNotEmpty && mounted) {
      setState(() { _sessions = cached; _loading = false; });
    }
    try {
      final sessions = await AgentService.getSessions();
      // Don't wipe a good cached list if the network returned nothing
      // (transient failure); only replace on a real result or first load.
      if (mounted && (sessions.isNotEmpty || cached.isEmpty)) {
        setState(() { _sessions = sessions; _loading = false; });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startNewChat() async {
    final sessionId = await DeviceSession.rotate();
    final session = ChatSession(
      id: sessionId,
      title: t('chat_list.new_conversation'),
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
    if (diff.inDays == 0) return t('chat_list.today');
    if (diff.inDays == 1) return t('chat_list.yesterday');
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final flavor = AppConfig.current;
    final primary = Color(flavor.primaryColor);
    final bg = AppColors.bg;
    final surface = AppColors.surface;
    final border = AppColors.border;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Text(t('chat_list.appbar_title'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
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
                          title: Text(session.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: session.lastMessage.isNotEmpty
                              ? Text(session.lastMessage, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Text(_formatDate(session.createdAt), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
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
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            t('chat_list.ask_leader').replaceAll('{name}', flavor.leaderName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
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
            Text(t('chat_list.empty_title').replaceAll('{name}', flavor.leaderName.split(' ')[0]), style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(t('chat_list.empty_subtitle'), style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.6), textAlign: TextAlign.center),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(t('chat_list.start_conversation'), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
