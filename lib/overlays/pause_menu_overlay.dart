import 'dart:ui';
import 'package:flutter/material.dart';
import '../game/galaxy_defender_game.dart';
import '../screens/main_menu.dart';

class PauseMenuOverlay extends StatelessWidget {
  final GalaxyDefenderGame game;
  const PauseMenuOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Blur effect
        child: Container(
          color: Colors.black.withValues(alpha: 0.6), // Semi-transparent black glass
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SYSTEM HALTED',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    letterSpacing: 4.0,
                    shadows: [
                      Shadow(color: Colors.red, blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 50),

                // Resume Mission Button
                _CyberButton(
                  label: 'RESUME MISSION',
                  color: Colors.cyanAccent,
                  onPressed: () {
                    game.overlays.remove('PauseMenuOverlay');
                    game.resumeEngine();
                  },
                ),
                
                const SizedBox(height: 20),

                // Abort Mission Button
                _CyberButton(
                  label: 'ABORT MISSION',
                  color: Colors.orangeAccent,
                  onPressed: () {
                    // Navigate to Main Menu. Since GameWidget is full screen, 
                    // we pop the route (which takes us back to MainMenu).
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const MainMenu())
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CyberButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CyberButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
