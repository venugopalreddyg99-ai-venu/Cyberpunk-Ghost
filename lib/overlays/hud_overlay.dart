import 'package:flutter/material.dart';
import '../game/galaxy_defender_game.dart';

class HUDOverlay extends StatelessWidget {
  final GalaxyDefenderGame game;
  const HUDOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.healthNotifier,
      builder: (context, health, child) {
        // Calculate gradient color and width based on health
        Color healthColor = Colors.redAccent;
        if (health >= 50) {
          healthColor = Colors.greenAccent;
        } else if (health >= 25) {
          healthColor = Colors.orangeAccent;
        }

        // Percentage for UI width
        double healthPercent = health / 100.0;
        
        return SafeArea(
          child: Stack(
            children: [
              // Top-Left: System Integrity (Horizontal Health Bar)
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SYSTEM INTEGRITY',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        shadows: [Shadow(color: Colors.cyan, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 5),
                    
                    // Slanted container illusion using simple padding/decoration
                    Container(
                      width: 200,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 200 * healthPercent,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  healthColor.withValues(alpha: 0.4),
                                  healthColor,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: healthColor.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                )
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Top-Right: Pause Icon
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.pause, color: Colors.cyanAccent, size: 30),
                  onPressed: () {
                    game.pauseEngine();
                    game.overlays.add('PauseMenuOverlay');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
