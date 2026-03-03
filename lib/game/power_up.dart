import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'galaxy_defender_game.dart';
import 'player.dart';

enum PowerUpType { health, shield, spreadShot }

class PowerUp extends PositionComponent with HasGameReference<GalaxyDefenderGame>, CollisionCallbacks {
  final PowerUpType type;
  static const double _speed = 100.0;
  
  late Paint _paint;
  late Path _shape;

  PowerUp({required this.type, required super.position}) : super(size: Vector2(30, 30), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
    
    if (type == PowerUpType.health) {
      _paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
        
      // Plus shape
      _shape = Path()
        ..moveTo(size.x / 2 - 5, 0)
        ..lineTo(size.x / 2 + 5, 0)
        ..lineTo(size.x / 2 + 5, size.y / 2 - 5)
        ..lineTo(size.x, size.y / 2 - 5)
        ..lineTo(size.x, size.y / 2 + 5)
        ..lineTo(size.x / 2 + 5, size.y / 2 + 5)
        ..lineTo(size.x / 2 + 5, size.y)
        ..lineTo(size.x / 2 - 5, size.y)
        ..lineTo(size.x / 2 - 5, size.y / 2 + 5)
        ..lineTo(0, size.y / 2 + 5)
        ..lineTo(0, size.y / 2 - 5)
        ..lineTo(size.x / 2 - 5, size.y / 2 - 5)
        ..close();
    } else if (type == PowerUpType.shield) {
      _paint = Paint()
        ..color = Colors.cyan
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
        
      // Hexagon shape
      _shape = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(size.x, size.y / 4)
        ..lineTo(size.x, size.y * 3 / 4)
        ..lineTo(size.x / 2, size.y)
        ..lineTo(0, size.y * 3 / 4)
        ..lineTo(0, size.y / 4)
        ..close();
    } else if (type == PowerUpType.spreadShot) {
      _paint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8.0);
        
      // Triangle shape
      _shape = Path()
        ..moveTo(size.x / 2, 0)
        ..lineTo(size.x, size.y)
        ..lineTo(0, size.y)
        ..close();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawPath(_shape, _paint);
    canvas.drawPath(_shape, Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += _speed * dt;
    // Slow rotation
    angle += 1.0 * dt;
    
    // Remove if it goes off the bottom screen
    if (position.y > game.size.y + size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      // Logic handled in game or player
      removeFromParent();
      if (type == PowerUpType.health) {
        game.restoreHealth();
      } else if (type == PowerUpType.shield) {
        other.activateShield();
      } else if (type == PowerUpType.spreadShot) {
        game.activateSpreadShot();
      }
    }
  }
}
