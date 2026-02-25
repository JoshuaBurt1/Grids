import 'package:flutter/material.dart';
import 'home_screen.dart'; // Import your logic here

void main() {
  runApp(const MemoryGameApp());
}

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Point this to your converted Home Screen widget
      home: const HomeScreen(), 
    );
  }
}