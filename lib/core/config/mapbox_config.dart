class MapboxConfig {
  static const String apiKey = 'pk.eyJ1Ijoic3BsaXRzdGF5IiwiYSI6ImNtZThsd3V1ZjBhYXMyanFhcDR3ZXZreXcifQ.aO9BpCIGBP1AfLXJ94ZBCg';
  
  static const String demoApiKey = '';
  
  static String get activeApiKey {
    return apiKey;
  }
  
  static bool get isConfigured {
    return activeApiKey.isNotEmpty && 
           activeApiKey != 'YOUR_MAPBOX_API_KEY_HERE';
  }
}
