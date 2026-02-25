import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tile_model.dart';

class GameScreen extends StatefulWidget {
  final String playerName;
  const GameScreen({super.key, required this.playerName});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<TileModel> _cells = List.generate(36, (_) => TileModel());
  int _tilesCount = 3; 
  int _clickCount = 0;
  int _totalRounds = 0; 
  int _scoreValue = 0;
  double _timeLeft = 3.0;
  bool _canClick = false;
  bool _showLevelUp = false; 
  Timer? _timer;

  int get _multiplier => _tilesCount - 2;

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
      
      // Clean reset of all cells
      for (var cell in _cells) {
        cell.isCorrect = false;
        cell.isHighlighted = false;
      }

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
          // Orthogonal Logic: Score increases by 10 * the current multiplier [cite: 2026-02-11]
          _scoreValue += 10 * _multiplier; 
          _totalRounds++;
          
          if (_totalRounds % 3 == 0) {
            _tilesCount++; 
            _showLevelUp = true;
            _canClick = false; 
            
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _showLevelUp = false;
                  _startRound();
                });
              }
            });
          } else {
            _startRound();
          }
        }
      });
    } else {
      _endGame();
    }
  }

  Future<void> _endGame() async {
    _timer?.cancel();
    try {
      final CollectionReference highScores = 
          FirebaseFirestore.instance.collection('memory_highscores');

      await highScores.add({
        'player_name': widget.playerName,
        'high_score': _scoreValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Cloud Save Successful");
    } catch (e) {
      print("Error saving to Firebase: $e");
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The debug banner is removed in the MaterialApp wrapper usually, 
      // but we ensure it's off by setting this property if applicable.
      body: Container(
        width: double.infinity, // Expand to fill full browser width
        height: double.infinity, // Expand to fill full browser height
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Score: $_scoreValue",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${_multiplier}x Multiplier",
                        style: const TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              "Time: ${_timeLeft.toStringAsFixed(1)}s",
              style: TextStyle(
                fontSize: 28, 
                color: _timeLeft < 1.5 ? Colors.red : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: _showLevelUp ? 0.3 : 1.0,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800), // Optional: keeps grid from becoming too wide on ultra-wide screens
                        child: GridView.builder(
                          shrinkWrap: true, // Grid fits content
                          physics: const NeverScrollableScrollPhysics(), // Prevent internal scrolling
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            mainAxisSpacing: 12, // Increased spacing for large screens
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: 36,
                          itemBuilder: (context, index) {
                            final tile = _cells[index];
                            return GestureDetector(
                              onTap: () => _handleCellClick(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  color: tile.isHighlighted 
                                      ? Colors.orangeAccent 
                                      : Colors.blue.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8),
                                  // Borderless design maintained [cite: 2026-02-04]
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_showLevelUp)
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "LEVEL UP!",
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.orange,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                "Next: $_tilesCount Tiles",
                                style: const TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
             ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
