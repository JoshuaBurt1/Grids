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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _showEmailLogin = false;
  bool _isRegistering = false; // Toggle between Login and Register

  // --- Auth Logic ---

  Future<void> _handleGoogleSignIn() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      await _syncUserProfile(userCredential.user);
    } catch (e) {
      _showError("Google Sign-In Error: $e");
    }
  }

  Future<void> _handleEmailAuth() async {
  try {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    UserCredential userCredential;
    if (_isRegistering) {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Optional: Update the Firebase Profile name immediately
      await userCredential.user?.updateDisplayName(_nameController.text.trim());
    } else {
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
    }
    await _syncUserProfile(userCredential.user);
  } on FirebaseAuthException catch (e) {
    // Your existing error handling is great! 
    _showError(e.code == 'operation-not-allowed' 
        ? "Enable Email/Password in Firebase Console!" 
        : e.message ?? "Auth failed");
  }
}

  Future<void> _syncUserProfile(User? user) async {
    if (user == null) return;
    
    // If it's an email user, user.displayName might be null.
    // We use the name from the controller as a fallback.
    String? nameToSave = user.displayName ?? _nameController.text.trim();
    if (nameToSave.isEmpty) nameToSave = "Player";

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'last_login': FieldValue.serverTimestamp(),
      'display_name': nameToSave,
      'gems': FieldValue.increment(0), 
    }, SetOptions(merge: true));
    
    if (mounted) setState(() {});
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          if (user != null) _buildGemDisplay(user.uid),
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
                  if (user == null) _buildLoginOptions() else _buildGameMenu(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGemDisplay(String uid) {
    return Positioned(
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
    );
  }

  Widget _buildLoginOptions() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          _buildGoogleButton(),
          const SizedBox(height: 12),
          if (!_showEmailLogin)
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _showEmailLogin = true),
              child: const Text("Sign in with Email"),
            )
          else ...[
            if (_isRegistering)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: "Player Name",
                    filled: true,
                    fillColor: Color(0xFFF0F7FF),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: "Email",
                filled: true,
                fillColor: Color(0xFFF0F7FF),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Password (min 6 chars)",
                filled: true,
                fillColor: Color(0xFFF0F7FF),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            // MAIN ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRegistering ? Colors.green : Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleEmailAuth,
                child: Text(
                  _isRegistering ? "CREATE ACCOUNT" : "LOGIN",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // TOGGLE BUTTON (More prominent)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => setState(() => _isRegistering = !_isRegistering),
                child: Text(
                  _isRegistering ? "Already have an account? Login" : "NEW USER? REGISTER HERE",
                  style: TextStyle(
                    color: _isRegistering ? Colors.blue : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showEmailLogin = false),
              child: const Text("Back"),
            ),
          ],
          const Divider(height: 40),
          // GUEST BUTTON WITH BORDER
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameScreen(playerName: "Guest")),
            ),
            child: const Text("Play as Guest (No Saving)", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: SvgPicture.string('<svg width="18" height="18" viewBox="0 0 533.5 544.3" xmlns="http://www.w3.org/2000/svg"><path fill="#EA4335" d="M533.5 278.4c0-18.6-1.5-37-4.7-54.8H272.1v103.8h147.1c-6.2 33.4-25.9 61.7-55.1 80.7v66h88.9c52.1-48 80.5-118.7 80.5-195.7z"/><path fill="#34A853" d="M272.1 544.3c74.1 0 136.3-24.5 181.7-66.2l-88.9-66c-24.7 16.6-56.4 26.5-92.7 26.5-71.3 0-131.7-48.1-153.4-112.6H27.6v70.7c45.2 89.6 137.9 147.6 244.5 147.6z"/><path fill="#4A90E2" d="M118.7 326c-10.4-31-10.4-64.5 0-95.5V159.7H27.6c-37.7 75.2-37.7 165.1 0 240.3l91.1-74z"/><path fill="#FBBC05" d="M272.1 106.1c40.3-.6 79.3 14.7 109.1 43.1l81.5-81.5C413.9 24.9 344.7-1 272.1 0 165.5 0 72.8 58 27.6 147.6l91.1 70.8c21.7-64.5 82.2-112.3 153.4-112.3z"/></svg>', height: 18),
      label: const Text('Sign in with Google'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Colors.blue), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                String name = _nameController.text.trim().isEmpty ? "Guest" : _nameController.text.trim();
                Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(playerName: name)));
              },
              child: const Padding(padding: EdgeInsets.all(16.0), child: Text("Start Game")),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HighscoresScreen())), child: const Text("View High Scores")),
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