import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions currentPlatform = FirebaseOptions(
    apiKey: "AIzaSyB1jhXYM_1nkOpvkhokcik9_zYSrSenRRM",
    authDomain: "squarehexagon-holdings.firebaseapp.com",
    projectId: "squarehexagon-holdings",
    storageBucket: "squarehexagon-holdings.firebasestorage.app",
    messagingSenderId: "702841156351",
    appId: "1:702841156351:web:b105027698de92b56d52ca",
    measurementId: "G-QV7Q6LZZHJ"
  );

  static Future<void> init() async {
    await Firebase.initializeApp(options: currentPlatform);
  }
}