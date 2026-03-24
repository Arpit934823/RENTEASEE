import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC-x2DSdBYhlAzVoHIg2llV0RRybHPeVvk',
    appId: '1:101340260529:android:6b12485e2daff841bf9a90',
    messagingSenderId: '101340260529',
    projectId: 'rentease-1bf37',
    storageBucket: 'rentease-1bf37.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAdw6Tz89VqiM6yYp_gi7dba2BmRQRjX-M',
    appId: '1:101340260529:web:aff4b87d31265799bf9a90',
    messagingSenderId: '101340260529',
    projectId: 'rentease-1bf37',
    authDomain: 'rentease-1bf37.firebaseapp.com',
    storageBucket: 'rentease-1bf37.firebasestorage.app',
    measurementId: 'G-YL6HCFSPW1',
  );

}