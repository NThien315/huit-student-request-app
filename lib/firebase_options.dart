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
        apiKey: 'AIzaSyBC_KDE77OY0t_D5lNdJoEnvmcGthkRH90',
        appId: '1:983678184026:android:a962d2ab305a5227a7c663',
        messagingSenderId: '983678184026',
        projectId: 'huit-student-request-app',
        storageBucket: 'huit-student-request-app.firebasestorage.app',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBC_KDE77OY0t_D5lNdJoEnvmcGthkRH90',
          appId: '1:983678184026:android:a962d2ab305a5227a7c663',
          messagingSenderId: '983678184026',
          projectId: 'huit-student-request-app',
          storageBucket: 'huit-student-request-app.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBC_KDE77OY0t_D5lNdJoEnvmcGthkRH90',
          appId: '1:983678184026:android:a962d2ab305a5227a7c663',
          messagingSenderId: '983678184026',
          projectId: 'huit-student-request-app',
          storageBucket: 'huit-student-request-app.firebasestorage.app',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return const FirebaseOptions(
          apiKey: 'AIzaSyBC_KDE77OY0t_D5lNdJoEnvmcGthkRH90',
          appId: '1:983678184026:android:a962d2ab305a5227a7c663',
          messagingSenderId: '983678184026',
          projectId: 'huit-student-request-app',
          storageBucket: 'huit-student-request-app.firebasestorage.app',
        );
    }
  }
}
