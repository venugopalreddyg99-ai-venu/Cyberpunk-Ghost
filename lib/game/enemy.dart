import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'galaxy_defender_game.dart';

class Enemy extends PositionComponent with HasGameRef<GalaxyDefenderGame>, CollisionCallbacks {
  // Speed settings
  double speed = 200;

  // Ghost visuals
  final Paint _ghostPaint = Paint()..color = Colors.white.withOpacity(0.8);
  final Paint _eyePaint = Paint()..color = Colors.black;

  Enemy({required Vector2 position, this.speed = 200}) 
      : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()); // Helper hitbox
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // 1. Fall Down (Linear Movement)
    y += speed * dt;

    // Remove if it goes off screen
    if (y > gameRef.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw the Ghost Shape
    final path = Path();
    
    // 1. Round Head
    path.moveTo(0, size.y);
    path.arcToPoint(Offset(size.x, size.y), radius: const Radius.circular(20), clockwise: false); // Top arc (simplified)
    // Actually, let's draw a proper ghost shape relative to 0,0
    path.reset();
    final w = size.x;
    final h = size.y;
    
    // Head (Top half circle)
    path.moveTo(0, h * 0.5);
    path.arcToPoint(Offset(w, h * 0.5), radius: Radius.circular(w/2));
    
    // Right side down
    path.lineTo(w, h);
    
    // Wavy Bottom (3 bumps)
    path.quadraticBezierTo(w * 0.83, h * 0.8, w * 0.66, h);
    path.quadraticBezierTo(w * 0.5, h * 0.8, w * 0.33, h);
    path.quadraticBezierTo(w * 0.16, h * 0.8, 0, h);
    
    path.close();
    canvas.drawPath(path, _ghostPaint);

    // Eyes
    canvas.drawCircle(Offset(w * 0.3, h * 0.4), 3, _eyePaint);
    canvas.drawCircle(Offset(w * 0.7, h * 0.4), 3, _eyePaint);
  }

  void takeDamage() {
    // Trigger the smoke explosion and sound in the main game
    gameRef.spawnSmoke(position);
    gameRef.playSound('bass_impact.wav', volume: 1.0); 
    removeFromParent();
    gameRef.increaseScore(10); // Fixed from gameRef.score += 10; since score is private in GalaxyDefenderGame
  }
}
