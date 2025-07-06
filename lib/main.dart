import 'package:flutter/material.dart';
import 'package:nutriplan/screens/home_page.dart';
import 'package:nutriplan/screens/breakfast_page.dart';
import 'package:nutriplan/screens/lunch_page.dart';
import 'package:nutriplan/screens/dinner_page.dart';

void main() {
  runApp(const NutriPlan());
}

class NutriPlan extends StatelessWidget {
  const NutriPlan({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriPlan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50), // Green theme for health/nutrition
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        // Responsive text themes for iPhone 11
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
          bodySmall: TextStyle(fontSize: 12),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/breakfast_page': (context) => const BreakfastPage(),
        '/lunch_page': (context) => const LunchPage(),
        '/dinner_page': (context) => const DinnerPage(),
      },
    );
  }
}

// Responsive design utilities
class ResponsiveDesign {
  static const double iPhone11Width = 414.0;
  static const double iPhone11Height = 896.0;
  
  static bool isiPhone11(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width == iPhone11Width && size.height == iPhone11Height;
  }
  
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 400;
  }
  
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 400 && width < 600;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
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