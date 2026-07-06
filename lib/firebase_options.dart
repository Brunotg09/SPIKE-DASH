import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configurações do Firebase geradas para o projeto spike-dash-8f986.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não suporta esta plataforma: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDx0PLXN8VdxllMAT2Wyh57hBJYnoeth20',
    appId: '1:927191631737:android:a6943a670ad7d9620c91a8',
    messagingSenderId: '927191631737',
    projectId: 'spike-dash-8f986',
    storageBucket: 'spike-dash-8f986.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDx0PLXN8VdxllMAT2Wyh57hBJYnoeth20',
    appId: '1:927191631737:ios:a6943a670ad7d9620c91a8',
    messagingSenderId: '927191631737',
    projectId: 'spike-dash-8f986',
    storageBucket: 'spike-dash-8f986.firebasestorage.app',
    iosBundleId: 'com.example.spikeDashApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBTurEwZqTv5_S96LSbfZwoLUQANHGBoQI',
    appId: '1:927191631737:web:ca1f0f6734f0b90c0c91a8',
    messagingSenderId: '927191631737',
    projectId: 'spike-dash-8f986',
    storageBucket: 'spike-dash-8f986.firebasestorage.app',
    authDomain: 'spike-dash-8f986.firebaseapp.com',
    measurementId: 'G-Q31XY2RN9S',
  );
}
