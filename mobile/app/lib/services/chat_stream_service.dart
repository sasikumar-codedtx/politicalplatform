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

/// Opens /ws/chat, sends the user_message envelope, and emits typed events
/// as the server streams tokens + audio.
class ChatStreamService {
  static Future<Stream<ChatEvent>> open({
    required String sessionId,
    required String message,
    String? flavorId,
  }) async {
    final controller = StreamController<ChatEvent>();

    final wsUrl = AppConfig.apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    final uri = Uri.parse('$wsUrl/ws/chat');

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();

    final channel = IOWebSocketChannel.connect(uri);

    // Server contract: every audio JSON frame is immediately followed by ONE
    // binary frame containing the MP3 bytes for that sentence. We buffer the
    // last audio header and pair it with the next binary frame.
    Map<String, dynamic>? pendingAudio;

    channel.stream.listen(
      (event) {
        try {
          if (event is String) {
            final json = jsonDecode(event) as Map<String, dynamic>;
            final type = json['type'] as String?;
            switch (type) {
              case 'token':
                controller.add(ChatToken((json['text'] ?? '') as String));
              case 'sentence':
                controller.add(ChatSentence((json['text'] ?? '') as String));
              case 'audio':
                pendingAudio = json;
              case 'done':
                controller.add(ChatDone((json['reply'] ?? '') as String));
              case 'error':
                controller.add(
                  ChatStreamError((json['detail'] ?? 'unknown') as String),
                );
            }
          } else if (event is List<int>) {
            final header = pendingAudio;
            if (header != null) {
              controller.add(ChatAudio(
                index: (header['index'] ?? 0) as int,
                sentence: (header['text'] ?? '') as String,
                bytes: event,
                mime: (header['mime'] ?? 'audio/mpeg') as String,
              ));
              pendingAudio = null;
            }
          }
        } catch (e) {
          controller.add(ChatStreamError('parse error: $e'));
        }
      },
      onError: (e) {
        controller.add(ChatStreamError('socket error: $e'));
        controller.close();
      },
      onDone: () => controller.close(),
      cancelOnError: false,
    );

    channel.sink.add(jsonEncode({
      'type': 'user_message',
      'session_id': sessionId,
      'message': message,
      'flavor_id': flavorId ?? AppConfig.flavorName,
      'token': ?token,
    }));

    controller.onCancel = () async {
      try { await channel.sink.close(); } catch (_) {}
    };

    return controller.stream;
  }
}
