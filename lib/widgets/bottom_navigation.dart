import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/responsive_design.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final int mealPlanCount;
  final double opacity;
  final bool isSmallScreen;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.mealPlanCount,
    required this.opacity,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * opacity,
            sigmaY: 8 * opacity,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity * 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1 * opacity),
                  blurRadius: 8 * opacity,
                  offset: Offset(0, -2 * opacity),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top border line (matching AppBar style)
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                // Bottom Navigation Bar
                BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: selectedIndex,
                  onTap: onTap,
                  unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
                  selectedItemColor: Colors.green,
                  iconSize: isSmallScreen ? 22 : 24,
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedLabelStyle: TextStyle(
                    fontSize: ResponsiveDesign.responsiveFontSize(context, 12),
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: ResponsiveDesign.responsiveFontSize(context, 12),
                  ),
                  items: [
                    _buildBottomNavItem(Icons.home, 'Home', 0),
                    _buildBottomNavItem(Icons.restaurant_menu, 'Meal Plan', 1, badgeCount: mealPlanCount),
                    _buildBottomNavItem(Icons.analytics, 'Analytics', 2),
                    _buildBottomNavItem(Icons.track_changes, 'Meal Tracker', 3),
                    _buildBottomNavItem(Icons.person, 'Profile', 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
      IconData icon, String label, int index, {int badgeCount = 0}) {
    return BottomNavigationBarItem(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: index == selectedIndex
                    ? [
                        Color.fromRGBO(142, 190, 155, 1.0),
                        Color.fromRGBO(125, 189, 228, 1.0),
                      ]
                    : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Icon(icon, color: Colors.white),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -6,
              right: -12,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(100),
                ),
                constraints: const BoxConstraints(
                  minWidth: 21,
                  minHeight: 15,
                ),
                child: Center(
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      label: label,
    );
  }
}
