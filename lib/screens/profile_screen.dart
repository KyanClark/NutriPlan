import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import './nutritional_tracking_screen.dart';
import './dietary_preferences_screen.dart';
import './meal_plan_history_screen.dart'; // Added import for MealPlanHistoryScreen

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _fullName;
  String? _bio;
  String? _dietType;
  List<dynamic>? _allergies;
  int? _servings;
  List<String> _healthGoals = [];
  bool _loading = true;
  // Removed edit mode and saving state
  bool _shouldLogout = false;

  // Example health goals
  final List<String> _availableHealthGoals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Endurance',
    'Eat Healthier',
    'Maintain Weight',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _loading = true);
    final user = Supabase.instance.client.auth.currentUser;
    _email = user?.email;
    _fullName = user?.userMetadata?['full_name'] as String?;
    _bio = user?.userMetadata?['bio'] as String?;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_preferences')
            .select()
            .eq('user_id', user.id)
            .maybeSingle();
        if (data != null) {
          setState(() {
            _dietType = data['diet_type'] as String?;
            _allergies = data['allergies'] as List<dynamic>? ?? [];
            _servings = data['servings'] as int?;
            if (data['health_goals'] != null) {
              _healthGoals = List<String>.from(data['health_goals']);
            }
          });
        }
      } catch (e) {
        print('Error fetching user preferences: $e');
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveUserPreferences() async {
    // Removed _saving = true;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client
            .from('user_preferences')
            .upsert({
              'user_id': user.id,
              'diet_type': _dietType,
              'allergies': _allergies ?? [],
              'servings': _servings,
              'health_goals': _healthGoals,
            });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
    // Removed setState(() => _saving = false);
  }

  Future<bool?> _showLogoutConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleLogoutIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleLogoutIfNeeded();
  }

  Future<void> _handleLogoutIfNeeded() async {
    if (_shouldLogout) {
      setState(() {
        _shouldLogout = false;
      });
      try {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ' + e.toString())),
        );
      }
    }
  }

  // Removed _toggleEditMode function

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Purple background with profile image (no back button)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 200, // Increased height for more overlap room
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 103, 196, 106), // Main project color
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                      ),
                      // Overlapping large profile avatar at the bottom center
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: -58, // Half of avatar radius to overlap
                        child: Center(
                          child: CircleAvatar(
                            radius: 70,
                            backgroundColor: Colors.white,
                            backgroundImage: null, // TODO: Add user image if available
                            child: Icon(Icons.person, size: 90, color: const Color.fromARGB(255, 97, 212, 86)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 65), // Reduced spacing between avatar and name/email
                  // Name and Email
                  Text(
                    _fullName ?? 'User',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (_email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0, bottom: 8.0), // Reduced top padding
                      child: Text(
                        _email!,
                        style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_bio != null && _bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                  if (_bio == null || _bio!.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Set your bio to let others know more about you!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black38),
                      ),
                    ),
                  const SizedBox(height: 16),
                  // New: Options List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Nutritional Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NutritionalTrackingScreen()),
                            );
                          },
                        ),
                        Container(height: 1, color: Colors.black),
                        ListTile(
                          title: const Text('Dietary Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DietaryPreferencesScreen()),
                            );
                          },
                        ),
                        Container(height: 1, color: Colors.black),
                        ListTile(
                          title: const Text('Meal Plan History', style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MealPlanHistoryScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      // Removed BottomNavigationBar from ProfileScreen
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      width: 120,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFF4CAF50),
          ],
          stops: [0.05, 0.4],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2,
          style: BorderStyle.solid,
          color: Color(0xFF4CAF50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<String?> _showAddAllergyDialog(BuildContext context) async {
    String allergy = '';
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Allergy'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter allergy'),
            onChanged: (val) => allergy = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, allergy),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
} 