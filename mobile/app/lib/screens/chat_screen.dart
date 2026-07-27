import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/chat_stream_service.dart';
import '../services/device_session.dart';
import 'voice_chat_screen.dart';

const _welcomeTa =
    'வணக்கம், நான் உங்கள் விஜய்.\n'
    'உங்களுடன் பேச ஆவலாக உள்ளேன்.\n'
    'நீங்கள் எதைப் பற்றி பேச விரும்புகிறீர்கள்?';
const _welcomeAsset = 'assets/audio/welcome_ta.mp3';

class ChatScreen extends StatefulWidget {
  final ChatSession session;

  const ChatScreen({super.key, required this.session});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _player = AudioPlayer();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChatMessage> _messages = [];

  // Past conversations, shown in the left sidebar (drawer). Cache-first.
  List<ChatSession> _sessions = [];

  // The reply currently being streamed. While non-empty, we render a special
  // "streaming" bubble at the end of the list (no replay icon on it — auto-
  // plays sentence by sentence). When the stream completes we move the text
  // into _messages and clear this.
  String _streamingReply = '';
  bool _streaming = false;

  // Queue of audio sentences arriving from the WS. The playback loop drains
  // this queue in order so even fast-arriving sentences play one at a time.
  final List<_PendingAudio> _audioQueue = [];
  bool _playbackPumping = false;

  // All audio bytes for the CURRENT streaming reply, in order. Saved to a
  // per-message local file on `done` so replaying that message plays from
  // disk with zero network + zero re-synthesis (instant).
  final List<int> _streamAudioBuffer = [];
  int _streamGen = 0;     // bumps on each new turn — cancels in-flight playback

  // Per-message replay state — kept separate from _streamGen so tapping the
  // speaker icon doesn't interfere with WS streaming and vice versa. While a
  // message is fetching its TTS bytes, its content sits in _replayingContent
  // so the icon can render a spinner.
  int _replayGen = 0;
  String? _replayingContent;

  // Playback control. _voiceOn tracks whether the player is actually emitting
  // sound (drives the header Stop button). _audioStop is a one-shot signal that
  // makes the live pump loop bail. _playingContent is the AI message whose
  // audio is currently playing so its bubble icon can show Stop instead of Play.
  StreamSubscription<bool>? _playingSub;
  bool _voiceOn = false;
  bool _audioStop = false;
  String? _playingContent;

