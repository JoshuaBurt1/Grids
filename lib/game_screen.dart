import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tile_model.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  const GameScreen({super.key, required this.playerName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<TileModel> _cells = List.generate(36, (_) => TileModel());
  int _tilesCount = 4;
  int _clickCount = 0;
  int _roundCount = 0;
  int _scoreValue = 0;
  double _timeLeft = 3.0;
  bool _canClick = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  void _startRound() {
    _timer?.cancel();
    setState(() {
      _clickCount = 0;
      _canClick = false;
      _timeLeft = 3.0;
      if (_roundCount % 3 == 0 && _roundCount != 0) _tilesCount++;
      
      // Reset cells
      for (var cell in _cells) {
        cell.isCorrect = false;
        cell.isHighlighted = false;
      }

      // Generate random pattern
      var random = Random();
      var indices = <int>{};
      while (indices.length < _tilesCount) {
        indices.add(random.nextInt(36));
      }
      for (var i in indices) {
        _cells[i].isCorrect = true;
        _cells[i].isHighlighted = true;
      }
    });

    // Start 3s Memorization Timer
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_timeLeft > 0.1) {
          _timeLeft -= 0.1;
        } else {
          _timer?.cancel();
          _startCopyPhase();
        }
      });
    });
  }

  void _startCopyPhase() {
    setState(() {
      _timeLeft = 5.0;
      _canClick = true;
      for (var cell in _cells) {
        cell.isHighlighted = false;
      }
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_timeLeft > 0.1) {
          _timeLeft -= 0.1;
        } else {
          _endGame();
        }
      });
    });
  }

  void _handleCellClick(int index) {
    if (!_canClick || _cells[index].isHighlighted) return;

    if (_cells[index].isCorrect) {
      setState(() {
        _cells[index].isHighlighted = true;
        _clickCount++;
        if (_clickCount == _tilesCount) {
          _scoreValue += 10 * (_roundCount ~/ 3 + 1);
          _roundCount++;
          _startRound();
        }
      });
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    // Logic for updating top 3 (simplified for brevity)
    List<String> scores = prefs.getStringList('highscores') ?? ["None:0", "None:0", "None:0"];
    // ... [Insert sorting logic similar to your Kotlin 'when' block] ...
    
    if (mounted) Navigator.pop(context); // Go back to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(child: Text("Player: ${widget.playerName} | Score: $_scoreValue")),
          Text("Time: ${_timeLeft.toStringAsFixed(1)}"),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
              itemCount: 36,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _handleCellClick(index),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    color: _cells[index].isHighlighted ? Colors.orange : Colors.blue,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}