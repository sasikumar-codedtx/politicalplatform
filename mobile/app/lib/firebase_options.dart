import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('DefaultFirebaseOptions not configured for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBdCnP_28fgrtjfj1wt4J895NsPtHHBpyc',
    appId: '1:151735878015:android:707c6b21dba5593fe89a4a',
    messagingSenderId: '151735878015',
    projectId: 'political-platform-19d77',
    storageBucket: 'political-platform-19d77.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAeIUYjOBzYv3U1RdGAmhwarEW0CXTwJXE',
    appId: '1:151735878015:ios:56191dd500165368e89a4a',
    messagingSenderId: '151735878015',
    projectId: 'political-platform-19d77',
    storageBucket: 'political-platform-19d77.firebasestorage.app',
    iosBundleId: 'com.codedtx.politicalPlatform',
  );
}
