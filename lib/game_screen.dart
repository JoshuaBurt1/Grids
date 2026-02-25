import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tile_model.dart';
import 'highscores_screen.dart';


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
  bool _isEnding = false;

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
    // 1. IMMEDIATE GUARD: If we are already ending or clicks are disabled, 
    // exit before even checking the tile logic.
    if (_isEnding || !_canClick || _cells[index].isHighlighted) return;

    if (_cells[index].isCorrect) {
      setState(() {
        _cells[index].isHighlighted = true;
        _clickCount++;
        
        if (_clickCount == _tilesCount) {
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
      // 2. WRONG CLICK: Call end game immediately
      _endGame();
    }
  }

  Future<void> _endGame() async {
    if (_isEnding) return;

    setState(() {
      _isEnding = true;
      _canClick = false;
    });

    _timer?.cancel();
    String? newDocId; // This is null by default

    try {
      final CollectionReference highScores = 
          FirebaseFirestore.instance.collection('grids_highscores');

      // Attempt to add the score
      DocumentReference docRef = await highScores.add({
        'player_name': widget.playerName,
        'high_score': _scoreValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Success! Now we have a real ID
      newDocId = docRef.id;

      await _distributeRewards(_scoreValue);

    } catch (e) {
      // If it fails (e.g., Guest has no permission), newDocId remains null
      print("Error in end game sequence: $e");
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HighscoresScreen(
            // Pass the ID, but your HighscoresScreen MUST check if it's null 
            // before calling Firestore with it.
            highlightDocId: newDocId, 
          ),
        ),
      );
    }
  }

  // Place this inside _GameScreenState
  Future<void> _distributeRewards(int playerScore) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final collection = FirebaseFirestore.instance.collection('grids_highscores');
    
    // Aggregate queries are efficient and perfect for percentile math
    AggregateQuerySnapshot totalSnapshot = await collection.count().get();
    int totalPlayers = totalSnapshot.count ?? 1;

    AggregateQuerySnapshot belowSnapshot = await collection
        .where('high_score', isLessThan: playerScore)
        .count()
        .get();
    int playersBelow = belowSnapshot.count ?? 0;

    double percentile = (playersBelow / totalPlayers) * 100;
    int gemsEarned = (percentile / 10).floor(); 

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'gems': FieldValue.increment(gemsEarned),
    });
    
    print("Gems Awarded: $gemsEarned (Percentile: ${percentile.toStringAsFixed(1)}%)");
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
