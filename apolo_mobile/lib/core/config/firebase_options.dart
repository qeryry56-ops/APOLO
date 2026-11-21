import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration for Apolo Real-time Chat (`apolo-chat-e3ccf`).
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

  static FirebaseOptions get currentPlatform => web;
}
