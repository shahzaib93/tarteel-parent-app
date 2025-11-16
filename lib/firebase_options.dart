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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return windows; // Use same config as Windows
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDrXbi2vqMua2jwvoEOsdEccUEGZAonIS4',
    appId: '1:51402909238:web:c4160931526c345c7a9a97',
    messagingSenderId: '51402909238',
    projectId: 'tarteel-quran',
    authDomain: 'tarteel-quran.firebaseapp.com',
    storageBucket: 'tarteel-quran.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDrXbi2vqMua2jwvoEOsdEccUEGZAonIS4',
    appId: '1:51402909238:web:c4160931526c345c7a9a97',
    messagingSenderId: '51402909238',
    projectId: 'tarteel-quran',
    authDomain: 'tarteel-quran.firebaseapp.com',
    storageBucket: 'tarteel-quran.firebasestorage.app',
    measurementId: 'G-RDWBDV3HJ3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDrXbi2vqMua2jwvoEOsdEccUEGZAonIS4',
    appId: '1:51402909238:android:c4160931526c345c7a9a97',
    messagingSenderId: '51402909238',
    projectId: 'tarteel-quran',
    storageBucket: 'tarteel-quran.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDrXbi2vqMua2jwvoEOsdEccUEGZAonIS4',
    appId: '1:51402909238:ios:c4160931526c345c7a9a97',
    messagingSenderId: '51402909238',
    projectId: 'tarteel-quran',
    iosBundleId: 'com.tarteel.parent',
    storageBucket: 'tarteel-quran.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDrXbi2vqMua2jwvoEOsdEccUEGZAonIS4',
    appId: '1:51402909238:ios:c4160931526c345c7a9a97',
    messagingSenderId: '51402909238',
    projectId: 'tarteel-quran',
    iosBundleId: 'com.tarteel.parent',
    storageBucket: 'tarteel-quran.firebasestorage.app',
  );
}
