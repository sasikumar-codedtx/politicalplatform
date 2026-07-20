import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_socket_channel/io.dart';
import '../config/app_config.dart';

/// One streamed chat event. Tokens build the visible message; sentences mark
/// boundaries; audio chunks carry the MP3 bytes for that sentence; done
/// signals the end of the turn.
sealed class ChatEvent {
  const ChatEvent();
}

class ChatToken extends ChatEvent {
  final String text;
  const ChatToken(this.text);
}

class ChatSentence extends ChatEvent {
  final String text;
  const ChatSentence(this.text);
}

class ChatAudio extends ChatEvent {
  final int index;
  final String sentence;
  final List<int> bytes;
  final String mime;
  const ChatAudio({
    required this.index,
    required this.sentence,
    required this.bytes,
    required this.mime,
  });
}

class ChatDone extends ChatEvent {
  final String reply;
  const ChatDone(this.reply);
}

class ChatStreamError extends ChatEvent {
  final String detail;
  const ChatStreamError(this.detail);
}

/// Persistent /ws/chat client. The socket is opened once and reused for every
/// turn, so each message skips a fresh WS + TLS handshake. Each call to [open]
/// sends one user_message envelope and returns a stream scoped to that turn;
/// the server's `done`/`error` frame ends the turn's stream but leaves the
/// socket open for the next one.
class ChatStreamService {
  static IOWebSocketChannel? _channel;
  static StreamSubscription<dynamic>? _sub;
  static StreamController<ChatEvent>? _current;
  static Map<String, dynamic>? _pendingAudio;

  static Future<Stream<ChatEvent>> open({
    required String sessionId,
    required String message,
    String? flavorId,
  }) async {
    // A new turn supersedes any previous one still attached.
    await _current?.close();
    final controller = StreamController<ChatEvent>();
    _current = controller;
    _pendingAudio = null;

    controller.onCancel = () {
      if (identical(_current, controller)) _current = null;
    };

    try {
      _ensureConnected();
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      _channel!.sink.add(jsonEncode({
        'type': 'user_message',
        'session_id': sessionId,
        'message': message,
        'flavor_id': flavorId ?? AppConfig.flavorName,
        'token': ?token,
      }));
    } catch (e) {
      controller.add(ChatStreamError('connect error: $e'));
      await controller.close();
      if (identical(_current, controller)) _current = null;
    }

    return controller.stream;
  }

  static void _ensureConnected() {
    if (_channel != null) return;

    final wsUrl = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final channel = IOWebSocketChannel.connect(Uri.parse('$wsUrl/ws/chat'));
    _channel = channel;
    _sub = channel.stream.listen(
      _onFrame,
      onError: (e) => _onSocketClosed('socket error: $e'),
      onDone: () => _onSocketClosed(null),
      cancelOnError: false,
    );
  }

  // Server contract: every audio JSON frame is immediately followed by ONE
  // binary frame containing the MP3 bytes for that sentence. We buffer the
  // last audio header and pair it with the next binary frame.
  static void _onFrame(dynamic event) {
    final controller = _current;
    try {
      if (event is String) {
        final json = jsonDecode(event) as Map<String, dynamic>;
        switch (json['type'] as String?) {
          case 'token':
            controller?.add(ChatToken((json['text'] ?? '') as String));
          case 'sentence':
            controller?.add(ChatSentence((json['text'] ?? '') as String));
          case 'audio':
            _pendingAudio = json;
          case 'done':
            controller?.add(ChatDone((json['reply'] ?? '') as String));
            _endTurn();
          case 'error':
            controller?.add(
              ChatStreamError((json['detail'] ?? 'unknown') as String),
            );
            _endTurn();
        }
      } else if (event is List<int>) {
        final header = _pendingAudio;
        if (header != null) {
          controller?.add(ChatAudio(
            index: (header['index'] ?? 0) as int,
            sentence: (header['text'] ?? '') as String,
            bytes: event,
            mime: (header['mime'] ?? 'audio/mpeg') as String,
          ));
          _pendingAudio = null;
        }
      }
    } catch (e) {
      controller?.add(ChatStreamError('parse error: $e'));
    }
  }

  // End the current turn's stream but keep the socket open for the next turn.
  static void _endTurn() {
    _current?.close();
    _current = null;
    _pendingAudio = null;
  }

  static void _onSocketClosed(String? error) {
    if (error != null) _current?.add(ChatStreamError(error));
    _current?.close();
    _current = null;
    _sub?.cancel();
    _sub = null;
    _channel = null; // next open() reconnects
  }

  /// Close the socket entirely — call on chat-session teardown / sign-out.
  static Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _current?.close();
    _current = null;
  }
}
