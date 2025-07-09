import 'package:flutter/material.dart';

class DecorativeAuthBackground extends StatelessWidget {
  final Widget child;
  const DecorativeAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pink/red curved background
        ClipPath(
          clipper: _TopCurveClipper(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative icons (placeholders)
                Positioned(
                  top: 40, left: 30,
                  child: Icon(Icons.fastfood, color: Colors.white.withOpacity(0.15), size: 48),
                ),
                Positioned(
                  top: 80, right: 40,
                  child: Icon(Icons.local_dining, color: Colors.white.withOpacity(0.13), size: 40),
                ),
                Positioned(
                  top: 20, right: 100,
                  child: Icon(Icons.restaurant, color: Colors.white.withOpacity(0.10), size: 36),
                ),
                Positioned(
                  top: 100, left: 100,
                  child: Icon(Icons.emoji_food_beverage, color: Colors.white.withOpacity(0.12), size: 32),
                ),
              ],
            ),
          ),
        ),
        // Main content (form, etc.)
        Align(
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }
}

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 