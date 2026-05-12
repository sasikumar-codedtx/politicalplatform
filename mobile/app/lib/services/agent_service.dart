import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
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
    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: await _headers(),
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
        'persona': AppConfig.current.aiPersonaPrompt,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map)['reply'] as String;
    }
    throw Exception('Agent error: ${response.statusCode}');
  }

  // ── List all sessions from backend ────────────────────────────────────────
  static Future<List<ChatSession>> getSessions() async {
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
    throw Exception('Sessions error: ${response.statusCode}');
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
}
