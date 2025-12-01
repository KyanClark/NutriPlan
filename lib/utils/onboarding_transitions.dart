import 'package:flutter/material.dart';

/// Custom page route with smooth transitions for onboarding pages
class OnboardingPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final bool slideFromRight;

  OnboardingPageRoute({
    required this.page,
    this.slideFromRight = true,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Fade transition
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
            );

            // Slide transition
            final slideOffset = slideFromRight
                ? const Offset(1.0, 0.0) // Slide from right
                : const Offset(-1.0, 0.0); // Slide from left
            final slideAnimation = Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            // Combine fade and slide
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