  StreamSubscription<ChatEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _playingSub = _player.playingStream.listen((playing) {
      if (!mounted) return;
      setState(() {
        _voiceOn = playing;
        if (!playing) _playingContent = null;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _loadMessages();
      _loadSessions();
    });
  }

  // ── Sidebar history ─────────────────────────────────────────────────────────
  Future<void> _loadSessions() async {
    final cached = await AgentService.getCachedSessions();
    if (cached.isNotEmpty && mounted) setState(() => _sessions = cached);
    try {
      final sessions = await AgentService.getSessions();
      if (mounted && sessions.isNotEmpty) setState(() => _sessions = sessions);
    } catch (_) {}
  }

  void _openSession(ChatSession session) {
    Navigator.pop(context); // close the drawer
    if (session.id == widget.session.id) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ChatScreen(session: session)));
  }

  Future<void> _newChat() async {
    Navigator.pop(context);
    final id = await DeviceSession.rotate();
    if (!mounted) return;
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ChatScreen(
              session: ChatSession(
                id: id, title: 'New conversation',
                createdAt: DateTime.now(), lastMessage: '',
              ),
            )));
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _confirmDelete(ChatSession session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete chat?',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('This conversation will be permanently deleted.',
            style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: const Color(0xFFE40101), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AgentService.deleteSession(session.id);
    if (!mounted) return;
    setState(() => _sessions.removeWhere((s) => s.id == session.id));
    // If the open chat was the one deleted, start a fresh session.
    if (session.id == widget.session.id) _newChat();
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _playingSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  // Stop all voice immediately — live streamed sentences AND per-message replay,
  // regardless of language. Cancels queued audio, supersedes any in-flight
  // replay fetch, and stops the player. _audioStop makes the live pump loop bail
  // even as more sentence frames keep arriving on the socket for this turn.
  Future<void> _stopVoice() async {
    _audioStop = true;
    _replayGen++;
    _audioQueue.clear();
    try { await _player.stop(); } catch (_) {}
    if (mounted) {
      setState(() {
        _replayingContent = null;
        _playingContent = null;
        _voiceOn = false;
      });
    }
  }

  // ── History load ──────────────────────────────────────────────────────────
  Future<void> _loadMessages() async {
    // Cache-first: render the last-known messages instantly, then sync.
    final cached = await AgentService.getCachedHistory(widget.session.id);
    if (cached.isNotEmpty && mounted) {
      setState(() => _messages = cached);
      _scrollToBottom();
    }
    try {
      final messages = await AgentService.getHistory(widget.session.id);
      if (mounted) setState(() => _messages = messages);
      _scrollToBottom();
    } catch (_) {}
  }

  // ── Welcome message audio ────────────────────────────────────────────────
  // Priority: bundled asset → on-device cached MP3 → cache-first /tts call
  // (cloud once, cached on the device + server forever).
  Future<void> _playWelcomeAudio() async {
    try {
      try {
        await rootBundle.load(_welcomeAsset);
        await _player.stop();
        await _player.setAsset(_welcomeAsset);
        await _player.play();
        return;
      } catch (_) {}
      final dir = await getApplicationDocumentsDirectory();
      final cached = File('${dir.path}/welcome_ta.mp3');
      if (!await cached.exists()) {
        final bytes = await AgentService.synthesizeSpeech(_welcomeTa);
        await cached.writeAsBytes(bytes, flush: true);
      }
      await _player.stop();
      await _player.setFilePath(cached.path);
      await _player.play();
    } catch (e) {
      _showError('Could not play welcome audio: $e');
    }
  }

  // ── Mic — opens voice mode ───────────────────────────────────────────────
  Future<void> _openVoiceMode() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceChatScreen(session: widget.session),
      ),
    );
  }

  // ── Streaming send via WebSocket ─────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _streaming) return;

    _controller.clear();
    final userMsg = ChatMessage(
      role: 'user', content: text, timestamp: DateTime.now(),
    );
    final myGen = ++_streamGen;
    setState(() {
      _messages.add(userMsg);
      _streamingReply = '';
      _streaming = true;
      _audioStop = false;
      _audioQueue.clear();
      _streamAudioBuffer.clear();
    });
    _scrollToBottom();

    try {
      final stream = await ChatStreamService.open(
        sessionId: widget.session.id,
        message: text,
      );
      _eventSub?.cancel();
      _eventSub = stream.listen(
        (evt) => _handleEvent(evt, myGen),
        onError: (e) => _finishStream(error: '$e'),
        onDone: () => _finishStream(),
      );
    } catch (e) {
      _finishStream(error: 'Could not connect: $e');
    }
  }

  void _handleEvent(ChatEvent evt, int myGen) {
    if (myGen != _streamGen) return;
    if (evt is ChatToken) {
      setState(() => _streamingReply += evt.text);
      _scrollToBottom();
    } else if (evt is ChatAudio) {
      _audioQueue.add(_PendingAudio(myGen, evt));
      // Accumulate for the per-message local cache. Frames arrive in order
      // before `done`, so the buffer is complete by the time we save it.
      _streamAudioBuffer.addAll(evt.bytes);
      _pumpAudio();
    } else if (evt is ChatDone) {
      // Commit the streamed text into the message list. The replay speaker
      // icon renders on every AI bubble — no separate "spoken once" gate.
      final reply = evt.reply.isNotEmpty ? evt.reply : _streamingReply;
      if (reply.trim().isNotEmpty) {
        _saveReplyAudio(reply);
        setState(() {
          _messages.add(ChatMessage(
            role: 'assistant', content: reply, timestamp: DateTime.now(),
          ));
          _streamingReply = '';
          _streaming = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _streamingReply = '';
          _streaming = false;
        });
      }
    } else if (evt is ChatStreamError) {
      _finishStream(error: evt.detail);
    }
  }

  void _finishStream({String? error}) {
    if (!mounted) return;
    // Promote any partial text into the final message so the user doesn't
    // lose what was already shown.
    final partial = _streamingReply.trim();
    setState(() {
      if (partial.isNotEmpty) {
        _messages.add(ChatMessage(
          role: 'assistant', content: partial, timestamp: DateTime.now(),
        ));
      }
      _streamingReply = '';
      _streaming = false;
    });
    if (error != null && error.isNotEmpty) _showError(error);
  }

  // Sequential audio player — drains _audioQueue one MP3 at a time.
  Future<void> _pumpAudio() async {
    if (_playbackPumping) return;
    _playbackPumping = true;
    try {
      while (_audioQueue.isNotEmpty) {
        if (_audioStop) break;
        final item = _audioQueue.removeAt(0);
        if (item.gen != _streamGen) continue;
        try {
          final dir = await getTemporaryDirectory();
          final f = File(
            '${dir.path}/ws_${item.gen}_${item.audio.index}.mp3',
          );
          await f.writeAsBytes(item.audio.bytes, flush: true);
          await _player.stop();
          if (item.gen != _streamGen || _audioStop) continue;
          await _player.setFilePath(f.path);
          await _player.play();
          // Wait for the sentence to finish. stop() emits `idle` (not
          // `completed`), so accept either or a manual stop would hang here.
          await _player.playerStateStream.firstWhere((s) =>
              s.processingState == ProcessingState.completed ||
              s.processingState == ProcessingState.idle);
        } catch (_) {}
      }
    } finally {
      _playbackPumping = false;
    }
  }

  // Replay = cache-first. Server returns from tts_cache if cached; otherwise
  // generates via cloud, stores in cache, returns bytes — so the next tap is
  // a cache hit. Works for streamed messages AND history-loaded ones.
  //
  // Repeat taps of the SAME message while it's loading are ignored (no race,
  // no flicker). Tapping a DIFFERENT message supersedes via _replayGen.
  Future<void> _replayMessage(String content) async {
    if (_replayingContent == content) return;
    final myGen = ++_replayGen;
    _audioStop = false;
    setState(() {
      _replayingContent = content;
      _playingContent = content;
    });
    try { await _player.stop(); } catch (_) {}
    try {
      // Fast path — audio already saved on this device (from the live turn or
      // a previous replay). Plays from disk, no network, no re-synthesis.
      final local = await _ttsFile(content);
      if (await local.exists() && await local.length() > 0) {
        if (myGen != _replayGen || !mounted) return;
        await _player.setFilePath(local.path);
        await _player.play();
        return;
      }
      // Slow path — fetch once (server cache → Fish), then bank it locally so
      // every future replay of this message is instant.
      final bytes = await AgentService.synthesizeSpeech(content);
      if (myGen != _replayGen || !mounted) return;
      await local.writeAsBytes(bytes, flush: true);
      if (myGen != _replayGen || !mounted) return;
      await _player.setFilePath(local.path);
      await _player.play();
    } catch (e) {
      if (mounted) _showError('Could not play audio: $e');
    } finally {
      if (mounted && myGen == _replayGen) {
        setState(() => _replayingContent = null);
      }
    }
  }

  // Stable per-message audio file (FNV-1a hash of the text → temp dir).
  String _ttsKey(String content) {
    int h = 0x811c9dc5;
    for (final c in content.codeUnits) {
      h = (h ^ c) & 0xffffffff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }

  Future<File> _ttsFile(String content) async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/msg_${_ttsKey(content)}.mp3');
  }

  Future<void> _saveReplyAudio(String content) async {
    if (_streamAudioBuffer.isEmpty) return;
    final bytes = List<int>.from(_streamAudioBuffer);
    try {
      final f = await _ttsFile(content);
      await f.writeAsBytes(bytes, flush: true);
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final color = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: _buildDrawer(color),
      appBar: PreferredSize(
        // PreferredSize does not add the status-bar inset the way AppBar does,
        // so it must be included here or the header's SafeArea eats the height.
        preferredSize: Size.fromHeight(60 + MediaQuery.of(context).padding.top),
        child: _buildHeader(color),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_streaming
                ? _buildWelcome(color)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_streaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_streaming && index == _messages.length) {
                        // The live streaming bubble — no replay icon.
                        return _buildStreamingBubble(color);
                      }
                      return _buildMessageBubble(_messages[index], color);
                    },
                  ),
          ),
          _buildInputBar(color),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 14, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                tooltip: 'Chat history',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_rounded, color: Colors.white, size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Respected Thiru Vijay',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: _streaming
                                ? const Color(0xFFFFCA00)
                                : const Color(0xFF35E08F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _streaming ? 'Replying live...' : 'Online',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11, fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                tooltip: 'Close',
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  // ── History sidebar ─────────────────────────────────────────────────────────
  Widget _buildDrawer(Color color) {
    return Drawer(
      backgroundColor: AppColors.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text('Chat History',
                  style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _newChat,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('New Chat',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _sessions.isEmpty
                  ? Center(
                      child: Text('No past chats yet',
                          style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textMuted,
                          )),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemCount: _sessions.length,
                      itemBuilder: (context, i) {
                        final s = _sessions[i];
                        final active = s.id == widget.session.id;
                        return Material(
                          color: active
                              ? color.withValues(alpha: 0.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            leading: Icon(Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: active ? color : AppColors.textSecondary),
                            title: Text(s.title,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight:
                                      active ? FontWeight.w700 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                )),
                            subtitle: Text(_formatDate(s.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 11, color: AppColors.textMuted,
                                )),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline_rounded,
                                  size: 19, color: AppColors.textMuted),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(s),
                            ),
                            onTap: () => _openSession(s),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(Color color) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.4), width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/av1.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: color.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _welcomeTa,
                      style: GoogleFonts.inter(
                        fontSize: 14, height: 1.55,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: GestureDetector(
                  onTap: _playWelcomeAudio,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 8, offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white, size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color color) {
    final isUser = msg.role == 'user';

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                colors: [color, Color.lerp(color, Colors.black, 0.18)!],
              )
            : null,
        color: isUser ? null : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? color.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        msg.content,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: isUser ? Colors.white : AppColors.textPrimary,
          height: 1.5,
        ),
      ),
    );

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    // AI message — render the replay speaker on EVERY bubble. Tap calls
    // /tts which serves from the disk cache when present (free, instant)
    // and falls through to cloud + caches on a miss. Spins while loading
    // so the user knows the tap registered.
    final isLoading = _replayingContent == msg.content;
    final isPlaying = _playingContent == msg.content && _voiceOn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubble,
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                isPlaying ? _stopVoice() : _replayMessage(msg.content),
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.35), width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3, offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.stop_rounded
                          : Icons.volume_up_rounded,
                      color: color, size: 14,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Live-streaming bubble — grows as tokens arrive. Shows a typing pulse
  /// when empty, no replay icon (cardinal rule for chat mode), and an
  /// inline live indicator while audio is streaming.
  Widget _buildStreamingBubble(Color color) {
    final empty = _streamingReply.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 12, offset: const Offset(0, 4),
              ),
            ],
          ),
          child: empty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dot(color, 0),
                    const SizedBox(width: 4),
                    _dot(color, 150),
                    const SizedBox(width: 4),
                    _dot(color, 300),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _streamingReply,
                      style: GoogleFonts.inter(
                        fontSize: 14, height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.graphic_eq_rounded, color: color, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'live',
                          style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            color: color, letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _dot(Color color, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      child: Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildInputBar(Color color) {
    final f = AppConfig.current;
    final border = Color(f.borderColor);
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = !_streaming && hasText;

    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4, minLines: 1,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 14,
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 8),
          // While Vijay is speaking (live stream or a replay), this slot turns
          // into a Stop button so the user can silence the voice right here at
          // the mic instead of hunting for a control in the header.
          _voiceOn
              ? _circleButton(
                  color: color,
                  iconColor: Colors.white,
                  icon: Icons.stop_rounded,
                  onTap: _stopVoice,
                  gradient: true,
                )
              : _circleButton(
                  color: color.withValues(alpha: 0.12),
                  iconColor: color,
                  icon: Icons.mic_rounded,
                  onTap: _openVoiceMode,
                ),
          const SizedBox(width: 6),
          _circleButton(
            color: canSend ? color : AppColors.surfaceAlt,
            iconColor: canSend ? Colors.white : AppColors.textMuted,
            icon: Icons.send_rounded,
            onTap: canSend ? _sendText : null,
            gradient: canSend,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required Color color,
    required Color iconColor,
    required IconData icon,
    required VoidCallback? onTap,
    bool gradient = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: gradient
              ? LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.22)!],
                )
              : null,
          color: gradient ? null : color,
          shape: BoxShape.circle,
          boxShadow: gradient
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10, offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _PendingAudio {
  final int gen;
  final ChatAudio audio;
  const _PendingAudio(this.gen, this.audio);
}
