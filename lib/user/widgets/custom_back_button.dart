import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final EdgeInsetsGeometry? padding;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      icon: CustomBackIcon(
        color: color ?? Colors.black,
        size: size,
      ),
      padding: padding ?? const EdgeInsets.all(8.0),
      constraints: BoxConstraints(
        minWidth: size + 16,
        minHeight: size + 16,
      ),
    );
  }
}

class CustomBackIcon extends StatelessWidget {
  final Color color;
  final double size;

  const CustomBackIcon({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CustomBackIconPainter(color: color),
    );
  }
}

class CustomBackIconPainter extends CustomPainter {
  final Color color;

  CustomBackIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.15 // Medium thickness
      ..strokeCap = StrokeCap.round // Rounded ends
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Draw the left-pointing chevron
    // Start from the right side, go left and down, then left and up
    path.moveTo(size.width * 0.8, size.height * 0.2);
    path.lineTo(size.width * 0.4, size.height * 0.5);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
