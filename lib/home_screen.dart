import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'game_screen.dart';
import 'highscores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  // Using signInWithPopup resolves the 'accessToken' and constructor issues on Web
  Future<void> _handleGoogleSignIn() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      
      final String uid = userCredential.user!.uid;

      // Update user profile - Logic is orthogonal to the auth provider [cite: 2026-02-11]
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'last_login': FieldValue.serverTimestamp(),
        'display_name': userCredential.user?.displayName,
        'gems': FieldValue.increment(0), 
      }, SetOptions(merge: true));

      if (mounted) setState(() {}); 
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // 1. Gem Display (Top Right)
          if (user != null)
            Positioned(
              top: 40,
              right: 20,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final int gems = data?['gems'] ?? 0;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.diamond, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "$gems",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.blue),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // 2. Main Content
          SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "MEMORY GAME",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.blue),
                  ),
                  const SizedBox(height: 40),

                  // Conditional UI: Show Login or Game Menu
                  if (user == null)
                    _buildGoogleButton()
                  else
                    _buildGameMenu(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: OutlinedButton.icon(
        onPressed: _handleGoogleSignIn,
        icon: SvgPicture.string(
          '<svg width="18" height="18" viewBox="0 0 533.5 544.3" xmlns="http://www.w3.org/2000/svg"><path fill="#EA4335" d="M533.5 278.4c0-18.6-1.5-37-4.7-54.8H272.1v103.8h147.1c-6.2 33.4-25.9 61.7-55.1 80.7v66h88.9c52.1-48 80.5-118.7 80.5-195.7z"/><path fill="#34A853" d="M272.1 544.3c74.1 0 136.3-24.5 181.7-66.2l-88.9-66c-24.7 16.6-56.4 26.5-92.7 26.5-71.3 0-131.7-48.1-153.4-112.6H27.6v70.7c45.2 89.6 137.9 147.6 244.5 147.6z"/><path fill="#4A90E2" d="M118.7 326c-10.4-31-10.4-64.5 0-95.5V159.7H27.6c-37.7 75.2-37.7 165.1 0 240.3l91.1-74z"/><path fill="#FBBC05" d="M272.1 106.1c40.3-.6 79.3 14.7 109.1 43.1l81.5-81.5C413.9 24.9 344.7-1 272.1 0 165.5 0 72.8 58 27.6 147.6l91.1 70.8c21.7-64.5 82.2-112.3 153.4-112.3z"/></svg>',
          height: 18,
        ),
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          side: const BorderSide(color: Colors.blue), // Design choice: light blue border instead of grey
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGameMenu() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Enter Player Name",
              filled: true,
              fillColor: Colors.blue.shade50,
              border: UnderlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                String name = _nameController.text.trim().isEmpty ? "Guest" : _nameController.text.trim();
                Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(playerName: name)));
              },
              child: const Padding(padding: EdgeInsets.all(16.0), child: Text("Start Game")),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HighscoresScreen())),
            child: const Text("View High Scores"),
          ),
          // Logout option to test the orthogonal auth states
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              setState(() {});
            },
            child: Text("Sign Out", style: TextStyle(color: Colors.red.shade300, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}