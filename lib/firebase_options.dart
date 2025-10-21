// Temporary stub to allow app to build before running `flutterfire configure`.
// Replace this file with the generated one from FlutterFire when you connect
// your real Firebase project.

import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (Platform.isIOS || Platform.isMacOS) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCP-Ej9eusSHduSNphtXgd9OoVavKuWctI',
        appId: '1:783732863935:ios:4253b73d74edaf1bff270a',
        messagingSenderId: '783732863935',
        projectId: 'fir-setup-50828',
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


