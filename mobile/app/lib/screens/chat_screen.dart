import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/chat_stream_service.dart';
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

  List<ChatMessage> _messages = [];

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
  int _streamGen = 0;     // bumps on each new turn — cancels in-flight playback

  // Per-message replay state — kept separate from _streamGen so tapping the
  // speaker icon doesn't interfere with WS streaming and vice versa. While a
  // message is fetching its TTS bytes, its content sits in _replayingContent
  // so the icon can render a spinner.
  int _replayGen = 0;
  String? _replayingContent;

  StreamSubscription<ChatEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _player.dispose();
    super.dispose();
  }

  // ── History load ──────────────────────────────────────────────────────────
  Future<void> _loadMessages() async {
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
      _audioQueue.clear();
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
      _pumpAudio();
    } else if (evt is ChatDone) {
      // Commit the streamed text into the message list. The replay speaker
      // icon renders on every AI bubble — no separate "spoken once" gate.
      final reply = evt.reply.isNotEmpty ? evt.reply : _streamingReply;
      if (reply.trim().isNotEmpty) {
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
        final item = _audioQueue.removeAt(0);
        if (item.gen != _streamGen) continue;
        try {
          final dir = await getTemporaryDirectory();
          final f = File(
            '${dir.path}/ws_${item.gen}_${item.audio.index}.mp3',
          );
          await f.writeAsBytes(item.audio.bytes, flush: true);
          await _player.stop();
          if (item.gen != _streamGen) continue;
          await _player.setFilePath(f.path);
          await _player.play();
          await _player.playerStateStream
              .firstWhere((s) => s.processingState == ProcessingState.completed);
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
    setState(() => _replayingContent = content);
    try { await _player.stop(); } catch (_) {}
    try {
      final bytes = await AgentService.synthesizeSpeech(content);
      if (myGen != _replayGen || !mounted) return;
      final dir = await getTemporaryDirectory();
      final f = File(
        '${dir.path}/replay_${myGen}_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await f.writeAsBytes(bytes, flush: true);
      if (myGen != _replayGen || !mounted) return;
      await _player.setFilePath(f.path);
      await _player.play();
    } catch (e) {
      if (mounted) _showError('Could not play audio: $e');
    } finally {
      if (mounted && myGen == _replayGen) {
        setState(() => _replayingContent = null);
      }
    }
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
      backgroundColor: bg,
      appBar: PreferredSize(
        // PreferredSize does not add the status-bar inset the way AppBar does,
        // so it must be included here or the header's SafeArea eats the 64px.
        preferredSize: Size.fromHeight(64 + MediaQuery.of(context).padding.top),
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
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
            ],
          ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8E8E8)),
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
                        color: const Color(0xFF1A1A1A),
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
        color: isUser ? null : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: const Color(0xFFE8E8E8)),
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
          color: isUser ? Colors.white : const Color(0xFF1A1A1A),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubble,
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _replayMessage(msg.content),
            child: Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  : Icon(Icons.volume_up_rounded, color: color, size: 14),
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
            color: Colors.white,
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
                        color: const Color(0xFF1A1A1A),
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
        color: Colors.white,
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
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(
                  color: const Color(0xFF999999), fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
          _circleButton(
            color: color.withValues(alpha: 0.12),
            iconColor: color,
            icon: Icons.mic_rounded,
            onTap: _openVoiceMode,
          ),
          const SizedBox(width: 6),
          _circleButton(
            color: canSend ? color : const Color(0xFFE0E0E0),
            iconColor: canSend ? Colors.white : const Color(0xFF999999),
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
