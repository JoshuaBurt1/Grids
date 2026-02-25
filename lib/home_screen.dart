import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'highscores_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "MEMORY GAME",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 40),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Enter Name",
                    border: OutlineInputBorder(), 
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          String name = _nameController.text.trim();
                          if (name.isEmpty) name = "Guest"; 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameScreen(playerName: name),
                            ),
                          );
                        },
                        child: const Text("Start Game"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HighscoresScreen()),
                        ),
                        child: const Text("View High Scores"),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}