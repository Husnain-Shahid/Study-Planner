import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    } else if (Platform.isAndroid) {
      return android;
    } else if (Platform.isIOS) {
      return ios;
    }
    throw UnsupportedError('DefaultFirebaseOptions is not supported for this platform.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDKJyujWn-QIQP4qqoNcKUS0OWQUbSLNvE',
    authDomain: 'study-planner-276d0.firebaseapp.com',
    projectId: 'study-planner-276d0',
    storageBucket: 'study-planner-276d0.firebasestorage.app',
    messagingSenderId: '631958367644',
    appId: '1:631958367644:web:cd20c306557103c55cac59',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDKJyujWn-QIQP4qqoNcKUS0OWQUbSLNvE',
    authDomain: 'study-planner-276d0.firebaseapp.com',
    projectId: 'study-planner-276d0',
    storageBucket: 'study-planner-276d0.firebasestorage.app',
    messagingSenderId: '631958367644',
    appId: '1:631958367644:android:cd20c306557103c55cac59',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDKJyujWn-QIQP4qqoNcKUS0OWQUbSLNvE',
    authDomain: 'study-planner-276d0.firebaseapp.com',
    projectId: 'study-planner-276d0',
    storageBucket: 'study-planner-276d0.firebasestorage.app',
    messagingSenderId: '631958367644',
    appId: '1:631958367644:ios:cd20c306557103c55cac59',
  );
}

