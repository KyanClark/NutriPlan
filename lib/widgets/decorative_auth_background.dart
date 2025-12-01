import 'dart:ui';
import 'package:flutter/material.dart';

class DecorativeAuthBackground extends StatelessWidget {
  final Widget child;
  const DecorativeAuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Green curved background with blurry edge
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Base solid gradient
              ClipPath(
                clipper: _TopCurveClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.38,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF1B5E20), // deeper green at top
                        Color(0xFF4CAF50),
                        Color(0xFF81C784), // lighter green accent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              // Blur overlay only at the bottom curve edge - positioned to follow curve
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ClipPath(
                    clipper: _BottomCurveBlurClipper(),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF81C784),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Subtle recipe / ingredient themed icons for visual interest
        Positioned(
          top: 40,
          left: 24,
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.white.withOpacity(0.12),
            size: 40,
          ),
        ),
        Positioned(
          top: 90,
          right: 32,
          child: Icon(
            Icons.local_dining,
            color: Colors.white.withOpacity(0.10),
            size: 34,
          ),
        ),
        Positioned(
          top: 150,
          left: 80,
          child: Icon(
            Icons.eco,
            color: Colors.white.withOpacity(0.10),
            size: 32,
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

class _BottomCurveBlurClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Create a path that follows the curve shape at the bottom
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(
      size.width / 2, size.height - 20,
      size.width, size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 