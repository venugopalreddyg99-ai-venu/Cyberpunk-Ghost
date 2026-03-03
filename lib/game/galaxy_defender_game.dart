import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
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
  
  late TextComponent _scoreText;
  late TextComponent _healthText;
  int _score = 0;
  int _health = 3;
  int highScore = 0;
  
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

    // Load High Score
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('high_score') ?? 0;

    // Cache the audio files
    await FlameAudio.audioCache.loadAll(['laser.mp3', 'explosion.mp3']);

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

    // Show start overlay initially
    overlays.add('StartOverlay');

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

    // Futuristic HUD
    final hudBackground = RectangleComponent(
      position: Vector2(10, 10),
      size: Vector2(180, 80),
      paint: Paint()
        ..color = Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill,
    );
    hudBackground.add(
      RectangleComponent(
        size: Vector2(180, 80),
        paint: Paint()
          ..color = Colors.cyan.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      )
    );

    _scoreText = TextComponent(
      text: 'SCORE: 0',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier', // Futuristic monospaced
          shadows: [Shadow(color: Colors.cyan, blurRadius: 4)],
        ),
      ),
    );
    
    _healthText = TextComponent(
      text: 'HULL: INT',
      position: Vector2(10, 45),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Courier',
          shadows: [Shadow(color: Colors.green, blurRadius: 4)],
        ),
      ),
    );

    hudBackground.add(_scoreText);
    hudBackground.add(_healthText);
    camera.viewport.add(hudBackground);

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
    
    // Reset properties
    _score = 0;
    _health = 3;
    _scoreText.text = 'SCORE: 0';
    _updateHealthUI();
    
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
    if (_score >= 1000) {
      newLevel = 3;
    } else if (_score >= 500) {
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
    FlameAudio.play('laser.mp3');
  }

  void increaseScore(int amount) {
    _score += amount;
    _scoreText.text = 'SCORE: $_score';
  }

  void _updateHealthUI() {
    final TextStyle baseStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Courier',
    );

    if (_health == 3) {
      _healthText.text = 'HULL: INT';
      _healthText.textRenderer = TextPaint(
        style: baseStyle.copyWith(color: Colors.greenAccent, shadows: [const Shadow(color: Colors.green, blurRadius: 4)]),
      );
    } else if (_health == 2) {
      _healthText.text = 'HULL: DMG';
      _healthText.textRenderer = TextPaint(
        style: baseStyle.copyWith(color: Colors.orangeAccent, shadows: [const Shadow(color: Colors.orange, blurRadius: 4)]),
      );
    } else if (_health == 1) {
      _healthText.text = 'HULL: CRT';
      _healthText.textRenderer = TextPaint(
        style: baseStyle.copyWith(color: Colors.redAccent, shadows: [const Shadow(color: Colors.red, blurRadius: 4)]),
      );
    }
  }

  void restoreHealth() {
    if (state != GameState.playing) return;
    if (_health < 3) {
      _health += 1;
      _updateHealthUI();
    } else {
      // Bonus points if already at max health
      increaseScore(50);
    }
  }

  void playerHit() {
    if (state != GameState.playing) return;
    
    FlameAudio.play('explosion.mp3');
    _health -= 1;
    _updateHealthUI();

    if (_health <= 0) {
      gameOver();
    }
  }

  void gameOver() {
    if (state == GameState.gameOver) return;
    
    state = GameState.gameOver;
    FlameAudio.play('explosion.mp3');
    player.removeFromParent();
    
    // Save High Score
    if (_score > highScore) {
      highScore = _score;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setInt('high_score', highScore);
      });
    }

    overlays.add('GameOverOverlay');
  }
}
