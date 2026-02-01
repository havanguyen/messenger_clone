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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0LpnpCyY--Yj-g95DdwwEoAEo-u9pH18',
    appId: '1:850801685937:web:75c8407f1899cdc44b3990',
    messagingSenderId: '850801685937',
    projectId: 'messenger-c8782',
    authDomain: 'messenger-c8782.firebaseapp.com',
    storageBucket: 'messenger-c8782.firebasestorage.app',
    measurementId: 'G-REH05FBBLG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBHwlTxvplTfsT2bNd_ZgFp4unwDVHI8ZM',
    appId: '1:850801685937:android:2a3af25c3736a3654b3990',
    messagingSenderId: '850801685937',
    projectId: 'messenger-c8782',
    storageBucket: 'messenger-c8782.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCegYQATDVQatZcrWZdsLx6BWPVv_icchE',
    appId: '1:850801685937:ios:c610508a631d4a2d4b3990',
    messagingSenderId: '850801685937',
    projectId: 'messenger-c8782',
    storageBucket: 'messenger-c8782.firebasestorage.app',
    iosClientId: '850801685937-isbmac2rt1mmtmkjo69sgdt4f52p7p3v.apps.googleusercontent.com',
    iosBundleId: 'com.example.messengerClone',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCegYQATDVQatZcrWZdsLx6BWPVv_icchE',
    appId: '1:850801685937:ios:c610508a631d4a2d4b3990',
    messagingSenderId: '850801685937',
    projectId: 'messenger-c8782',
    storageBucket: 'messenger-c8782.firebasestorage.app',
    iosClientId: '850801685937-isbmac2rt1mmtmkjo69sgdt4f52p7p3v.apps.googleusercontent.com',
    iosBundleId: 'com.example.messengerClone',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0LpnpCyY--Yj-g95DdwwEoAEo-u9pH18',
    appId: '1:850801685937:web:0bf16eb7fc2e5dd24b3990',
    messagingSenderId: '850801685937',
    projectId: 'messenger-c8782',
    authDomain: 'messenger-c8782.firebaseapp.com',
    storageBucket: 'messenger-c8782.firebasestorage.app',
    measurementId: 'G-6K93W4Y69V',
  );

}