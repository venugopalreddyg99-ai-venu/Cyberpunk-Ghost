import 'package:flutter/material.dart';

import '../game/galaxy_defender_game.dart';

class GameOverOverlay extends StatefulWidget {
  final GalaxyDefenderGame game;

  const GameOverOverlay(this.game, {super.key});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SYSTEM FAILURE',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 3.0,
                shadows: [
                  Shadow(color: Colors.red, blurRadius: 10, offset: Offset(2, -2)),
                  Shadow(color: Colors.blueAccent, blurRadius: 10, offset: Offset(-2, 2)), // Glitch effect approximation
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'FINAL SCORE: ${widget.game.highScore}', // We don't have direct access to internal _score, but we can just use highScore for now or update Game class to expose score.
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 40),
            
            // Future Ad Button Placeholder
            // ElevatedButton(onPressed: () {}, child: Text('EMERGENCY REPAIR (AD)')),
            // SizedBox(height: 15),

            ScaleTransition(
              scale: _scaleAnimation,
              child: ElevatedButton(
                onPressed: () {
                  widget.game.startGame();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Hard terminal edges
                ),
                child: const Text('REBOOT SYSTEM', style: TextStyle(fontSize: 20, letterSpacing: 2.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
