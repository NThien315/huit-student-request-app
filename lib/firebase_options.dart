import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'TODO',
        appId: 'TODO',
        messagingSenderId: 'TODO',
        projectId: 'hdpe-sinhvien',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'TODO',
          appId: 'TODO',
          messagingSenderId: 'TODO',
          projectId: 'hdpe-sinhvien',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'TODO',
          appId: 'TODO',
          messagingSenderId: 'TODO',
          projectId: 'hdpe-sinhvien',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const FirebaseOptions(
          apiKey: 'TODO',
          appId: 'TODO',
          messagingSenderId: 'TODO',
          projectId: 'hdpe-sinhvien',
        );
    }
  }
}
