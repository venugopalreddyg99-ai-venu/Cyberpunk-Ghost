import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class Bullet extends PositionComponent {
  static const double _speed = 400.0;
  Vector2 velocity;
  
  final Paint _paint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.fill;

  Bullet({required super.position, Vector2? velocity}) : velocity = velocity ?? Vector2(0, -_speed), super(size: Vector2(4, 15), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    
    // Remove if it goes off the top screen
    if (position.y < -size.y) {
      removeFromParent();
    }
  }
}
