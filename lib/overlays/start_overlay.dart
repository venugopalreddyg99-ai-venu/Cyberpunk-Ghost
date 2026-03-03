import 'package:flutter/material.dart';

import '../game/galaxy_defender_game.dart';

class StartOverlay extends StatelessWidget {
  final GalaxyDefenderGame game;

  const StartOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'GALAXY DEFENDER',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 10.0,
                  color: Colors.blue,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'HIGH SCORE: ${game.highScore}',
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              shadows: [
                Shadow(color: Colors.redAccent, blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              game.startGame();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              backgroundColor: Colors.white10,
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.cyan, width: 2),
            ),
            child: const Text('ENGAGE', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }
}
