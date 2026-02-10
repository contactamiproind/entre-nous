import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

class FloatingDecoration extends StatelessWidget {
  final String shape; // 'circle', 'star', 'diamond', 'squiggle'
  final Color color;
  final double size;
  final double top;
  final double left;
  final double? right;
  final double? bottom;
  final Duration duration;
  final double delay;
  final double opacity;

  const FloatingDecoration({
    super.key,
    required this.shape,
    required this.color,
    required this.size,
    this.top = 0,
    this.left = 0,
    this.right,
    this.bottom,
    this.duration = const Duration(seconds: 3),
    this.delay = 0,
    this.opacity = 0.3, // Default low opacity for subtlety
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: _buildShape()
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            delay: (delay * 1000).round().ms,
          )
          .moveY(
            begin: 0, 
            end: 20, 
            duration: duration, 
            curve: Curves.easeInOut
          )
          .rotate(
            begin: -0.015, // approx -0.1 radians
            end: 0.015,    // approx 0.1 radians
            duration: duration, 
            curve: Curves.easeInOut
          ),
    );
  }

  Widget _buildShape() {
    final shapeColor = color.withValues(alpha: opacity);

    Widget shapeWidget;
    switch (shape) {
      case 'circle':
        shapeWidget = Container(
          decoration: BoxDecoration(color: shapeColor, shape: BoxShape.circle),
        );
        break;
      case 'star':
        shapeWidget = CustomPaint(
          painter: StarPainter(color: shapeColor),
        );
        break;
      case 'diamond':
        shapeWidget = Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            decoration: BoxDecoration(
              color: shapeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
        break;
      case 'squiggle':
        shapeWidget = CustomPaint(
          painter: SquigglePainter(color: shapeColor),
        );
        break;
      default:
        shapeWidget = const SizedBox.shrink();
    }
    
    // STRICTLY enforce size
    return SizedBox(
      width: shape == 'squiggle' ? size * 2 : size,
      height: size,
      child: shapeWidget,
    );
  }
}

class StarPainter extends CustomPainter {
  final Color color;

  StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * math.pi / 5) - math.pi / 2;
      final innerAngle = outerAngle + math.pi / 5;

      final outerX = centerX + outerRadius * math.cos(outerAngle);
      final outerY = centerY + outerRadius * math.sin(outerAngle);
      final innerX = centerX + innerRadius * math.cos(innerAngle);
      final innerY = centerY + innerRadius * math.sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SquigglePainter extends CustomPainter {
  final Color color;

  SquigglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(size.width / 4, 0, size.width / 2, size.height / 2);
    path.quadraticBezierTo(
      size.width * 3 / 4,
      size.height,
      size.width,
      size.height / 2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
