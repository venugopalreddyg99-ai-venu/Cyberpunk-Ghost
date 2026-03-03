import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'galaxy_defender_game.dart';
import 'enemy.dart';

class PlayerShip extends PositionComponent with HasGameReference<GalaxyDefenderGame>, CollisionCallbacks {
  final Paint _cyanPaint = Paint()
    ..color = Colors.cyan
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10.0);

  final Paint _saucerPaint = Paint()
    ..color = const Color(0xFFC0C0C0) // Silver
    ..style = PaintingStyle.fill;
    
  final Paint _cockpitPaint = Paint()
    ..color = Colors.cyanAccent.withValues(alpha: 0.8)
    ..style = PaintingStyle.fill;
    
  final Paint _lightPaint = Paint()
    ..style = PaintingStyle.fill;
    
  final Paint _shieldPaint = Paint()
    ..color = Colors.cyanAccent.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Random _rnd = Random();
  double _particleTimer = 0.0;
  double _animationTime = 0.0;
  
  bool hasShield = false;

  PlayerShip({super.position}) : super(size: Vector2(50, 40), anchor: Anchor.center);

  void activateShield() {
    hasShield = true;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw glowing neon aura behind the saucer
    final saucerRect = Rect.fromCenter(center: Offset(size.x / 2, size.y / 2 + 5), width: size.x, height: 20);
    canvas.drawOval(saucerRect, _cyanPaint);

    // 2. Draw solid silver saucer
    canvas.drawOval(saucerRect, _saucerPaint);

    // 3. Draw cyan cockpit arc on top
    final cockpitRect = Rect.fromCenter(center: Offset(size.x / 2, size.y / 2 - 2), width: size.x * 0.5, height: 25);
    canvas.drawArc(cockpitRect, pi, pi, true, _cockpitPaint); // Use dart:math pi
    
    // 4. Draw pulsating lights along the rim of the saucer
    // We space out 5 lights horizontally. 
    // The alpha pulsates smoothly based on sine of _animationTime.
    final pulseAlpha = ((sin(_animationTime * 5) + 1) / 2 * 255).toInt();
    _lightPaint.color = Colors.cyanAccent.withAlpha(pulseAlpha);
    
    final numLights = 5;
    for (int i = 0; i < numLights; i++) {
       double lx = size.x * 0.15 + (size.x * 0.7 / (numLights - 1)) * i;
       double ly = size.y / 2 + 5; // Align roughly to saucer center
       canvas.drawCircle(Offset(lx, ly), 3, _lightPaint);
    }
    
    // 5. Draw Shield if active
    if (hasShield) {
       // Pulsating radius
       double shieldRadius = size.x * 0.6 + sin(_animationTime * 10) * 3;
       canvas.drawCircle(Offset(size.x / 2, size.y / 2), shieldRadius, _shieldPaint);
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
    
    // Clamp the position to ensure the ship doesn't leave the screen area
    position.clamp(
      Vector2(size.x / 2, size.y / 2),
      game.size - Vector2(size.x / 2, size.y / 2),
    );

    // Emit Engine Trail Particles
    _particleTimer += dt;
    if (_particleTimer > 0.05) {
      _particleTimer = 0.0;
      
      final particleSystem = ParticleSystemComponent(
        particle: Particle.generate(
          count: 5,
          lifespan: 0.5,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 150),
            speed: Vector2((_rnd.nextDouble() - 0.5) * 50, 50 + _rnd.nextDouble() * 50),
            position: Vector2(position.x, position.y + size.y / 2),
            child: CircleParticle(
              radius: 1.5 + _rnd.nextDouble() * 2,
              paint: Paint()..color = Colors.cyanAccent.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
      game.add(particleSystem);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Enemy) {
      if (hasShield) {
        hasShield = false;
        other.removeFromParent();
        game.playSound('explosion.mp3'); // Feedback for shield break
      } else {
        game.playerHit();
      }
    }
  }
}
