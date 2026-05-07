import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class ChatStorage {
  static const String _sessionsKey = 'chat_sessions';
  static const String _messagesPrefix = 'messages_';

  static Future<List<ChatSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => ChatSession.fromJson(e)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    await prefs.setString(_sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  static Future<List<ChatMessage>> getMessages(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_messagesPrefix$sessionId');
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<void> saveMessage(String sessionId, ChatMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessages(sessionId);
    messages.add(message);
    await prefs.setString(
        '$_messagesPrefix$sessionId', jsonEncode(messages.map((m) => m.toJson()).toList()));
  }

  static Future<void> deleteSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await prefs.setString(_sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
    await prefs.remove('$_messagesPrefix$sessionId');
  }
}
