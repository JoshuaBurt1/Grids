import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HighscoresScreen extends StatelessWidget {
  const HighscoresScreen({super.key});

  Future<List<String>> _getScores() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('highscores') ?? ["Empty:0", "Empty:0", "Empty:0"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Highscores")),
      body: FutureBuilder<List<String>>(
        future: _getScores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return ListView(
            children: snapshot.data!.map((s) => ListTile(title: Text(s))).toList(),
          );
        },
      ),
    );
  }
}