import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/chat_session.dart';
import 'device_session.dart';

class AgentService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  // One shared client so repeated calls reuse the TCP/TLS connection
  // (HTTP keep-alive) instead of a fresh handshake per request.
  static final http.Client _client = http.Client();

  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    // X-Device-Id lets members / polls work before login and be adopted onto
    // the account on login so they sync across devices.
    final device = await DeviceSession.deviceId();
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': device,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // â”€â”€ Send a message, get AI reply â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<String> sendMessage(String sessionId, String message) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/chat'),
        headers: await _headers(),
        body: jsonEncode({
          'session_id': sessionId,
          'message': message,
          'flavor_id': AppConfig.flavorName,
        }),
      ).timeout(const Duration(seconds: 90));
    } on Exception catch (e) {
      // Network-level failure â€” surface a readable message
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

  // â”€â”€ Local cache (SharedPreferences) â€” cache-first for instant loads â”€â”€â”€â”€â”€â”€â”€
  static const _kSessionsKey = 'cache_sessions';
  static String _historyKey(String id) => 'cache_history_$id';

  static List<ChatSession> _parseSessions(String body) {
    final list = (jsonDecode(body) as Map)['sessions'] as List<dynamic>;
    return list.map((e) => ChatSession(
      id: e['id'] as String,
      title: e['title'] as String,
      createdAt: DateTime.parse(e['created_at'] as String),
      lastMessage: e['last_message'] as String? ?? '',
    )).toList();
  }

  static List<ChatMessage> _parseHistory(String body) {
    final list = (jsonDecode(body) as Map)['history'] as List<dynamic>;
    return list.map((e) => ChatMessage(
      role: e['role'] as String,
      content: e['content'] as String,
      timestamp: DateTime.tryParse(e['timestamp'] as String? ?? '') ?? DateTime.now(),
    )).toList();
  }

  /// Instant (~5 ms) read of the last-cached sessions. Empty if never cached.
  static Future<List<ChatSession>> getCachedSessions() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kSessionsKey);
    if (raw == null) return [];
    try { return _parseSessions(raw); } catch (_) { return []; }
  }

  /// Instant read of a session's last-cached messages. Empty if never cached.
  static Future<List<ChatMessage>> getCachedHistory(String sessionId) async {
    final raw = (await SharedPreferences.getInstance()).getString(_historyKey(sessionId));
    if (raw == null) return [];
    try { return _parseHistory(raw); } catch (_) { return []; }
  }

  // â”€â”€ List all sessions from backend (caches the response on success) â”€â”€â”€â”€â”€â”€â”€
  static Future<List<ChatSession>> getSessions() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/sessions'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        (await SharedPreferences.getInstance()).setString(_kSessionsKey, response.body);
        return _parseSessions(response.body);
      }
    } catch (_) {
      // Backend unreachable â€” return empty list so the UI still works
    }
    return [];
  }

  // â”€â”€ Get full message history for a session (caches on success) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<List<ChatMessage>> getHistory(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/history/$sessionId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      (await SharedPreferences.getInstance()).setString(_historyKey(sessionId), response.body);
      return _parseHistory(response.body);
    }
    throw Exception('History error: ${response.statusCode}');
  }

  // â”€â”€ Delete a session â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> deleteSession(String sessionId) async {
    await _client.delete(
      Uri.parse('$_baseUrl/session/$sessionId'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
  }

  // â”€â”€ User profile (per-uid, synced across devices) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/profile'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<bool> updateProfile({String? name, String? city}) async {
    try {
      final r = await _client.put(
        Uri.parse('$_baseUrl/profile'),
        headers: await _headers(),
        body: jsonEncode({'name': ?name, 'city': ?city}),
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> uploadAvatar(File image) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/profile/avatar'));
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.files.add(await http.MultipartFile.fromPath('file', image.path));
    final resp = await req.send().timeout(const Duration(seconds: 30));
    return resp.statusCode == 200;
  }

  // Returns the avatar bytes for the logged-in user, or null if none (404).
  static Future<List<int>?> downloadAvatar() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/profile/avatar'), headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) return r.bodyBytes;
    } catch (_) {}
    return null;
  }

  // â”€â”€ Complaints â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>?> registerComplaint({
    required String title,
    String description = '',
    String category = 'General',
    String subcategory = '',
    String department = '',
    String district = '',
    String taluk = '',
    String localBody = '',
    String village = '',
    String ward = '',
    String pincode = '',
    String address = '',
    String previousRef = '',
    bool isUrgent = false,
    File? file,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/complaints'));
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.headers['X-Device-Id'] = await DeviceSession.deviceId();
      req.fields['title'] = title;
      req.fields['description'] = description;
      req.fields['category'] = category;
      req.fields['subcategory'] = subcategory;
      req.fields['department'] = department;
      req.fields['district'] = district;
      req.fields['taluk'] = taluk;
      req.fields['local_body'] = localBody;
      req.fields['village'] = village;
      req.fields['ward'] = ward;
      req.fields['pincode'] = pincode;
      req.fields['address'] = address;
      req.fields['previous_ref'] = previousRef;
      req.fields['is_urgent'] = isUrgent.toString();
      if (file != null) {
        req.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final r = await http.Response.fromStream(streamed);
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // Downloads a complaint's attachment (authed). Returns bytes + mime, or null.
  static Future<({List<int> bytes, String mime})?> complaintAttachment(String complaintId) async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/complaints/$complaintId/attachment'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 30));
      if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
        return (bytes: r.bodyBytes, mime: r.headers['content-type'] ?? 'application/octet-stream');
      }
    } catch (_) {}
    return null;
  }

  // â”€â”€ Membership (Join TVK) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>?> registerMember(Map<String, String> data) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/members'),
        headers: await _headers(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  /// Every membership registered under the logged-in account, oldest first.
  /// Server-side per-uid, so the same login sees the same list on any device.
  static Future<List<Map<String, dynamic>>> listMembers() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/members'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map<String, dynamic>)['members'] as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<Map<String, dynamic>?> getMember() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/members/me'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> getComplaints() async {
    try {
      final r = await _client.get(Uri.parse('$_baseUrl/complaints'), headers: await _headers())
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['complaints'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  // â”€â”€ Community polls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>?> createPoll({
    required String question,
    required List<String> options,
    int durationDays = 2,
  }) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/polls'),
        headers: await _headers(),
        body: jsonEncode({
          'question': question,
          'options': options,
          'duration_days': durationDays,
          'flavor_id': AppConfig.flavorName,
        }),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Forum (shared across every user) ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listForumPosts(
      {String status = '', bool mine = false}) async {
    try {
      final q = 'flavor_id=${AppConfig.flavorName}'
          '${status.isEmpty ? '' : '&status=$status'}'
          '${mine ? '&mine=true' : ''}';
      final r = await _client.get(
        Uri.parse('$_baseUrl/forum/posts?$q'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['posts'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  /// Absolute URL of a post's uploaded attachment (image/video).
  static String forumMediaUrl(String postId) =>
      '$_baseUrl/forum/posts/$postId/media';

  static Future<Map<String, dynamic>?> createForumPost({
    required String text,
    required String userName,
    String status = 'approved',
    File? file,
  }) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/forum/posts'));
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.headers['X-Device-Id'] = await DeviceSession.deviceId();
      req.fields['text'] = text;
      req.fields['user_name'] = userName;
      req.fields['status'] = status;
      req.fields['flavor_id'] = AppConfig.flavorName;
      if (file != null) {
        req.files.add(await http.MultipartFile.fromPath('file', file.path));
      }
      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final r = await http.Response.fromStream(streamed);
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<void> deleteForumPost(String postId) async {
    try {
      await _client.delete(
        Uri.parse('$_baseUrl/forum/posts/$postId'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  static Future<void> setForumPostStatus(String postId, String status) async {
    try {
      await _client.post(
        Uri.parse('$_baseUrl/forum/posts/$postId/status?status=$status'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  /// Returns `{liked, like_count}` — null when the call failed.
  static Future<Map<String, dynamic>?> toggleForumLike(String postId) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/forum/posts/$postId/like'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> listForumComments(String postId) async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/forum/posts/$postId/comments'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['comments'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<Map<String, dynamic>?> addForumComment(
      String postId, String text, String userName) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/forum/posts/$postId/comments'),
        headers: await _headers(),
        body: jsonEncode({'text': text, 'user_name': userName}),
      ).timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<Map<String, dynamic>>> listToolkit(String kind) async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/toolkit?flavor_id=${AppConfig.flavorName}'
            '&kind=${Uri.encodeQueryComponent(kind)}'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['items'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<List<Map<String, dynamic>>> listPolls() async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/polls?flavor_id=${AppConfig.flavorName}'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['polls'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<bool> votePoll(int pollId, int optionIndex) async {
    try {
      final r = await _client.post(
        Uri.parse('$_baseUrl/polls/$pollId/vote'),
        headers: await _headers(),
        body: jsonEncode({'option_index': optionIndex}),
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<int> pollsParticipated() async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/polls/participated'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) return (jsonDecode(r.body) as Map)['count'] as int? ?? 0;
    } catch (_) {}
    return 0;
  }

  // â”€â”€ News + Events (admin-published content) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<List<Map<String, dynamic>>> listNews() async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/news?flavor_id=${AppConfig.flavorName}'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['news'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  static Future<List<Map<String, dynamic>>> listEvents() async {
    try {
      final r = await _client.get(
        Uri.parse('$_baseUrl/events?flavor_id=${AppConfig.flavorName}'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final list = (jsonDecode(r.body) as Map)['events'] as List<dynamic>;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return const [];
  }

  // â”€â”€ Speech-to-text via /stt/transcribe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

    // The server sends a human-readable `error` for the cases a user can act
    // on (nothing heard, unsupported language). Show that as-is; only fall
    // back to a generic apology when there is nothing usable to show.
    String? serverError;
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
      final e = (body['error'] as String?)?.trim();
      if (e != null && e.isNotEmpty) serverError = e;
    } catch (_) {}

    if (response.statusCode != 200) {
      developer.log('STT ${response.statusCode} at $uri — ${response.body}');
      throw Exception(serverError ??
          'Sorry, I could not hear you clearly. Please try again.');
    }

    final text = (body?['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      throw Exception(serverError ??
          'Sorry, I did not catch that. Please speak again.');
    }
    return text;
  }

  // â”€â”€ Cache probe â€” does NOT download audio â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Asks the agent "is the cloned-voice audio for this reply already on disk?"
  // Returns true only when EVERY sentence is cached (otherwise replay would
  // be partial and broken). Used by the per-message speaker icon to decide
  // whether to render at all.
  static Future<bool> isSpeechCached(String text) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/tts/cached'),
        headers: await _headers(),
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['cached'] == true;
    } catch (_) {
      return false;
    }
  }

  // â”€â”€ Strict cache lookup â€” NEVER calls Fish â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Returns MP3 bytes if the agent already has them on disk, or null if not.
  // Used by the per-message speaker button so replays only ever come from
  // our cached data â€” silent if a sentence wasn't pre-cached.
  static Future<List<int>?> synthesizeSpeechCached(String text) async {
    final sw = Stopwatch()..start();
    final response = await _client.post(
      Uri.parse('$_baseUrl/tts?strict_cache=true'),
      headers: await _headers(),
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 10));
    sw.stop();

    if (response.statusCode == 404) {
      developer.log(
        '[TTS] strict MISS  in ${sw.elapsedMilliseconds} ms  text=${_preview(text)}',
        name: 'tts',
      );
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception('TTS cached failed (${response.statusCode})');
    }
    _logCacheHeader(response, sw.elapsedMilliseconds, text);
    return response.bodyBytes;
  }

  // â”€â”€ Cache-first TTS (cache â†’ cloud fallback) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Calls /tts WITHOUT strict_cache. Server logic:
  //   1. If MP3 already on disk under sha256(text|voice|engine) â†’ return HIT (cheap).
  //   2. Else synthesise via Fish, store on disk, return MISS (one-time cost).
  // Used by the per-message speaker icon so EVERY AI reply can be replayed:
  // first tap may hit Fish once and bank the cache; every subsequent tap
  // anywhere on the device, or any other device sharing this server, is free.
  static Future<List<int>> synthesizeSpeech(String text) async {
    final sw = Stopwatch()..start();
    final response = await _client.post(
      Uri.parse('$_baseUrl/tts'),
      headers: await _headers(),
      body: jsonEncode({'text': text}),
    ).timeout(const Duration(seconds: 30));
    sw.stop();

    if (response.statusCode != 200) {
      throw Exception('TTS failed (${response.statusCode})');
    }
    _logCacheHeader(response, sw.elapsedMilliseconds, text);
    return response.bodyBytes;
  }

  // Surface the X-Cache header in the Flutter console so the client side
  // matches what the server prints. HIT means free, MISS means a Fish call.
  static void _logCacheHeader(http.Response r, int totalMs, String text) {
    final cache = r.headers['x-cache'] ?? '??';
    final serverMs = r.headers['x-cache-ms'] ?? '?';
    developer.log(
      '[TTS] $cache  ${r.bodyBytes.length}B  net=${totalMs}ms server=${serverMs}ms  text=${_preview(text)}',
      name: 'tts',
    );
  }

  static String _preview(String t) {
    final s = t.replaceAll('\n', ' ');
    return s.length <= 40 ? s : '${s.substring(0, 40)}...';
  }
}
