import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatSession session;

  const ChatScreen({super.key, required this.session});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _recorder = AudioRecorder();
  final _player   = AudioPlayer();

  List<ChatMessage> _messages = [];
  bool _thinking = false;

  // Voice mode — engaged when user taps the mic at least once this session.
  // Reset when the screen is disposed.
  bool _voiceMode = false;

  bool _recording  = false;
  bool _processing = false;
  bool _replayingLast = false;     // briefly true while we re-synth the last reply

  // Monotonic counter for TTS requests. Each call to _speak() captures the
  // current value and only proceeds to play if it's still the latest. This
  // discards stale Fish responses when the user has already moved on to a
  // newer reply — fixes "an old voice plays after I sent a new message".
  int _speakGen = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await AgentService.getHistory(widget.session.id);
      if (mounted) setState(() => _messages = messages);
      _scrollToBottom();
    } catch (_) {}
  }

  // ── Mic + voice mode ──────────────────────────────────────────────────────

  Future<bool> _ensureMicPermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) return true;
    _showError('Microphone permission denied');
    return false;
  }

  Future<void> _toggleMic() async {
    if (_processing) return;
    if (_recording) {
      await _stopAndProcess();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (!await _ensureMicPermission()) return;
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      setState(() {
        _recording = true;
        _voiceMode = true;
      });
    } catch (e) {
      _showError('Could not start recording: $e');
    }
  }

  Future<void> _stopAndProcess() async {
    setState(() => _recording = false);
    final path = await _recorder.stop();
    if (path == null) return;

    setState(() => _processing = true);
    try {
      // Force STT language for Tamil-flavor sessions. Whisper auto-detect
      // sometimes confuses Tamil speech with Hindi on short utterances and
      // returns Devanagari text — the LLM then replies in Hindi.
      // Hardcode the script per flavor so this can't happen.
      final sttLang = AppConfig.flavorName == 'tn-tvk' ? 'ta' : null;
      final transcribed = await AgentService.transcribe(File(path), language: sttLang);
      if (transcribed.isEmpty) return;

      final userMsg = ChatMessage(role: 'user', content: transcribed, timestamp: DateTime.now());
      setState(() { _messages.add(userMsg); _thinking = true; });
      _scrollToBottom();

      final reply = await AgentService.sendMessage(widget.session.id, transcribed);
      final aiMsg = ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now());
      setState(() { _messages.add(aiMsg); _thinking = false; });
      _scrollToBottom();

      if (_voiceMode) await _speak(reply);
    } catch (e) {
      _showError('$e');
      setState(() => _thinking = false);
    } finally {
      if (mounted) setState(() => _processing = false);
      try { await File(path).delete(); } catch (_) {}
    }
  }

  Future<void> _speak(String text) async {
    final myGen = ++_speakGen;
    try {
      final mp3Bytes = await AgentService.synthesizeSpeech(text);

      // If the user sent another mic turn while we were waiting on Fish,
      // there's a newer _speak in flight. Discard this one — playing it
      // now would be "old voice telling latest reply" which is exactly
      // the bug the user reported.
      if (myGen != _speakGen) return;

      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await out.writeAsBytes(mp3Bytes, flush: true);

      // Stop any currently playing audio so the new reply takes over.
      try { await _player.stop(); } catch (_) {}

      // Last-chance check before play — a newer reply may have arrived
      // while we were writing the file to disk.
      if (myGen != _speakGen) return;

      await _player.setFilePath(out.path);
      await _player.play();
    } catch (e) {
      if (myGen == _speakGen) _showError('Playback failed: $e');
    }
  }

  // Replay the most recent assistant message with the cloned voice.
  // Auto-engages voice mode so future replies play too. If there is no AI
  // message yet, shows a hint and just turns voice mode on.
  Future<void> _onReplayTap() async {
    if (_replayingLast || _processing) return;
    final lastAi = _messages.lastWhere(
      (m) => m.role == 'assistant',
      orElse: () => ChatMessage(role: '', content: '', timestamp: DateTime.now()),
    );
    setState(() => _voiceMode = true);     // engage for future turns either way
    if (lastAi.content.isEmpty) {
      _showError('Send a message first — there\'s nothing to replay.');
      return;
    }
    setState(() => _replayingLast = true);
    try {
      // Stop anything currently playing so a tap restarts cleanly.
      await _player.stop();
      await _speak(lastAi.content);
    } finally {
      if (mounted) setState(() => _replayingLast = false);
    }
  }

  // Text-mode send: typing is always silent (no TTS), regardless of voice mode.
  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _thinking) return;

    _controller.clear();
    final userMsg = ChatMessage(role: 'user', content: text, timestamp: DateTime.now());
    setState(() { _messages.add(userMsg); _thinking = true; });
    _scrollToBottom();

    try {
      final reply = await AgentService.sendMessage(widget.session.id, text);
      final aiMsg = ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now());
      setState(() { _messages.add(aiMsg); _thinking = false; });
      _scrollToBottom();
    } catch (e) {
      setState(() => _thinking = false);
      _showError('$e');
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
          duration: const Duration(milliseconds: 300),
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
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            // tvk_flag.png as the AppBar avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/tvk_flag.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: color.withValues(alpha: 0.1),
                    child: Icon(Icons.person_rounded, color: color, size: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.session.title,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF1A1A1A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Replay / voice-mode button — always visible.
            //   Tap            → replay the last AI reply with the cloned voice
            //                    AND auto-engage voice mode for future replies.
            //   Long-press     → silence voice mode.
            //   Color reflects state: filled red when voice mode on, gray outline off.
            _ReplayButton(
              voiceModeOn: _voiceMode,
              busy: _processing || _replayingLast,
              activeColor: color,
              onTap: _onReplayTap,
              onLongPress: () => setState(() => _voiceMode = false),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: border, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty(color)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_thinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_thinking && index == _messages.length) {
                        return _buildThinkingBubble(color);
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

  Widget _buildEmpty(Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Media.jpg in the empty state, where the sparkle was
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/Media.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: color.withValues(alpha: 0.1),
                  child: Icon(Icons.auto_awesome, size: 56, color: color.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text("What's on your mind?",
              style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ask CM Vijay anything — type, or tap the mic',
              style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Color color) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? color : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Text(
          msg.content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isUser ? Colors.white : const Color(0xFF1A1A1A),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildThinkingBubble(Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [_dot(color, 0), const SizedBox(width: 4), _dot(color, 150), const SizedBox(width: 4), _dot(color, 300)],
        ),
      ),
    );
  }

  Widget _dot(Color color, int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
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
    final canSend = !_thinking && !_processing && _controller.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 8, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),     // refresh send-button enabled state
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 14),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              onSubmitted: (_) => _sendText(),
            ),
          ),
          const SizedBox(width: 6),
          // Mic button — next to send, per the design
          _circleButton(
            color: _recording ? color : color.withValues(alpha: 0.12),
            iconColor: _recording ? Colors.white : color,
            icon: _processing
                ? Icons.hourglass_top_rounded
                : (_recording ? Icons.stop_rounded : Icons.mic_rounded),
            onTap: _toggleMic,
            pulsing: _recording,
          ),
          const SizedBox(width: 6),
          // Send button
          _circleButton(
            color: canSend ? color : const Color(0xFFE0E0E0),
            iconColor: canSend ? Colors.white : const Color(0xFF999999),
            icon: Icons.send_rounded,
            onTap: canSend ? _sendText : null,
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
    bool pulsing = false,
  }) {
    final btn = Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: pulsing
            ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 18, spreadRadius: 2)]
            : null,
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
    return GestureDetector(onTap: onTap, child: btn);
  }
}


/// AppBar replay button — Hotstar-style.
///   Tap        → replay the last AI reply with the cloned voice
///   Long-press → silence (turn voice mode off)
///   Filled red = voice mode on, gray outline = voice mode off,
///   pulsing red = currently playing.
class _ReplayButton extends StatelessWidget {
  final bool voiceModeOn;
  final bool busy;
  final Color activeColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReplayButton({
    required this.voiceModeOn,
    required this.busy,
    required this.activeColor,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bg = voiceModeOn ? activeColor : Colors.transparent;
    final fg = voiceModeOn ? Colors.white : const Color(0xFF999999);
    final border = voiceModeOn ? activeColor : const Color(0xFFCCCCCC);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.5),
            boxShadow: busy
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.55), blurRadius: 16, spreadRadius: 2)]
                : null,
          ),
          child: Icon(
            busy ? Icons.graphic_eq : Icons.volume_up_rounded,
            color: fg,
            size: 18,
          ),
        ),
      ),
    );
  }
}
