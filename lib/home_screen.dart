import 'package:flutter/material.dart';
import 'game_screen.dart';

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
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Enter Name"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(context).unfocus(); // Hides keyboard
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(playerName: _nameController.text),
                  ),
                );
              },
              child: const Text("Start Game"),
            ),
          ],
        ),
      ),
    );
  }
}