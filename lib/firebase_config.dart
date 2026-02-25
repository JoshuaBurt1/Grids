import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyBM3XixppIif9vvd8rwR8mML4xaTLf2JrQ",
    authDomain: "squarehexagon-games.firebaseapp.com",
    projectId: "squarehexagon-games",
    storageBucket: "squarehexagon-games.firebasestorage.app",
    messagingSenderId: "323592971309",
    appId: "1:323592971309:web:ca296a8f4eca5f8b8cc4a4",
    measurementId: "G-788TSS1VVF",
  );

  static Future<void> init() async {
    await Firebase.initializeApp(options: currentPlatform);
  }
}