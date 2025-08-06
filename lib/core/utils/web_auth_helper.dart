import 'package:flutter/foundation.dart';

/// Helper class for web authentication setup
class WebAuthHelper {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;
  
  /// Debug info for web authentication
  static void printWebAuthDebugInfo() {
    if (kIsWeb) {
      print('🌐 Running on Web Platform');
      print('📋 For Google Sign-in to work on web, ensure:');
      print('   1. Web OAuth client ID is configured in Firebase Console');
      print('   2. Authorized domains include your web domain');
      print('   3. Firebase SDK is loaded in web/index.html');
      print('   4. Google Sign-in SDK is loaded in web/index.html');
    } else {
      print('📱 Running on Mobile Platform');
    }
  }
  
  /// Instructions for Firebase Console setup
  static const String webOAuthSetupInstructions = '''
🚀 Web OAuth Client ID Setup Instructions:

1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your project: holy-love-2025-07-11
3. Go to Authentication → Sign-in method
4. Click on Google provider
5. Under "Web SDK configuration", you'll see your Web client ID
6. Copy the Web client ID (format: xxxxx.apps.googleusercontent.com)

Alternative method:
1. Go to Google Cloud Console (https://console.cloud.google.com)
2. Select project: holy-love-2025-07-11
3. Go to APIs & Services → Credentials
4. Look for "Web client" under OAuth 2.0 Client IDs
5. Copy the Client ID

Then update web/index.html with:
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID">

Also ensure these domains are authorized:
- localhost:8080 (for development)
- Your production domain
''';
}