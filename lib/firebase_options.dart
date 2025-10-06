// Temporary stub to allow app to build before running `flutterfire configure`.
// Replace this file with the generated one from FlutterFire when you connect
// your real Firebase project.

import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS || Platform.isMacOS) {
      return const FirebaseOptions(
        apiKey: 'stub-ios-api-key',
        appId: '1:000000000000:ios:stub',
        messagingSenderId: '000000000000',
        projectId: 'stub-project',
      );
    }
    if (Platform.isAndroid) {
      return const FirebaseOptions(
        apiKey: 'stub-android-api-key',
        appId: '1:000000000000:android:stub',
        messagingSenderId: '000000000000',
        projectId: 'stub-project',
      );
    }
    // Fallback for other platforms; web requires real options to work
    return const FirebaseOptions(
      apiKey: 'stub',
      appId: 'stub',
      messagingSenderId: 'stub',
      projectId: 'stub',
    );
  }
}


