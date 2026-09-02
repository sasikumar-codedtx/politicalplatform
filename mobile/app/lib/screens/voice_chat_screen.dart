import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../config/app_colors.dart';
import '../config/app_config.dart';
import '../config/app_strings.dart';
import '../models/chat_session.dart';
import '../services/agent_service.dart';
import '../services/chat_stream_service.dart';

enum _VoiceState { idle, recording, transcribing, thinking, speaking }

class VoiceChatScreen extends StatefulWidget {
  final ChatSession session;
  const VoiceChatScreen({super.key, required this.session});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  final _player   = AudioPlayer();
  final _rng      = math.Random();

  _VoiceState _state = _VoiceState.idle;

  // Full conversation as it happens this session — user transcripts +
  // AI replies, in order. Pre-seeded with prior history on open so
  // context is visible. Auto-scrolls to bottom.
  final List<ChatMessage> _conversation = [];
  final ScrollController _convScroll = ScrollController();

  // Real running elapsed time — starts at 00:00, advances every second
  // while active (recording / thinking / speaking). Resets to 0 each new
  // mic turn.
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  // Live bar heights for the waveform. Driven by a ~16fps ticker; values
  // are random while recording/speaking, near-flat when idle.
  static const int _waveBars = 48;
  late final List<double> _waveHeights = List.filled(_waveBars, 0.15);
  Timer? _waveTimer;

  // Per-message replay state (mirrors chat_screen). Lets the play button
  // ignore rapid repeat taps + show a spinner during the fetch.
  int _replayGen = 0;
  String? _replayingContent;

