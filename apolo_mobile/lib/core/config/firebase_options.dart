import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Firebase configuration for Apolo Real-time Chat & Push (`apolo-chat-e3ccf`).
class ApoloFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-cSxkhWLjLPMexsAup9dsIomo1ps11cU',
    authDomain: 'apolo-chat-e3ccf.firebaseapp.com',
    projectId: 'apolo-chat-e3ccf',
    storageBucket: 'apolo-chat-e3ccf.firebasestorage.app',
    messagingSenderId: '293222708485',
    appId: '1:293222708485:web:ba548646ce77f24486f36c',
    measurementId: 'G-0N86SLBJLG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCKMIN3bQGY0ejzmlNnH8768F7Ce9KuSMw',
    appId: '1:293222708485:android:24ea5ff880a4f29086f36c',
    messagingSenderId: '293222708485',
    projectId: 'apolo-chat-e3ccf',
    storageBucket: 'apolo-chat-e3ccf.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgxWOaZhtWGxKskNv9swX-m93Hooz46MY',
    appId: '1:293222708485:ios:f60aeb0505ae49b586f36c',
    messagingSenderId: '293222708485',
    projectId: 'apolo-chat-e3ccf',
    storageBucket: 'apolo-chat-e3ccf.firebasestorage.app',
    iosBundleId: 'ma.apolo.apoloMobile',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }
}
