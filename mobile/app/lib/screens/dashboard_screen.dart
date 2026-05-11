import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import '../services/chat_storage.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<ChatSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await ChatStorage.getSessions();
    setState(() { _sessions = sessions; _loading = false; });
  }

  Future<void> _startNewChat() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = ChatSession(
      id: sessionId,
      title: 'New conversation',
      createdAt: DateTime.now(),
      lastMessage: '',
    );
    await ChatStorage.saveSession(session);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(session: session)),
    );
    _loadSessions();
  }

  Future<void> _openChat(ChatSession session) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(session: session)),
    );
    _loadSessions();
  }

  Future<void> _deleteSession(ChatSession session) async {
    await ChatStorage.deleteSession(session.id);
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
    final color = Color(AppConfig.current.primaryColor);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppConfig.current.appName,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  color: color,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        user?.phoneNumber ?? '',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _sessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations yet',
                                style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to start',
                                style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                              ),
                            ],
                          ),
                        )
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
                                decoration: BoxDecoration(
                                  color: Colors.red[400],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteSession(session),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: color.withValues(alpha: 0.1),
                                    child: Icon(Icons.chat, color: color, size: 20),
                                  ),
                                  title: Text(
                                    session.title,
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: session.lastMessage.isNotEmpty
                                      ? Text(
                                          session.lastMessage,
                                          style: GoogleFonts.inter(
                                              fontSize: 12, color: Colors.grey[500]),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null,
                                  trailing: Text(
                                    _formatDate(session.createdAt),
                                    style: GoogleFonts.inter(
                                        fontSize: 11, color: Colors.grey[400]),
                                  ),
                                  onTap: () => _openChat(session),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewChat,
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: Text('Ask AI', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
