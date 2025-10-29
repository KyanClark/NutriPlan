import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../recipes/recipe_info_screen.dart';
import '../profile/profile_screen.dart';
import '../../models/recipes.dart';
import 'interface/meal_planner_widgets.dart';

class MealPlannerScreen extends StatefulWidget {
  final bool forceRefresh;
  final VoidCallback? onChanged;
  const MealPlannerScreen({super.key, this.forceRefresh = false, this.onChanged});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  DateTime selectedDate = DateTime.now();
  Timer? _timer;
  late final PageController _weekPageController;

  // Add state for Supabase meal plans
  List<Map<String, dynamic>> supabaseMealPlans = [];
  List<Map<String, dynamic>> allMealPlans = []; // For badge counting across all dates
  final String _selectedFilter = 'All';
  bool _isDeleteMode = false;
  final Set<String> _selectedMealsForDeletion = {};
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _weekPageController = PageController(initialPage: 1000);
    _fetchAllMealPlans(); // Fetch all meals for badge counting
      _fetchSupabaseMealPlans();
    _fetchUserAvatar();
    
    // Set up timer for periodic refresh
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _fetchAllMealPlans();
      _fetchSupabaseMealPlans();
    }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MealPlannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceRefresh != oldWidget.forceRefresh && widget.forceRefresh) {
      _fetchAllMealPlans();
      _fetchSupabaseMealPlans();
    }
  }

  Future<void> _fetchAllMealPlans() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Fetch ALL meals for badge counting (no date filter)
      final plansResponse = await Supabase.instance.client
          .from('meal_plans')
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      List<Map<String, dynamic>> allMeals = [];
      
      // Process each meal plan record
      for (final meal in plansResponse) {
        allMeals.add({
          'id': meal['id'],
          'title': meal['title'],
          'meal_type': meal['meal_type'],
          'meal_time': meal['meal_time'],
          'date': meal['date'],
          'recipes': meal['recipes'],
          'created_at': meal['created_at'],
        });
      }
      
      if (mounted) {
        setState(() {
          allMealPlans = allMeals;
        });
      }
    } catch (e) {
      // Handle error silently for badge counting
    }
  }

  Future<void> _fetchSupabaseMealPlans() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Format selected date for filtering
      final selectedDateStr = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      
      // Fetch from meal_plans table with recipe details, filtered by selected date
      final plansResponse = await Supabase.instance.client
          .from('meal_plans')
          .select('*, recipes(*)')
          .eq('user_id', userId)
          .eq('date', selectedDateStr)  // Fixed: use 'date' instead of 'meal_date'
          .order('created_at', ascending: false);
      
      List<Map<String, dynamic>> allMeals = [];
      
      // Process each meal plan record
      for (final meal in plansResponse) {
        allMeals.add({
          ...meal,
          'plan_id': meal['id'],
          'is_legacy_format': false,
        });
      }
      
      // Sort meals chronologically by time
      allMeals.sort((a, b) {
        final timeA = a['meal_time'] as String?;
        final timeB = b['meal_time'] as String?;
        
        // If both have times, compare them
        if (timeA != null && timeB != null) {
          return _compareTimeStrings(timeA, timeB);
        }
        
        // If only one has time, prioritize the one with time
        if (timeA != null && timeB == null) return -1;
        if (timeA == null && timeB != null) return 1;
        
        // If neither has time, sort by created_at
        final createdA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final createdB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return createdA.compareTo(createdB);
      });
      
      if (mounted) {
        setState(() {
          supabaseMealPlans = allMeals;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _fetchUserAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      if (!mounted) return;
        setState(() {
        _avatarUrl = data?['avatar_url'] as String?;
      });
    } catch (e) {
      print('Error fetching user avatar: $e');
    }
  }

  /// Compare two time strings chronologically
  int _compareTimeStrings(String timeA, String timeB) {
    try {
      // Parse time strings like "08:30:00" or "8:30 AM"
      final parsedA = _parseTimeString(timeA);
      final parsedB = _parseTimeString(timeB);
      
      if (parsedA == null && parsedB == null) return 0;
      if (parsedA == null) return 1;
      if (parsedB == null) return -1;
      
      return parsedA.compareTo(parsedB);
    } catch (e) {
      return 0; // Return 0 if comparison fails
    }
  }

  /// Parse time string to DateTime for comparison
  DateTime? _parseTimeString(String timeString) {
    try {
      // Clean the time string
      String cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      
      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          
          // Create a DateTime with today's date and the parsed time
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
      
      // Handle single hour format
      final hour = int.tryParse(cleanTime);
      if (hour != null && hour >= 0 && hour <= 23) {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, 0);
      }
      
      return null;
    } catch (e) {
      return null; // Return null if parsing fails
    }
  }

  /// Get filtered meals based on selected filter
  List<Map<String, dynamic>> get _filteredMeals {
    if (_selectedFilter == 'All') {
      return supabaseMealPlans;
    }
    
    return supabaseMealPlans.where((meal) {
      final mealType = meal['meal_type']?.toString().toLowerCase();
      return mealType == _selectedFilter.toLowerCase();
    }).toList();
  }

  /// Delete selected meals
  Future<void> _deleteSelectedMeals() async {
    if (_selectedMealsForDeletion.isEmpty) return;

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete ${_selectedMealsForDeletion.length} ${_selectedMealsForDeletion.length == 1 ? 'meal' : 'meals'}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6961),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    // If user didn't confirm, don't delete
    if (shouldDelete != true) return;

    try {
      // Delete from Supabase
      await Supabase.instance.client
          .from('meal_plans')
          .delete()
          .inFilter('id', _selectedMealsForDeletion.toList());

      // Show success message
      final deletedCount = _selectedMealsForDeletion.length;
      String message;
      if (deletedCount == 1) {
        // Find the name of the single deleted meal
        final deletedMeal = supabaseMealPlans.firstWhere(
          (meal) => meal['id']?.toString() == _selectedMealsForDeletion.first,
          orElse: () => {'title': 'Unknown'},
        );
        message = '${deletedMeal['title']} deleted successfully';
      } else {
        message = '$deletedCount meals deleted successfully';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Refresh data and exit delete mode
      setState(() {
        _isDeleteMode = false;
        _selectedMealsForDeletion.clear();
      });
      
      await _fetchAllMealPlans(); // Refresh badge counts
      await _fetchSupabaseMealPlans(); // Refresh current view
      
      // Notify parent widget of changes
      widget.onChanged?.call();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting meals: $e'),
            backgroundColor: const Color(0xFFFF6961),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _navigateToRecipe(BuildContext context, String mealId) async {
    final navigatorContext = context;
    final response = await Supabase.instance.client
        .from('recipes')
        .select()
        .eq('id', mealId)
        .maybeSingle();
    if (response == null || !mounted) return;
    final recipe = Recipe.fromMap(response);
    if (!mounted) return;
    await Navigator.of(navigatorContext).push(
      MaterialPageRoute(
        builder: (builderContext) => RecipeInfoScreen(
          recipe: recipe,
          showStartCooking: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'NutriPlan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: [
          RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;
                      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(12),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(Icons.person, color: Colors.grey, size: 20)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
            child: Column(
              children: [
            // Hero header with title, subtitle, and weekly calendar inside
                          Container(
              width: double.infinity,
                            decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                ),
                              boxShadow: [
                                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                                'Meal Planner',
                                style: TextStyle(
                                  color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            // Delete button
                            IconButton(
                              tooltip: _isDeleteMode ? 'Cancel delete' : 'Delete meals',
                              icon: Icon(
                                _isDeleteMode ? Icons.close : Icons.delete_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                // Only toggle delete mode; never perform deletion here
                                setState(() {
                                  if (_isDeleteMode) {
                                    _isDeleteMode = false;
                                    _selectedMealsForDeletion.clear();
                                  } else {
                                    _isDeleteMode = true;
                                  }
                                });
                              },
                            ),
                            ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Plan smarter, eat better',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _weekPageController,
                            onPageChanged: (_) {},
                            itemBuilder: (context, page) {
                              final weekStart = _startOfWeek(DateTime.now()).add(Duration(days: (page - 1000) * 7));
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: List.generate(7, (i) {
                                  final date = weekStart.add(Duration(days: i));
                                  return Expanded(
                                      child: Center(child: _buildCalendarDay(date)),
                                  );
                                  }),
                                ),
                              );
                            },
                          ),
                          // Left fade (green -> transparent)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 16,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [Color(0xFF2E7D32), Color(0x002E7D32)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Right fade (green -> transparent)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: 16,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [Color(0xFF4CAF50), Color(0x004CAF50)],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
            // Date Display with animation and tappable indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: InkWell(
                    key: ValueKey('date_${selectedDate.millisecondsSinceEpoch}'),
                    onTap: _showCalendarDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatSelectedDate(),
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                    ),
                  ),
            ),
            // Content area with loading state and animated transitions
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOut,
                    )),
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: supabaseMealPlans.isNotEmpty
                        ? SingleChildScrollView(
                            key: ValueKey('content_${selectedDate.millisecondsSinceEpoch}'),
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                    child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                            // Delete mode controls
                        if (_isDeleteMode) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                      decoration: _selectedMealsForDeletion.isEmpty
                                          ? null
                                          : BoxDecoration(
                                              color: const Color(0xFF4CAF50).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                                color: const Color(0xFF4CAF50).withOpacity(0.25),
                                    width: 1,
                                  ),
                                ),
                                      child: _selectedMealsForDeletion.isEmpty
                                          ? Text(
                                              'No meals selected for deletion',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            )
                                          : Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                                  color: const Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${_selectedMealsForDeletion.length} meal${_selectedMealsForDeletion.length != 1 ? 's' : ''} selected for deletion',
                                        style: const TextStyle(
                                          fontSize: 14,
                                                      color: Color(0xFF4CAF50),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                      ],
                    ),
                  ),
                              const SizedBox(height: 20),
                            ],
                                  // Meal sections (Breakfast, Lunch, Dinner)
                                  _buildMealSections(),
                                  // Extra bottom spacing to prevent FAB overlap/overflow
                                  SizedBox(height: _isDeleteMode ? 120 : 40),
                                ],
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(
                              bottom: _isDeleteMode ? 120.0 : 40.0,
                            ),
                            child: const MealPlannerEmptyState(),
                          ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isDeleteMode
        ? FloatingActionButton.extended(
            onPressed: _selectedMealsForDeletion.isEmpty ? null : _deleteSelectedMeals,
            label: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFFF6961),
          )
        : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _formatSelectedDate() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    final weekday = weekdays[selectedDate.weekday - 1];
    final month = months[selectedDate.month - 1];
    
    return '$weekday, ${selectedDate.day} $month';
  }

  DateTime _startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  // legacy weekly calendar removed (unused)

  // Calendar day widget used by the scrollable list
  Widget _buildCalendarDay(DateTime date) {
    final now = DateTime.now();
    final dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
    final isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;
    
    // Count meals for this specific date using allMealPlans
    final mealsForDate = allMealPlans.where((meal) {
      final mealDate = DateTime.parse(meal['date']);
      return mealDate.day == date.day && mealDate.month == date.month && mealDate.year == date.year;
    }).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          setState(() {
            selectedDate = date;
          });
          _fetchSupabaseMealPlans();
        },
        onLongPress: _showCalendarDialog,
        child: Stack(
          children: [
            (isSelected)
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dayLetters[date.weekday % 7],
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date.day.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Text(
                      dayLetters[date.weekday % 7],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      date.day.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    if (isToday)
                      const SizedBox(height: 2),
                    if (isToday)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
            // Meal count badge - always show if meals exist, regardless of selection
            if (mealsForDate > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    mealsForDate.toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSections() {
    final mealTypes = ['breakfast', 'lunch', 'dinner'];
    final mealTypeLabels = ['Breakfast', 'Lunch', 'Dinner'];
    
    return Column(
      children: mealTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final mealType = entry.value;
        final label = mealTypeLabels[index];
        
        final mealsForType = _filteredMeals.where((meal) => 
          meal['meal_type']?.toString().toLowerCase() == mealType
        ).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal type header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Meals for this type
            if (mealsForType.isNotEmpty)
              ...mealsForType.map((meal) => _buildMealCard(meal))
            else
              Container(
                alignment: Alignment.centerLeft,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  'No $label planned',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,   
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
                                    final mealId = meal['id']?.toString() ?? '';
                                    final isSelected = _selectedMealsForDeletion.contains(mealId);
                                    final recipeData = meal['recipes'];
                                    final recipeId = recipeData?['id']?.toString() ?? mealId;
    bool isHovered = false;
    
    // Validate recipe data
    if (recipeData == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Text(
          'Error: Recipe data not found',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
    
    return StatefulBuilder(
      builder: (context, localSetState) {
        return MouseRegion(
          onEnter: (_) => localSetState(() => isHovered = true),
          onExit: (_) => localSetState(() => isHovered = false),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered ? const Color(0xFF4CAF50) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isSelected ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: const Color(0xFF4CAF50),
                highlightColor: const Color(0xFF4CAF50),
                                      onTap: () {
                                         if (_isDeleteMode) {
                                           setState(() {
                                            if (isSelected) {
                                               _selectedMealsForDeletion.remove(mealId);
                                             } else {
                                               _selectedMealsForDeletion.add(mealId);
                                             }
                                           });
                                        } else {
                                          _navigateToRecipe(context, recipeId);
                                        }
                                      },
                onLongPress: () {
                  if (!_isDeleteMode) {
                    setState(() {
                      _isDeleteMode = true;
                      _selectedMealsForDeletion.add(mealId);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (recipeData?['image_url'] ?? '').toString().isNotEmpty
                                ? Image.network(
                                    recipeData!['image_url'],
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.restaurant, color: Colors.grey),
                                  ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              recipeData?['title'] ?? meal['title'] ?? 'Unknown Recipe',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isHovered ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                        ),
                      ),
                      if ((meal['meal_time'] as String?)?.isNotEmpty == true)
                        Text(
                          _formatTime((meal['meal_time'] as String)),
                          style: TextStyle(
                            fontSize: 12,
                            color: isHovered ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCalendarDialog() {
    // Calculate meal counts for each date
    final mealCounts = <DateTime, int>{};
    for (final meal in allMealPlans) {
      final mealDate = DateTime.parse(meal['date']);
      final dateKey = DateTime(mealDate.year, mealDate.month, mealDate.day);
      mealCounts[dateKey] = (mealCounts[dateKey] ?? 0) + 1;
    }
    
    showDialog(
      context: context,
      builder: (context) => _CalendarDialog(
        selectedDate: selectedDate,
        mealCounts: mealCounts,
        onDateSelected: (date) {
          setState(() {
            selectedDate = date;
          });
          _fetchSupabaseMealPlans();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      String cleanTime = timeString.replaceAll(RegExp(r'[^\d:]'), '');
      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = parts[1];
          if (hour == 0) return '12:${minute.padLeft(2, '0')} AM';
          if (hour < 12) return '${hour}:${minute.padLeft(2, '0')} AM';
          if (hour == 12) return '12:${minute.padLeft(2, '0')} PM';
          return '${hour - 12}:${minute.padLeft(2, '0')} PM';
        }
      }
      final hour = int.tryParse(cleanTime);
      if (hour != null) {
        if (hour == 0) return '12:00 AM';
        if (hour < 12) return '$hour:00 AM';
        if (hour == 12) return '12:00 PM';
        return '${hour - 12}:00 PM';
      }
      return timeString;
    } catch (_) {
      return timeString;
    }
  }
}

// Calendar Dialog for selecting dates
class _CalendarDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<DateTime, int> mealCounts;
  final Function(DateTime) onDateSelected;

  const _CalendarDialog({
    required this.selectedDate,
    required this.mealCounts,
    required this.onDateSelected,
  });

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  late DateTime currentMonth;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month, 1);
    selectedDate = widget.selectedDate;
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
  }

  List<DateTime> _getDaysInMonth() {
    final firstDay = currentMonth;
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDay.day;

    final firstDayOfWeek = firstDay.weekday; // Monday = 1
    final List<DateTime> days = [];

    // Add days from previous month to fill the first week
    for (int i = firstDayOfWeek - 1; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }
    
    // Add days of current month
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(currentMonth.year, currentMonth.month, i));
    }
    
    // Add days from next month to fill the last week
    final remainingDays = 42 - days.length; // 6 rows * 7 days
    for (int i = 1; i <= remainingDays; i++) {
      days.add(lastDay.add(Duration(days: i)));
    }
    
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth, 
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _nextMonth, 
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == currentMonth.month;
                final isSelected = day.year == selectedDate.year && 
                                 day.month == selectedDate.month && 
                                 day.day == selectedDate.day;
                final isToday = day.year == DateTime.now().year && 
                               day.month == DateTime.now().month && 
                               day.day == DateTime.now().day;
                final dateKey = DateTime(day.year, day.month, day.day);
                final mealCount = widget.mealCounts[dateKey] ?? 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDate = day;
                    });
                    widget.onDateSelected(day);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFFFF6B35)
                          : isToday 
                              ? const Color(0xFFFF6B35).withOpacity(0.3)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white
                                  : isCurrentMonth 
                                      ? Colors.black 
                                      : Colors.grey,
                              fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Meal count badge
                        if (mealCount > 0 && isCurrentMonth)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                mealCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 