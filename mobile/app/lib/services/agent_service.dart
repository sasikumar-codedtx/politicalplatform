import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';

class AgentService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Send a message, get AI reply ─────────────────────────────────────────
  static Future<String> sendMessage(String sessionId, String message) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: await _headers(),
        body: jsonEncode({
          'session_id': sessionId,
          'message': message,
          'flavor_id': AppConfig.flavorName,
        }),
      ).timeout(const Duration(seconds: 90));
    } on Exception catch (e) {
      // Network-level failure — surface a readable message
      final msg = e.toString().contains('timeout')
          ? 'Request timed out. The AI is taking too long.'
          : 'Could not reach the server. Check your connection.';
      throw Exception(msg);
    }

    if (response.statusCode == 200) {
      final reply = (jsonDecode(response.body) as Map)['reply'] as String? ?? '';
      if (reply.isEmpty) throw Exception('No reply received. Please try again.');
      return reply;
    }
    if (response.statusCode == 503) throw Exception('AI service is busy. Please wait a moment.');
    throw Exception('Server error (${response.statusCode}). Please try again.');
  }

  // ── List all sessions from backend ────────────────────────────────────────
  static Future<List<ChatSession>> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map;
        final list = data['sessions'] as List<dynamic>;
        return list.map((e) => ChatSession(
          id: e['id'] as String,
          title: e['title'] as String,
          createdAt: DateTime.parse(e['created_at'] as String),
          lastMessage: e['last_message'] as String? ?? '',
        )).toList();
      }
    } catch (_) {
      // Backend unreachable — return empty list so the UI still works
    }
    return [];
  }

  // ── Get full message history for a session ────────────────────────────────
  static Future<List<ChatMessage>> getHistory(String sessionId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/history/$sessionId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map;
      final list = data['history'] as List<dynamic>;
      return list.map((e) => ChatMessage(
        role: e['role'] as String,
        content: e['content'] as String,
        timestamp: DateTime.tryParse(e['timestamp'] as String? ?? '') ?? DateTime.now(),
      )).toList();
    }
    throw Exception('History error: ${response.statusCode}');
  }

  // ── Delete a session ──────────────────────────────────────────────────────
  static Future<void> deleteSession(String sessionId) async {
    await http.delete(
      Uri.parse('$_baseUrl/session/$sessionId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
  }

  // ── Speech-to-text via /stt/transcribe ────────────────────────────────────
  // Posts the audio file to the gateway. Returns the transcribed text.
  // If `language` is omitted the server auto-detects (Tamil/Hindi/English
  // all work). Pass "ta", "hi", "en" explicitly to force a language.
  static Future<String> transcribe(File audioFile, {String? language}) async {
    final qs = (language != null && language.isNotEmpty)
        ? '?language=$language'
        : '';
    final uri = Uri.parse('$_baseUrl/stt/transcribe$qs');
    final req = http.MultipartRequest('POST', uri);
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    // Force a real audio MIME type instead of the default
    // application/octet-stream that Flutter's http library uses for files
    // it can't sniff. Without this the STT route rejected us with 400.
    final ext = audioFile.path.toLowerCase().split('.').last;
    final mime = switch (ext) {
      'm4a' || 'mp4' || 'aac' => MediaType('audio', 'mp4'),
      'wav'                   => MediaType('audio', 'wav'),
      'mp3'                   => MediaType('audio', 'mpeg'),
      'ogg'                   => MediaType('audio', 'ogg'),
      'webm'                  => MediaType('audio', 'webm'),
      _                       => MediaType('audio', 'mp4'),
    };
    req.files.add(await http.MultipartFile.fromPath(
      'audio_file', audioFile.path,
      contentType: mime,
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode != 200) {
      // Surface the failing URL too — makes "still 404" debuggable.
      throw Exception('STT failed (${response.statusCode}) at $uri\n${response.body}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (body['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      final err = body['error'] as String?;
      throw Exception(err ?? 'No speech detected.');
    }
    return text;
  }

  // ── Text-to-speech (returns MP3 bytes from the cloned voice) ──────────────
  // Hits the agent's /tts endpoint if available; falls back to a synth via
  // the WebSocket if /tts isn't implemented yet on the agent. For MVP we use
  // a small dedicated REST endpoint we add to the agent.
  static Future<List<int>> synthesizeSpeech(String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/tts'),
      headers: await _headers(),
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('TTS failed (${response.statusCode})');
    }
    return response.bodyBytes;
  }
}
