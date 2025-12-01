import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../recipes/recipes_page.dart';
import 'auto_generate_meal_plan_page.dart';

class MealPlanningOptionsPage extends StatelessWidget {
  const MealPlanningOptionsPage({super.key});
  
  static const String _dontShowDialogKey = 'dont_show_generate_meal_plan_dialog';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50), // Same green as meal planner
      appBar: AppBar(
        title: const Text(
          'Meal Planning',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header
                      Text(
                        'Choose Your Meal Planning Option',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 16),
                      Text(
                        'Select how you want to plan your meals',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      
                      // Add Meal for Today Option
                      _buildOptionCard(
                        context: context,
                        title: 'Add Meal for Today',
                        subtitle: 'Plan a meal for today',
                        icon: Icons.today,
                        color: Colors.white,
                        textColor: const Color(0xFF4CAF50),
                        isSmallScreen: false, // Revert to original size
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RecipesPage(),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Plan Meal in Advance Option
                      _buildOptionCard(
                        context: context,
                        title: 'Plan Meal in Advance',
                        subtitle: 'Schedule meals for future dates',
                        icon: Icons.calendar_today,
                        color: Colors.white,
                        textColor: const Color(0xFF4CAF50),
                        isSmallScreen: false, // Revert to original size
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const RecipesPage(
                                isAdvancePlanning: true,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Generate Meal Plan Option (Blue button)
                      _buildOptionCard(
                        context: context,
                        title: 'Generate Meal Plan',
                        subtitle: 'Auto-generate meals based on your preferences',
                        icon: Icons.auto_awesome,
                        color: Colors.white,
                        textColor: Colors.blue, // Blue button
                        isSmallScreen: isSmallScreen,
                        onTap: () {
                          _showGenerateMealPlanDialog(context);
                        },
                      ),
                      
                      // Add bottom padding for small screens
                      SizedBox(height: isSmallScreen ? 16 : 0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showGenerateMealPlanDialog(BuildContext context) async {
    // Check if user has selected "don't show again"
    final prefs = await SharedPreferences.getInstance();
    final dontShowAgain = prefs.getBool(_dontShowDialogKey) ?? false;
    
    if (dontShowAgain) {
      // Skip dialog and go directly to generate page
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AutoGenerateMealPlanPage(),
          ),
        );
      }
      return;
    }
    
    bool dontShow = false;
    
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Generate Meal Plan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Let NutriPlan create a personalized meal plan for you! 🎯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Our smart algorithm learns from your preferences, health conditions, and eating patterns to suggest the perfect meals for breakfast, lunch, and dinner.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Each meal will be different and tailored just for you!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    "Don't show this again",
                    style: TextStyle(fontSize: 14),
                  ),
                  value: dontShow,
                  onChanged: (value) {
                    setState(() {
                      dontShow = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save "don't show again" preference
                if (dontShow) {
                  await prefs.setBool(_dontShowDialogKey, true);
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Generate Meal Plan'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result == true && context.mounted) {
        // Navigate to generate page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AutoGenerateMealPlanPage(),
          ),
        );
      }
    });
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color textColor,
    required bool isSmallScreen,
    required VoidCallback onTap,
  }) {
    // Use original sizes for first two cards, responsive for Generate Meal Plan
    final useOriginalSize = title != 'Generate Meal Plan';
    final padding = useOriginalSize ? 24.0 : (isSmallScreen ? 16.0 : 20.0);
    final iconSize = useOriginalSize ? 48.0 : (isSmallScreen ? 36.0 : 44.0);
    final titleSize = useOriginalSize ? 20.0 : (isSmallScreen ? 16.0 : 18.0);
    final subtitleSize = useOriginalSize ? 14.0 : (isSmallScreen ? 12.0 : 13.0);
    final iconSpacing = useOriginalSize ? 16.0 : (isSmallScreen ? 8.0 : 12.0);
    final titleSpacing = useOriginalSize ? 8.0 : (isSmallScreen ? 4.0 : 6.0);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: textColor,
            ),
            SizedBox(height: iconSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: titleSpacing),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleSize,
                color: textColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
