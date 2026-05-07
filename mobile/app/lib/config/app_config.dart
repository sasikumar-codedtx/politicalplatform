class AppConfig {
  static const String flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'india-pm');
  static const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://192.168.1.37:8001');

  static const Map<String, FlavorConfig> _flavors = {
    'india-pm': FlavorConfig(
      appName: 'India PM',
      primaryColor: 0xFF138808,
      secondaryColor: 0xFFFF9933,
    ),
  };

  static FlavorConfig get current => _flavors[flavorName] ?? _flavors['india-pm']!;
}

class FlavorConfig {
  final String appName;
  final int primaryColor;
  final int secondaryColor;

  const FlavorConfig({
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
  });
}
