// File generated to provide Firebase configuration in code.
//
// iOS reads its config from the bundled GoogleService-Info.plist by default,
// but that plist is not added to the Xcode Runner target, so the no-argument
// Firebase.initializeApp() fails on iOS with "No Firebase App '[DEFAULT]'".
// Supplying options explicitly from Dart makes init work on every platform
// regardless of whether the native config files are bundled.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for '
          '$defaultTargetPlatform.',
        );
    }
  }

  // Values taken from android/app/google-services.json
  // (client package_name "j.food.business").
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDWTvbB0gMgADIt6iisVPpgV2V72ESUqSM',
    appId: '1:547928555422:android:0cc9584596adbfa144208f',
    messagingSenderId: '547928555422',
    projectId: 'j-food-2a4d7',
    storageBucket: 'j-food-2a4d7.firebasestorage.app',
  );

  // Values taken from ios/Runner/GoogleService-Info.plist
  // (BUNDLE_ID "jfoob.business.perfectadv").
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDXBSsEvwOzWFqjPnsPXBHXM-xLcxuYwl8',
    appId: '1:547928555422:ios:bdbbab935d336aab44208f',
    messagingSenderId: '547928555422',
    projectId: 'j-food-2a4d7',
    storageBucket: 'j-food-2a4d7.firebasestorage.app',
    iosBundleId: 'jfoob.business.perfectadv',
  );
}
