import 'package:flutter/material.dart';

// Responsive design utilities
class ResponsiveDesign {
  static const double iPhone11Width = 414.0;
  static const double iPhone11Height = 896.0;
  
  static bool isiPhone11(BuildContext context) {
    try {
      final size = MediaQuery.of(context).size;
      return size.width == iPhone11Width && size.height == iPhone11Height;
    } catch (_) {
      return false;
    }
  }
  
  static bool isSmallScreen(BuildContext context) {
    try {
      return MediaQuery.of(context).size.width < 400;
    } catch (_) {
      return true; // Default to small screen if MediaQuery is unavailable
    }
  }
  
  static bool isMediumScreen(BuildContext context) {
    try {
      final width = MediaQuery.of(context).size.width;
      return width >= 400 && width < 600;
    } catch (_) {
      return false;
    }
  }
  
  static bool isLargeScreen(BuildContext context) {
    try {
      return MediaQuery.of(context).size.width >= 600;
    } catch (_) {
      return false;
    }
  }
  
  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isSmallScreen(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isMediumScreen(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
  
  // Responsive spacing
  static double responsiveSpacing(BuildContext context) {
    if (isSmallScreen(context)) {
      return 12.0;
    } else if (isMediumScreen(context)) {
      return 16.0;
    } else {
      return 20.0;
    }
  }
  
  // Responsive font size
  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (isSmallScreen(context)) {
      return baseSize * 0.9;
    } else if (isMediumScreen(context)) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }
} 