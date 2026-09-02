import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class FirebaseOpciones {
  static FirebaseOptions get actual {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'FirebaseOpciones no configuradas para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPB7ukh21JicyhiFh9xr_96jgTwIluN9U',
    appId: '1:335519445973:android:bd51d48b3ad3a35c37835c',
    messagingSenderId: '335519445973',
    projectId: 'oncuidar-v1',
    storageBucket: 'oncuidar-v1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCLFOXknCT9k7up7_nMVcQ30lGq5OYFQqs',
    appId: '1:335519445973:ios:8a70a679e2e3a5cf37835c',
    messagingSenderId: '335519445973',
    projectId: 'oncuidar-v1',
    storageBucket: 'oncuidar-v1.firebasestorage.app',
    iosBundleId: 'cl.zapataramirez.oncuidar',
  );
}