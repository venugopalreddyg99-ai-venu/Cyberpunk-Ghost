import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'galaxy_defender_game.dart';
import 'enemy.dart';

class Bullet extends PositionComponent with HasGameReference<GalaxyDefenderGame>, CollisionCallbacks {
  static const double _speed = 400.0; // Reduced speed to prevent tunneling through enemies
  Vector2 velocity;

  final Paint _paint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.fill;

  // Added velocity parameter to support spread-shot from galaxy_defender_game.dart
  Bullet({required super.position, Vector2? velocity}) 
      : velocity = velocity ?? Vector2(0, -_speed), 
        super(size: Vector2(5, 40), anchor: Anchor.center); // Made bullet twice as long (from 20 to 40) to prevent skipping past ghosts at low frame rates

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // THIS is what makes the bullet "solid"
    add(RectangleHitbox()); 
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Only draw the visual part of the bullet as size 5x20 even though hitbox is 5x40
    canvas.drawRect(Rect.fromLTWH(0, 0, 5, 20), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    position += velocity * dt;

    // Remove if it goes off screen
    if (position.y < -height) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    // If we hit an Enemy
    if (other is Enemy) {
      other.takeDamage(); // Kill the enemy
      removeFromParent(); // Destroy the bullet
    }
  }
}
