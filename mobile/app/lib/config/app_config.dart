class AppConfig {
  static const String flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'tn-tvk');
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.1.37:8001');

  static const Map<String, FlavorConfig> _flavors = {
    'tn-tvk': FlavorConfig(
      appName: 'TVK',
      govtName: 'Tamilaga Vettri Kazhagam',
      partyName: 'Tamilaga Vettri Kazhagam',
      leaderName: 'Vijay',
      leaderTitle: 'President, TVK',
      leaderLocation: 'Chennai, Tamil Nadu',
      tagline: 'நாம் வெல்வோம்',
      taglineEn: 'Namma Velluvom',
      joinCtaLabel: 'Join TVK',
      primaryColor: 0xFFCC0000,
      accentColor: 0xFFFFB300,
      backgroundColor: 0xFF111111,
      surfaceColor: 0xFF1E1E1E,
      borderColor: 0xFF2A2A2A,
      textPrimary: 0xFFFFFFFF,
      textSecondary: 0xFF888888,
      aiPersonaPrompt: '''
You are Vijay (Joseph Vijay Chandrasekhar), Chief Minister of Tamil Nadu.

WHO YOU ARE:
You stand for social justice, equality, and the rights of every Tamil citizen. You speak plainly and with conviction. You are bilingual — if someone writes in Tamil, reply in Tamil; if in English, reply in English.

HOW YOU RESPOND:
- When someone shares a problem, acknowledge it with genuine empathy, then explain what the government is doing.
- When asked about policy, reference the five-year vision: clean water, digital classrooms, social justice, farmer welfare, youth employment.
- Be honest. Be direct. Never make up schemes or numbers.
- Keep replies to 3–5 sentences. Speak like a person, not a politician.
- Ask only ONE follow-up question if you need more information.

You represent every Tamil citizen. Treat every message as important.
''',
      manifestoYears: ['2026', '2027', '2028', '2029', '2030'],
    ),
    'india-pm': FlavorConfig(
      appName: 'India One',
      govtName: 'Government of India',
      partyName: 'Indian National Congress',
      leaderName: 'Rahul Gandhi',
      leaderTitle: 'Prime Minister of India',
      leaderLocation: 'New Delhi',
      tagline: 'हाथ बदलेगा हालात',
      taglineEn: 'Haath Badlega Halaat',
      joinCtaLabel: 'Join Congress',
      primaryColor: 0xFF19AAED,
      accentColor: 0xFFFF9933,
      backgroundColor: 0xFFF5F5F5,
      surfaceColor: 0xFFFFFFFF,
      borderColor: 0xFFE8E8E8,
      textPrimary: 0xFF1A1A1A,
      textSecondary: 0xFF666666,
      aiPersonaPrompt: '''
You are Rahul Gandhi, Prime Minister of India.

WHO YOU ARE:
You care deeply about farmers, youth, workers, and every ordinary Indian. You believe in the Constitution, social justice, and unity. You speak plainly and honestly.

HOW YOU RESPOND:
- If someone writes in Hindi, reply in Hindi. If in English, reply in English.
- When someone shares a problem, acknowledge it with real empathy, then explain what the government will do.
- When asked about policy, reference the Nyay Patra: Kisan Nyay, Yuva Nyay, Nari Nyay, Hissedari Nyay, Samvidhan Nyay.
- Be honest about challenges. Never make up data or schemes.
- Keep replies to 3–5 sentences. Speak like a person, not a press release.

You represent the hopes of every Indian citizen. Every message matters.
''',
      manifestoYears: ['2024', '2025', '2026', '2027', '2028'],
    ),
  };

  static FlavorConfig get current => _flavors[flavorName] ?? _flavors['tn-tvk']!;
}

class FlavorConfig {
  final String appName;
  final String govtName;
  final String partyName;
  final String leaderName;
  final String leaderTitle;
  final String leaderLocation;
  final String tagline;
  final String taglineEn;
  final String joinCtaLabel;
  final int primaryColor;
  final int accentColor;
  final int backgroundColor;
  final int surfaceColor;
  final int borderColor;
  final int textPrimary;
  final int textSecondary;
  final String aiPersonaPrompt;
  final List<String> manifestoYears;

  const FlavorConfig({
    required this.appName,
    required this.govtName,
    required this.partyName,
    required this.leaderName,
    required this.leaderTitle,
    required this.leaderLocation,
    required this.tagline,
    required this.taglineEn,
    required this.joinCtaLabel,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.aiPersonaPrompt,
    required this.manifestoYears,
  });
}
