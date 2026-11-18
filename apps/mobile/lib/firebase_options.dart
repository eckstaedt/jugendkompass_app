import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for the Jugendkompass app.
///
/// Generated manually from GoogleService-Info.plist and google-services.json.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCaUJJwfEZALTVTGjsoXei5uz6uF8v03_Q',
    appId: '1:443036016738:android:f1c650fac9595bc619b13b',
    messagingSenderId: '443036016738',
    projectId: 'jugendkompass-46aa7',
    storageBucket: 'jugendkompass-46aa7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCNhdcgO4n_6rKN4FBw3qosyn-XjH938LU',
    appId: '1:443036016738:ios:4fa4a8818a92deda19b13b',
    messagingSenderId: '443036016738',
    projectId: 'jugendkompass-46aa7',
    storageBucket: 'jugendkompass-46aa7.appspot.com',
    iosBundleId: 'io.stephanus.jugendkompass',
  );
}
