import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/galaxy_defender_game.dart';
import 'overlays/start_overlay.dart';
import 'overlays/game_over_overlay.dart';
import 'overlays/sound_toggle_overlay.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Galaxy Protocol 2026',
      home: GameWidget(
        game: GalaxyDefenderGame(),
        overlayBuilderMap: {
          'StartOverlay': (context, GalaxyDefenderGame game) => StartOverlay(game),
          'GameOverOverlay': (context, GalaxyDefenderGame game) => GameOverOverlay(game),
          'SoundToggleOverlay': (context, GalaxyDefenderGame game) => SoundToggleOverlay(game),
        },
      ),
    ),
  );
}
