import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // 다른 플랫폼 지원을 위한 옵션들은 나중에 추가할 수 있습니다
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCnp4izw1rwY9pPV-bAak7iyDuQV-Rhzd0',
    appId: '1:1008606267382:web:fa057a0b9a56f29d2e69d7',
    messagingSenderId: '1008606267382',
    projectId: 'renate-project',
    authDomain: 'renate-project.firebaseapp.com',
    storageBucket: 'renate-project.appspot.com',
    measurementId: 'G-TW5YJB78TP',
  );
} 