  // Live streaming state — populated by ChatStreamService events.
  String _streamingReply = '';
  final List<List<int>> _audioQueue = [];
  bool _playbackPumping = false;
  int _streamGen = 0;
  StreamSubscription<ChatEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null && mounted) {
        Navigator.of(context).pop();
        return;
      }
      _loadHistory();
      _startWaveTicker();
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _ticker?.cancel();
    _waveTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _convScroll.dispose();
    super.dispose();
  }

  // Pre-seed the conversation list with the last few messages so the user
  // sees recent context. Limited to last 6 messages to keep the screen
  // clean — the full history lives in the chat screen.
  Future<void> _loadHistory() async {
    try {
      final messages = await AgentService.getHistory(widget.session.id);
      final tail = messages.length > 6 ? messages.sublist(messages.length - 6) : messages;
      if (!mounted) return;
      setState(() => _conversation.addAll(tail));
      _scrollConvToEnd();
    } catch (_) {}
  }

  void _scrollConvToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_convScroll.hasClients) {
        _convScroll.animateTo(
          _convScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Timer ───────────────────────────────────────────────────────────────
  void _startTimer() {
    _ticker?.cancel();
    setState(() => _elapsed = Duration.zero);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
  }

  String _formatElapsed() {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Live waveform ───────────────────────────────────────────────────────
  void _startWaveTicker() {
    _waveTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted) return;
      final active = _state == _VoiceState.recording || _state == _VoiceState.speaking;
      setState(() {
        for (var i = 0; i < _waveBars; i++) {
          if (active) {
            // Center-weighted random heights for a "voice" look
            final dist = (i - _waveBars / 2).abs() / (_waveBars / 2);
            final base = 0.25 + (1 - dist) * 0.65;
            _waveHeights[i] = (base * (0.5 + _rng.nextDouble() * 0.7))
                .clamp(0.08, 1.0);
          } else {
            _waveHeights[i] = 0.1 + _rng.nextDouble() * 0.05;
          }
        }
      });
    });
  }

  // ── Mic recording ───────────────────────────────────────────────────────
  Future<void> _onMicTap() async {
    if (_state == _VoiceState.transcribing || _state == _VoiceState.thinking) return;
    if (_state == _VoiceState.recording) {
      await _stopAndProcess();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showError(t('voice_chat.mic_permission_denied'));
      return;
    }
    // Interrupt any current AI playback before listening
    if (_player.playing) {
      _streamGen++;
      try { await _player.stop(); } catch (_) {}
    }
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      setState(() => _state = _VoiceState.recording);
      _startTimer();
    } catch (e) {
      _showError('${t('voice_chat.could_not_start_recording')}: $e');
    }
  }

  /// Turns a thrown error into something worth showing a citizen. Dart
  /// prefixes every Exception with "Exception: ", and network failures carry
  /// stack-trace noise no user can act on.
  String _friendly(Object e) {
    final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (msg.isEmpty || msg.contains('SocketException') || msg.contains('TimeoutException')) {
      return t('voice_chat.server_unreachable');
    }
    return msg;
  }

  Future<void> _stopAndProcess() async {
    // Timer stops immediately when user stops recording — it should only
    // count "you are speaking" time, not the AI's thinking + reply time.
    _stopTimer();
    setState(() => _state = _VoiceState.transcribing);
    final path = await _recorder.stop();
    if (path == null) {
      setState(() => _state = _VoiceState.idle);
      return;
    }

    try {
      // Auto-detect the spoken language across all 99 Whisper languages.
      // Forcing 'ta' for tn-tvk made English-spoken queries come back as
      // Tamil-script English, which then made the LLM reply in Tamil even
      // when the user spoke in English. The Hindi-mis-detection workaround
      // it was protecting is now handled server-side in guard.py (Devanagari
      // input is treated as Tamil for the tn-tvk flavor).
      final transcribed = await AgentService.transcribe(File(path));
      if (transcribed.isEmpty) {
        setState(() => _state = _VoiceState.idle);
        return;
      }

      // Append the user's transcribed message to the conversation —
      // they see what they actually said, not a blank wait.
      setState(() {
        _conversation.add(ChatMessage(
          role: 'user', content: transcribed, timestamp: DateTime.now(),
        ));
        _state = _VoiceState.thinking;
        _streamingReply = '';
        _audioQueue.clear();
      });
      _scrollConvToEnd();

      await _runStreamedTurn(transcribed);

      if (!mounted) return;
      setState(() => _state = _VoiceState.idle);

      // Continuous conversation — once the AI finishes speaking, hop
      // straight back into recording. User taps End Chat to leave.
      // Bail if the user signed out mid-conversation.
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted
          && _state == _VoiceState.idle
          && FirebaseAuth.instance.currentUser != null) {
        await _startRecording();
      }
    } catch (e) {
      _showError(_friendly(e));
      if (mounted) {
        setState(() => _state = _VoiceState.idle);
      }
    } finally {
      try { await File(path).delete(); } catch (_) {}
    }
  }

  // ── Streamed turn — replaces the old blocking sendMessage + cache poll ──
  // Opens /ws/chat; tokens land live in _streamingReply (visible in the
  // conversation), audio frames queue up and play sequentially. First audio
  // typically arrives in ~1.5s instead of ~6s with the REST path.
  Future<void> _runStreamedTurn(String userText) async {
    final myGen = ++_streamGen;
    final completer = Completer<void>();
    try {
      final stream = await ChatStreamService.open(
        sessionId: widget.session.id,
        message: userText,
      );
      _eventSub?.cancel();
      _eventSub = stream.listen(
        (evt) => _handleStreamEvent(evt, myGen, completer),
        onError: (e) {
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future;
    } catch (e) {
      if (mounted) _showError('${t('voice_chat.could_not_connect')}: $e');
    }
    // Wait for the audio queue to drain so the next mic turn doesn't start
    // talking over Vijay's last sentence.
    while (_playbackPumping || _audioQueue.isNotEmpty) {
      if (myGen != _streamGen) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _handleStreamEvent(ChatEvent evt, int myGen, Completer<void> doneCompleter) {
    if (myGen != _streamGen) return;
    if (evt is ChatToken) {
      if (_state != _VoiceState.speaking) {
        setState(() => _state = _VoiceState.speaking);
      }
      setState(() => _streamingReply += evt.text);
      _scrollConvToEnd();
    } else if (evt is ChatAudio) {
      _audioQueue.add(evt.bytes);
      _pumpAudio(myGen);
    } else if (evt is ChatDone) {
      final reply = evt.reply.isNotEmpty ? evt.reply : _streamingReply;
      if (reply.trim().isNotEmpty) {
        setState(() {
          _conversation.add(ChatMessage(
            role: 'assistant', content: reply, timestamp: DateTime.now(),
          ));
          _streamingReply = '';
        });
        _scrollConvToEnd();
      } else {
        setState(() => _streamingReply = '');
      }
      if (!doneCompleter.isCompleted) doneCompleter.complete();
    } else if (evt is ChatStreamError) {
      _showError(evt.detail);
      if (!doneCompleter.isCompleted) doneCompleter.complete();
    }
  }

  // Sequential MP3 playback — drains _audioQueue one frame at a time so
  // sentences never overlap.
  Future<void> _pumpAudio(int myGen) async {
    if (_playbackPumping) return;
    _playbackPumping = true;
    try {
      while (_audioQueue.isNotEmpty) {
        if (myGen != _streamGen) return;
        final bytes = _audioQueue.removeAt(0);
        try {
          final dir = await getTemporaryDirectory();
          final f = File(
            '${dir.path}/ws_voice_${myGen}_${DateTime.now().microsecondsSinceEpoch}.mp3',
          );
          await f.writeAsBytes(bytes, flush: true);
          await _player.stop();
          if (myGen != _streamGen) return;
          await _player.setFilePath(f.path);
          await _player.play();
          await _player.playerStateStream.firstWhere(
            (s) => s.processingState == ProcessingState.completed,
          );
        } catch (_) {}
      }
    } finally {
      _playbackPumping = false;
    }
  }

  // ── Manual replay (per-message play button) ─────────────────────────────
  // Cache-first /tts — returns instantly on a hit, falls through to cloud
  // once on a miss (and stores it so subsequent taps are free). Used by the
  // play button next to history-loaded AI bubbles.
  //
  // Repeat taps of the SAME message while it's loading are ignored. Uses a
  // dedicated counter so rapid taps don't cancel each other into oblivion.
  Future<void> _replayMessage(String text) async {
    if (_replayingContent == text) return;
    final myGen = ++_replayGen;
    setState(() => _replayingContent = text);
    try { await _player.stop(); } catch (_) {}
    try {
      final bytes = await AgentService.synthesizeSpeech(text);
      if (myGen != _replayGen || !mounted) return;
      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/tts_replay_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await out.writeAsBytes(bytes, flush: true);
      if (myGen != _replayGen || !mounted) return;
      await _player.setFilePath(out.path);
      await _player.play();
    } catch (e) {
      if (mounted) _showError('${t('voice_chat.could_not_play_audio')}: $e');
    } finally {
      if (mounted && myGen == _replayGen) {
        setState(() => _replayingContent = null);
      }
    }
  }


  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final color = Color(f.primaryColor);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(color),
              const SizedBox(height: 20),
              Expanded(child: _buildConversation(color)),
              const SizedBox(height: 8),
              _buildWaveform(color),
              const SizedBox(height: 16),
              Text(
                _formatElapsed(),
                style: GoogleFonts.robotoMono(
                  color: color, fontSize: 22, fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusText(),
                style: GoogleFonts.inter(
                  color: color, fontSize: 14, fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              _buildControls(color),
              const SizedBox(height: 8),
              Text(
                t('voice_chat.tap_to_speak_language'),
                style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('voice_chat.you_are_speaking_with'),
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15, fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                t('voice_chat.respected_vijay_sir'),
                style: GoogleFonts.inter(
                  color: color, fontSize: 28, fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('voice_chat.chief_minister_title'),
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11, fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/av1.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: color.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, color: color, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversation(Color color) {
    final isStreaming = _streamingReply.isNotEmpty;
    if (_conversation.isEmpty && !isStreaming) {
      return Center(
        child: Text(
          t('voice_chat.tap_mic_start'),
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }
    final extra = isStreaming ? 1 : 0;
    return ListView.builder(
      controller: _convScroll,
      padding: EdgeInsets.zero,
      itemCount: _conversation.length + extra,
      itemBuilder: (context, i) {
        if (isStreaming && i == _conversation.length) {
          return _buildAiBubble(color, _streamingReply);
        }
        final msg = _conversation[i];
        return msg.role == 'user'
            ? _buildUserBubble(color, msg.content)
            : _buildAiBubble(color, msg.content);
      },
    );
  }

  Widget _buildUserBubble(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 40),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13, height: 1.4, color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/av1.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: color.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13, height: 1.45,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _replayMessage(text),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: _replayingContent == text
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 18,
                    child: _MiniWaveform(color: color, heights: _waveHeights.sublist(0, 28)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform(Color color) {
    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_waveBars, (i) {
          final h = _waveHeights[i] * 76;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 70),
                height: h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildControls(Color color) {
    final isRecording = _state == _VoiceState.recording;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SideButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: t('voice_chat.type_button'),
          onTap: () {
            _streamGen++;
            _player.stop();
            _recorder.stop();
            Navigator.pop(context);
          },
        ),
        GestureDetector(
          onTap: _onMicTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 84, height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  Color.lerp(color, Colors.black, 0.25) ?? color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isRecording ? 0.55 : 0.30),
                  blurRadius: isRecording ? 26 : 16,
                  spreadRadius: isRecording ? 4 : 2,
                ),
              ],
            ),
            child: Icon(
              _state == _VoiceState.transcribing || _state == _VoiceState.thinking
                  ? Icons.hourglass_top_rounded
                  : (isRecording ? Icons.stop_rounded : Icons.mic_rounded),
              color: Colors.white, size: 34,
            ),
          ),
        ),
      ],
    );
  }

  String _statusText() {
    switch (_state) {
      case _VoiceState.idle:          return t('voice_chat.status_idle');
      case _VoiceState.recording:     return t('voice_chat.status_listening');
      case _VoiceState.transcribing:  return t('voice_chat.status_transcribing');
      case _VoiceState.thinking:      return t('voice_chat.status_thinking');
      case _VoiceState.speaking:      return t('voice_chat.status_speaking');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }
}


class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SideButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


class _MiniWaveform extends StatelessWidget {
  final Color color;
  final List<double> heights;
  const _MiniWaveform({required this.color, required this.heights});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(heights.length, (i) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 70),
              height: heights[i] * 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        );
      }),
    );
  }
}
