import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player.dart';
import 'bullet.dart';
import 'enemy.dart';
import 'power_up.dart';

enum GameState { initial, playing, gameOver }

class GalaxyDefenderGame extends FlameGame with PanDetector, TapCallbacks, HasCollisionDetection {
  late PlayerShip player;
  
  // Exposing these for overlays
  int score = 0;
  final ValueNotifier<int> healthNotifier = ValueNotifier<int>(100);
  int highScore = 0;
  
  // Audio state
  final ValueNotifier<bool> soundEnabledNotifier = ValueNotifier<bool>(true);
  
  final Random _random = Random();
  
  GameState state = GameState.initial;
  
  int currentLevel = 1;
  late TextComponent _levelUpText;
  late TimerComponent _enemySpawner;
  late TimerComponent _powerUpSpawner;
  Color _bgColor = Colors.black;
  
  bool hasSpreadShot = false;
  late TimerComponent _spreadShotTimer;

  @override
  Color backgroundColor() => _bgColor;

  Future<ui.Image> _createStarfield(int numStars, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.x, size.y));
    final paint = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    for (int i = 0; i < numStars; i++) {
      final x = _random.nextDouble() * size.x;
      final y = _random.nextDouble() * size.y;
      final radius = _random.nextDouble() * 2 + 1;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    final picture = recorder.endRecording();
    return await picture.toImage(size.x.toInt(), size.y.toInt());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    debugMode = false; // Turn off X-Ray vision now that hitboxes are fixed

    // Load High Score and Sound Preference
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('high_score') ?? 0;
    soundEnabledNotifier.value = prefs.getBool('sound_enabled') ?? true;

    // Cache the high-fidelity audio files
    await FlameAudio.audioCache.loadAll(['cyber_storm.mp3', 'plasma_cannon.wav', 'bass_impact.wav']);
    
    // Start Background Music Loop
    if (soundEnabledNotifier.value) {
      FlameAudio.bgm.play('cyber_storm.mp3', volume: 0.6);
    }

    // Generate dynamic starfields
    final layer1 = await _createStarfield(100, Colors.grey.withValues(alpha: 0.5));
    final layer2 = await _createStarfield(75, Colors.blueGrey.withValues(alpha: 0.7));
    final layer3 = await _createStarfield(50, Colors.white);

    final parallaxComponent = ParallaxComponent(
      parallax: Parallax([
        ParallaxLayer(
          ParallaxImage(layer1),
          velocityMultiplier: Vector2(0, 10),
        ),
        ParallaxLayer(
          ParallaxImage(layer2),
          velocityMultiplier: Vector2(0, 20),
        ),
        ParallaxLayer(
          ParallaxImage(layer3),
          velocityMultiplier: Vector2(0, 40),
        ),
      ]),
    );

    add(parallaxComponent);

    // The camera will ensure the game adapts to screen size
    camera.viewfinder.anchor = Anchor.topLeft;

    // Show start overlay and sound toggle initially
    overlays.add('StartOverlay');
    overlays.add('SoundToggleOverlay');

    _levelUpText = TextComponent(
      text: 'LEVEL UP!',
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.yellowAccent,
          fontSize: 60,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
          shadows: [Shadow(color: Colors.red, blurRadius: 10)],
        ),
      ),
    );

    player = PlayerShip(position: size / 2);
    add(player);

    // Old HUD removed. We now use the HUDOverlay via the Flutter Widget Tree.

    _enemySpawner = TimerComponent(
      period: 1.0,
      repeat: true,
      onTick: _spawnEnemy,
    );
    add(_enemySpawner);
    
    _powerUpSpawner = TimerComponent(
      period: 12.0, // Spawn a power up roughly every 12 seconds
      repeat: true,
      onTick: _spawnPowerUp,
    );
    add(_powerUpSpawner);
    
    _spreadShotTimer = TimerComponent(
      period: 10.0,
      repeat: false,
      autoStart: false,
      onTick: () => hasSpreadShot = false,
    );
    add(_spreadShotTimer);
  }

  void startGame() {
    state = GameState.playing;
    overlays.remove('StartOverlay');
    overlays.remove('GameOverOverlay');
    
    // Restore Ducked BGM Volume
    if (soundEnabledNotifier.value) {
      FlameAudio.bgm.audioPlayer.setVolume(0.6);
    }
    
    // Reset properties
    score = 0;
    healthNotifier.value = 100;
    
    currentLevel = 1;
    _bgColor = Colors.black;
    _enemySpawner.timer.limit = 1.0;
    _powerUpSpawner.timer.reset();
    hasSpreadShot = false;
    _spreadShotTimer.timer.stop();
    
    // Clear old components
    children.whereType<Enemy>().forEach((enemy) => enemy.removeFromParent());
    children.whereType<Bullet>().forEach((bullet) => bullet.removeFromParent());
    children.whereType<PowerUp>().forEach((pu) => pu.removeFromParent());
    if (children.contains(player)) {
      player.removeFromParent();
    }
    
    // Re-add player
    player = PlayerShip(position: size / 2);
    add(player);
  }

  void _spawnEnemy() {
    if (state != GameState.playing) return;
    double xPos = _random.nextDouble() * size.x;
    
    double enemySpeed = 150.0;
    if (currentLevel == 2) enemySpeed = 200.0;
    if (currentLevel == 3) enemySpeed = 250.0;
    
    add(Enemy(position: Vector2(xPos, -30), speed: enemySpeed));
  }

  void _spawnPowerUp() {
    if (state != GameState.playing) return;
    double xPos = _random.nextDouble() * size.x;
    
    // 33% chance for Health, Shield, or SpreadShot
    int r = _random.nextInt(3);
    PowerUpType type = PowerUpType.health;
    if (r == 1) type = PowerUpType.shield;
    if (r == 2) type = PowerUpType.spreadShot;
    
    add(PowerUp(position: Vector2(xPos, -30), type: type));
  }

  void activateSpreadShot() {
    hasSpreadShot = true;
    _spreadShotTimer.timer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (state == GameState.playing) {
      _checkLevel();
    }
  }

  void _checkLevel() {
    int newLevel = 1;
    if (score >= 1000) {
      newLevel = 3;
    } else if (score >= 500) {
      newLevel = 2;
    }

    if (newLevel > currentLevel) {
      currentLevel = newLevel;
      _triggerLevelUp();
    }
  }

  void _triggerLevelUp() {
    if (!children.contains(_levelUpText)) {
      _levelUpText.position = size / 2;
      add(_levelUpText);
      Future.delayed(const Duration(seconds: 2), () {
        if (children.contains(_levelUpText)) {
          _levelUpText.removeFromParent();
        }
      });
    }

    // Apply level effects
    if (currentLevel == 2) {
      _bgColor = const Color(0xFF1A0B2E); // Dark Purple/Blue (Nebula Storm)
      _enemySpawner.timer.limit = 0.7; // Faster spawns
    } else if (currentLevel == 3) {
      _bgColor = const Color(0xFF330000); // Dark Red (Red Alert)
      _enemySpawner.timer.limit = 0.4; // Insane spawns
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (state != GameState.playing) return;
    player.position += info.delta.global;
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (state != GameState.playing) return;
    
    if (hasSpreadShot) {
      // Fire 3 bullets
      add(Bullet(position: player.position.clone() - Vector2(0, player.size.y)));
      // Note: Bullet component needs to be updated to support custom velocities/angles.
      // We will create the left and right bullets in a moment by adding a velocity field to Bullet.
      add(Bullet(position: player.position.clone() - Vector2(15, player.size.y), velocity: Vector2(-100, -800)));
      add(Bullet(position: player.position.clone() + Vector2(15, -player.size.y), velocity: Vector2(100, -800)));
    } else {
      // Fire a bullet just above the player
      add(Bullet(position: player.position.clone() - Vector2(0, player.size.y)));
    }
    
    // Dynamic Pro Pitch for Plasma Cannon
    double rndPitch = 0.9 + (_random.nextDouble() * 0.2); // Random pitch between 0.9 and 1.1
    playSound('plasma_cannon.wav', pitch: rndPitch);
  }

  void increaseScore(int amount) {
    score += amount;
    // We could expose score via a ValueNotifier as well if we wanted a separate score widget,
    // but the HUD can be updated manually if needed, or we just handle score on the Game Over screen.
  }

  // Old _updateHealthUI method removed as it's handled by HUDOverlay now.

  void restoreHealth() {
    if (state != GameState.playing) return;
    if (healthNotifier.value < 100) {
      healthNotifier.value = (healthNotifier.value + 20).clamp(0, 100).toInt();
    } else {
      // Bonus points if already at max health
      increaseScore(50);
    }
  }

  void playerHit() {
    if (state != GameState.playing) return;
    
    playSound('bass_impact.wav', volume: 1.0);
    healthNotifier.value -= 20;

    if (healthNotifier.value <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    if (state == GameState.gameOver) return;
    
    state = GameState.gameOver;
    playSound('bass_impact.wav', volume: 1.0);
    player.removeFromParent();
    
    // Duck BGM during Game Over screen
    if (soundEnabledNotifier.value) {
      FlameAudio.bgm.audioPlayer.setVolume(0.2);
    }
    
    // Save High Score
    if (score > highScore) {
      highScore = score;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('high_score', highScore);
      });
    }

    overlays.add('GameOverOverlay');
  }

  void spawnSmoke(Vector2 position) {
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 20,
          lifespan: 1.0,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2.random(Random()) * 200, // Random speed
            speed: Vector2.random(Random()) * 100 - Vector2(50, 50),
            position: position.clone(),
            child: CircleParticle(
              radius: 5,
              paint: Paint()..color = Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // --- Audio Helpers ---
  Future<void> playSound(String fileName, {double volume = 1.0, double pitch = 1.0}) async {
    if (soundEnabledNotifier.value) {
      AudioPlayer player = await FlameAudio.play(fileName, volume: volume);
      if (pitch != 1.0) {
        await player.setPlaybackRate(pitch);
      }
    }
  }

  void toggleSound() async {
    soundEnabledNotifier.value = !soundEnabledNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', soundEnabledNotifier.value);
    
    if (soundEnabledNotifier.value) {
      if (!FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.resume();
      } else {
        FlameAudio.bgm.play('cyber_storm.mp3', volume: 0.6); // restart if stopped
      }
    } else {
      FlameAudio.bgm.pause();
    }
  }
}
