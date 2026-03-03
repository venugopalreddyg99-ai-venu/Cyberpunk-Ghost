import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'galaxy_defender_game.dart';
import 'bullet.dart';

class Enemy extends PositionComponent with HasGameReference<GalaxyDefenderGame>, CollisionCallbacks {
  final double speed;
  
  final Paint _ghostPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8)
    ..style = PaintingStyle.fill;
    
  final Paint _eyePaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;
    
  late Path _ghostShape;
  double _time = 0;
  final Random _rnd = Random();

  Enemy({required super.position, this.speed = 150.0}) : super(size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
    
    // Create a Ghost shape
    _ghostShape = Path()
      ..moveTo(0, size.y / 2) // Start left middle
      ..arcToPoint(
        Offset(size.x, size.y / 2),
        radius: Radius.circular(size.x / 2),
        clockwise: true,
      ) // Semi-circle head
      ..lineTo(size.x, size.y)
      // Wavy skirt (3 curves)
      ..quadraticBezierTo(size.x * 5 / 6, size.y - 10, size.x * 2 / 3, size.y)
      ..quadraticBezierTo(size.x / 2, size.y - 10, size.x / 3, size.y)
      ..quadraticBezierTo(size.x / 6, size.y - 10, 0, size.y)
      ..close();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Draw ghost body
    canvas.drawPath(_ghostShape, _ghostPaint);
    
    // Draw eyes
    canvas.drawCircle(Offset(size.x * 0.35, size.y * 0.4), 4, _eyePaint);
    canvas.drawCircle(Offset(size.x * 0.65, size.y * 0.4), 4, _eyePaint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Movement: downward speed + floating sine wave
    double offsetX = sin(_time * 3) * 2;
    position.y += speed * dt;
    position.x += offsetX;
    
    // Remove if it goes off the bottom screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bullet) {
      // Show smoke explosion
      _showSmoke(position.clone());
      
      // Destroy both the enemy and the bullet
      removeFromParent();
      other.removeFromParent();
      
      // Increment score
      game.increaseScore(10);
    }
  }

  void _showSmoke(Vector2 spawnPosition) {
    final particleSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: 20,
        lifespan: 1.0,
        generator: (i) => AcceleratedParticle(
          speed: Vector2((_rnd.nextDouble() - 0.5) * 100, (_rnd.nextDouble() - 0.5) * 100),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final radius = 5.0 * (1 - particle.progress);
              final paint = Paint()
                ..color = Colors.white.withValues(alpha: 1 - particle.progress)
                ..style = PaintingStyle.fill;
              canvas.drawCircle(Offset.zero, radius, paint);
            },
          ),
        ),
      ),
      position: spawnPosition,
    );
    game.add(particleSystem);
  }
}
