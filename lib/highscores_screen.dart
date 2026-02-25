import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HighscoresScreen extends StatelessWidget {
  const HighscoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Blue Sequence: The connection to the 'memory_highscores' collection is orthogonal logic.
    final Stream<QuerySnapshot> _scoresStream = FirebaseFirestore.instance
        .collection('memory_highscores')
        .orderBy('high_score', descending: true)
        .limit(10) // Showing top 10 as requested
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Top 10 Highscores")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _scoresStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No scores yet. Be the first!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            // Separator ensures a clean look with no borders around factors/powers
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade300,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String name = data['player_name'] ?? 'Anonymous';
              final int score = data['high_score'] ?? 0;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text("${index + 1}"),
                ),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  "$score",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}