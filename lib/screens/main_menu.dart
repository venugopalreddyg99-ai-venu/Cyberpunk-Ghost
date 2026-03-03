import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'dart:math';

import '../game/galaxy_defender_game.dart';
import '../overlays/start_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/sound_toggle_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/pause_menu_overlay.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Simplified pulsating stars background using an AnimatedBuilder
  Widget _buildStarfield() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarfieldPainter(_animController.value),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF0D1B2A), // Dark Blue-Grey
                  Colors.black,
                ],
              ),
            ),
          ),
          
          // Starfield
          _buildStarfield(),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title with Glow Effect
                const Text(
                  'GALAXY PROTOCOL\n2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    shadows: [
                      Shadow(
                        color: Colors.cyan,
                        blurRadius: 15.0,
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        color: Colors.blueAccent,
                        blurRadius: 30.0, // Double glow
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),

                // Neumorphic Cyberpunk Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          body: GameWidget<GalaxyDefenderGame>(
                            game: GalaxyDefenderGame(),
                            overlayBuilderMap: {
                              'StartOverlay': (context, game) => StartOverlay(game), // We'll likely remove this later
                              'GameOverOverlay': (context, game) => GameOverOverlay(game),
                              'SoundToggleOverlay': (context, game) => SoundToggleOverlay(game),
                              'HUDOverlay': (context, game) => HUDOverlay(game),
                              'PauseMenuOverlay': (context, game) => PauseMenuOverlay(game),
                            },
                            initialActiveOverlays: const ['HUDOverlay', 'SoundToggleOverlay'], // Ensure HUD is active immediately
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.cyanAccent, width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'INITIALIZE SYSTEM',
                      style: TextStyle(
                        fontSize: 20,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final double animationValue;
  final Random _random = Random(42); // Fixed seed for stable stars

  _StarfieldPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    for (int i = 0; i < 50; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final radius = _random.nextDouble() * 2 + 0.5;
      
      // Make them twinkle based on our animation value
      // Assign random offsets so they don't all twinkle identically
      final offsetMultiplier = _random.nextDouble() * 2 * pi;
      final alpha = ((sin(animationValue * pi * 4 + offsetMultiplier) + 1) / 2 * 255).toInt();
      
      paint.color = Colors.white.withAlpha(alpha.clamp(50, 255)); 
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
