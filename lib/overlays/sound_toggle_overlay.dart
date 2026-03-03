import 'package:flutter/material.dart';
import '../game/galaxy_defender_game.dart';

class SoundToggleOverlay extends StatefulWidget {
  final GalaxyDefenderGame game;

  const SoundToggleOverlay(this.game, {super.key});

  @override
  State<SoundToggleOverlay> createState() => _SoundToggleOverlayState();
}

class _SoundToggleOverlayState extends State<SoundToggleOverlay> {
  @override
  void initState() {
    super.initState();
    // Re-render when the sound preference loads if it was delayed 
    widget.game.soundEnabledNotifier.addListener(_onSoundChanged);
  }

  @override
  void dispose() {
    widget.game.soundEnabledNotifier.removeListener(_onSoundChanged);
    super.dispose();
  }

  void _onSoundChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isSoundEnabled = widget.game.soundEnabledNotifier.value;

    return Positioned(
      top: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          iconSize: 32,
          icon: Icon(
            isSoundEnabled ? Icons.volume_up : Icons.volume_off,
            color: isSoundEnabled ? Colors.greenAccent : Colors.redAccent,
          ),
          onPressed: () {
            widget.game.toggleSound();
          },
        ),
      ),
    );
  }
}
