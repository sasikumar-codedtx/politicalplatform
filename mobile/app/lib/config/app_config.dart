class AppConfig {
  static const String flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'tn-tvk',
  );
  // Gateway port (9000) — proxies to agent (8001), avatar-service (8002), gpu-avatar
  // (8003), stt (8004), tavus-service (8005). Mobile MUST hit the gateway so paths
  // like /stt/transcribe and /avatar-svc/* reach the right backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.8:9000',
  );

  static const Map<String, FlavorConfig> _flavors = {
    'tn-tvk': FlavorConfig(
      appName: 'TVK',
      govtName: 'Tamilaga Vettri Kazhagam',
      partyName: 'Tamilaga Vettri Kazhagam',
      leaderName: 'Honorable CM Vijay Sir',
      leaderTitle: 'President, TVK',
      leaderLocation: 'Chennai, Tamil Nadu',
      tagline: 'நாம் வெல்வோம்',
      taglineEn: 'Namma Velluvom',
      joinCtaLabel: 'Join TVK',
      primaryColor: 0xFFE40101,
      accentColor: 0xFFFFB300,
      backgroundColor: 0xFFF5F5F5,
      surfaceColor: 0xFFFFFFFF,
      borderColor: 0xFFEEEEEE,
      textPrimary: 0xFF1A1A1A,
      textSecondary: 0xFF666666,
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
      manifestoYears: ['2024', '2025', '2026', '2027', '2028'],
    ),
  };

  static FlavorConfig get current =>
      _flavors[flavorName] ?? _flavors['tn-tvk']!;
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
    required this.manifestoYears,
  });
}
