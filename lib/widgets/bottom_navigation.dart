import 'package:flutter/material.dart';
import '../utils/responsive_design.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final int mealPlanCount;
  final bool isSmallScreen;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.mealPlanCount,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top border line
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.25),
          ),
          // Bottom Navigation Bar
          BottomNavigationBar(
            backgroundColor: Colors.white,
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
              _buildBottomNavItem(Icons.track_changes, 'Meal Tracker', 2),
              _buildBottomNavItem(Icons.person, 'Profile', 3),
            ],
          ),
        ],
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
                  color: const Color(0xFFFF6961),
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
