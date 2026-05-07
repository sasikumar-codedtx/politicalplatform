import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AgentService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static Future<String> sendMessage(String sessionId, String message) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'session_id': sessionId, 'message': message}),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String;
    }
    throw Exception('Agent error: ${response.statusCode}');
  }
}
