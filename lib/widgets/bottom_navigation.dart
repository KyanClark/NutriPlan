import 'package:flutter/material.dart';
import '../utils/responsive_design.dart';

class BottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final int mealPlanCount;
  final bool isSmallScreen;
  final VoidCallback? onAddMealPressed;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.mealPlanCount,
    required this.isSmallScreen,
    this.onAddMealPressed,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}


class _BottomNavigationState extends State<BottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
    
    _shadowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only rebuild if essential properties changed
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.mealPlanCount != widget.mealPlanCount ||
        oldWidget.isSmallScreen != widget.isSmallScreen) {
      // Essential properties changed, allow rebuild
    } else {
      // Non-essential properties changed, prevent unnecessary rebuild
      // This prevents rebuilds when banner page changes, user name updates, etc.
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() {
      _isHovered = true;
    });
    _hoverController.forward();
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
    });
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure consistent icon sizing and allow a slightly taller bar for better alignment
    final double computedIconSize = widget.isSmallScreen ? 27 : 24;
    // Keep Meal Plan at computed size, slightly reduce others; make Meal Tracker a touch smaller
    final double defaultIconSize = (computedIconSize - 2).clamp(18, 28).toDouble();
    final double mealTrackerIconSize = (computedIconSize - 4).clamp(18, 26).toDouble();
    final double barHeight = widget.isSmallScreen ? 68 : 60;
    const double plusButtonSize = 56;
    final double plusTop = (barHeight - plusButtonSize) / 2; // center inside bar, below top border
    return RepaintBoundary(
      child: Container(
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
          // Bottom Navigation Bar with elevated plus button
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Main navigation bar
              SizedBox(
                height: barHeight,
                child: BottomNavigationBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  currentIndex: widget.selectedIndex,
                  onTap: widget.onTap,
                  unselectedItemColor: const Color.fromARGB(255, 136, 136, 136),
                  selectedItemColor: Colors.green,
                  iconSize: computedIconSize,
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
                    _buildBottomNavItem(Icons.home, 'Home', 0, iconSize: defaultIconSize),
                    _buildBottomNavItem(
                      Icons.restaurant_menu,
                      'Meal Plan',
                      1,
                      badgeCount: widget.mealPlanCount,
                      customImagePath: 'assets/navigation_icons/meal plan icon.png',
                      iconSize: computedIconSize,
                    ),
                    // Empty item for the plus button space
                    const BottomNavigationBarItem(
                      icon: SizedBox.shrink(),
                      label: '',
                    ),
                    _buildBottomNavItem(
                      Icons.track_changes,
                      'Meal Tracker',
                      3,
                      customImagePath: 'assets/navigation_icons/chart-pie-alt.png',
                      iconSize: mealTrackerIconSize,
                    ),
                    _buildBottomNavItem(
                      Icons.analytics,
                      'Analytics',
                      4,
                      iconSize: defaultIconSize,
                    ),
                  ],
                ),
              ),
              // Elevated plus button with hover effect
              Positioned(
                top: plusTop,
                left: 0,
                right: 0,
                child: Center(
                  child: MouseRegion(
                    onEnter: (_) => _onHoverEnter(),
                    onExit: (_) => _onHoverExit(),
                    child: AnimatedBuilder(
                      animation: _hoverController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque, // make full circular container tappable
                            onTap: widget.onAddMealPressed,
                            child: Container(
                              width: plusButtonSize,
                              height: plusButtonSize,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isHovered
                                      ? [
                                          const Color.fromRGBO(91, 219, 97, 1.0),
                                          const Color.fromRGBO(86, 185, 90, 1.0),
                                        ]
                                      : [
                                          const Color.fromRGBO(81, 209, 87, 1.0),
                                          const Color.fromRGBO(76, 175, 80, 1.0),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(_shadowAnimation.value),
                                    blurRadius: _isHovered ? 16 : 12,
                                    offset: Offset(0, _isHovered ? 6 : 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.1),
                                    blurRadius: _isHovered ? 12 : 8,
                                    offset: Offset(0, _isHovered ? 3 : 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                                size: _isHovered ? 30 : 28,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
      IconData icon, String label, int index,
      {int badgeCount = 0, String? customImagePath, double iconSize = 24}) {
    final Widget baseIconWidget = customImagePath != null
        ? ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: index == widget.selectedIndex
                    ? [
                        const Color.fromRGBO(142, 190, 155, 1.0),
                        const Color.fromRGBO(125, 189, 228, 1.0),
                      ]
                    : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Image.asset(
              customImagePath,
              width: iconSize,
              height: iconSize,
              color: Colors.white,
            ),
          )
        : ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: index == widget.selectedIndex
                    ? [
                        const Color.fromRGBO(142, 190, 155, 1.0),
                        const Color.fromRGBO(125, 189, 228, 1.0),
                      ]
                    : [Colors.grey, Colors.grey],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Icon(icon, color: Colors.white, size: iconSize),
          );

    return BottomNavigationBarItem(
      icon: SizedBox(
        width: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: baseIconWidget),
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: 1,
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
      ),
      label: label,
    );
  }
}
