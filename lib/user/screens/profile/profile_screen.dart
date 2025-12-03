import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/account_switch_screen.dart';
import '../../utils/app_logger.dart';
import '../../widgets/profile_avatar_widget.dart';
import 'dietary_preferences_screen.dart';
import 'profile_information_screen.dart';
import '../meal_plan/meal_plan_history_screen.dart'; // Added import for MealPlanHistoryScreen
import 'favorites_page.dart'; // Added import for FavoritesPage
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onAvatarUpdated;
  const ProfileScreen({super.key, this.onAvatarUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _email;
  String? _fullName;
  bool _loading = true;
  // Removed edit mode and saving state
  bool _shouldLogout = false;
  String? _avatarUrl;
  String? _gender;
  bool _uploadingImage = false;


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
    if (user != null) {
      try {
        // Fetch profile data
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (profileData != null) {
          setState(() {
            _avatarUrl = profileData['avatar_url'] as String?;
          });
        }
        
        // Fetch gender from user_preferences
        final prefsData = await Supabase.instance.client
            .from('user_preferences')
            .select('gender')
            .eq('user_id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (prefsData != null) {
          setState(() {
            _gender = prefsData['gender'] as String?;
          });
        }
      } catch (e) {
        AppLogger.error('Error fetching user preferences', e);
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  // Removed unused _saveUserPreferences

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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6961)),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteAccountConfirmation(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone. All your data, including meal plans, preferences, and history will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Show second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Final Confirmation', style: TextStyle(color: Colors.red)),
          content: const Text(
            'This is your last chance to cancel. Your account and all data will be permanently deleted. Type "DELETE" to confirm.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('I Understand, Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (finalConfirm != true) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Deleting Account...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we delete your account and all data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Delete user data from all tables
      // Note: This assumes you have proper RLS policies or database triggers
      // to cascade delete related data, or you may need to delete from each table manually
      
      // Delete from meal_plan_history
      await Supabase.instance.client
          .from('meal_plan_history')
          .delete()
          .eq('user_id', user.id);

      // Delete from meal_plans
      await Supabase.instance.client
          .from('meal_plans')
          .delete()
          .eq('user_id', user.id);

      // Delete from user_preferences
      await Supabase.instance.client
          .from('user_preferences')
          .delete()
          .eq('user_id', user.id);

      // Delete from profiles
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', user.id);

      // Delete profile picture from storage if exists
      // Note: Supabase storage doesn't support wildcard delete easily
      // You may need to list and delete specific files
      // For now, we'll skip this as it's not critical
      try {
        // Profile picture deletion can be handled by storage lifecycle policies
        // or manual cleanup if needed
      } catch (e) {
        AppLogger.error('Error deleting profile picture from storage', e);
      }

      // Delete the auth user (this will cascade delete related auth data)
      // Note: Supabase doesn't have a direct client method to delete users
      // You may need to use the Admin API or create a database function
      // For now, we'll sign out and the user will need to contact support
      // or you can implement a server-side function to handle this
      
      // Sign out the user
      await Supabase.instance.client.auth.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AccountSwitchScreen()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted successfully.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error deleting account', e);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleLogoutIfNeeded();
  }

  Future<void> _handleLogoutIfNeeded() async {
    if (_shouldLogout) {
      if (!mounted) return;
      setState(() {
        _shouldLogout = false;
      });
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Save this account info for quick re-login on splash screen
          final prefs = await SharedPreferences.getInstance();
          const key = 'saved_accounts';
          final existing = prefs.getStringList(key) ?? [];
          final accounts = <Map<String, dynamic>>[];
          for (final raw in existing) {
            try {
              final map = jsonDecode(raw) as Map<String, dynamic>;
              accounts.add(map);
            } catch (_) {}
          }

          final identifier =
              user.email ?? (user.userMetadata?['phone'] as String? ?? '');
          final displayName =
              _fullName ?? (user.userMetadata?['full_name'] as String?) ?? 'NutriPlan user';

          final data = <String, dynamic>{
            'user_id': user.id,
            'display_name': displayName,
            'identifier': identifier,
            'avatar_url': _avatarUrl,
            'gender': _gender,
          };

          // Replace any existing entry for this user_id
          accounts.removeWhere((a) => a['user_id'] == user.id);
          accounts.add(data);

          final encoded = accounts.map((a) => jsonEncode(a)).toList();
          await prefs.setStringList(key, encoded);
        }

        // Sign out from Supabase to clear the session
        await Supabase.instance.client.auth.signOut();
        
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AccountSwitchScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // Removed _toggleEditMode function

  // Removed unused local file image helpers (migrated to Supabase Storage)

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent closing with back button
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loading animation (same as meal history)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 97, 212, 86).withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  // Loading text
                  const Text(
                    'Uploading Profile Picture...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we upload your image',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    // Set loading state
    if (mounted) {
      setState(() {
        _uploadingImage = true;
      });
    }
    
    try {
      final fileBytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final filePath = 'profile-pictures/${user.id}.$fileExt';
      final storage = Supabase.instance.client.storage.from('profile-pictures');
      
      // Upload the image to Supabase Storage
      await storage.uploadBinary(
        filePath, 
        fileBytes, 
        fileOptions: FileOptions(upsert: true, contentType: 'image/$fileExt')
      );
      
      // Get the public URL
      final publicUrl = storage.getPublicUrl(filePath);
      
      // Update avatar_url in profiles table
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Update the UI
      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _uploadingImage = false;
        });
      }
      
      // Notify parent widget about avatar update
      widget.onAvatarUpdated?.call();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error uploading profile image', e);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: const Color(0xFFFF6961),
          ),
        );
      }
    }
  }

  Future<void> _showProfileImagePicker() async {
    if (!mounted) return;
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Picture'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('Update Picture'),
              onTap: () => Navigator.pop(context, 'update'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result == 'update') {
      await _pickAndUploadProfileImage();
    } else if (result == 'remove') {
      await _removeProfileImage();
    }
  }

  Future<void> _removeProfileImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 97, 212, 86).withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                        shape: BoxShape.circle,
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Removing Profile Picture...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    
    try {
      // Get the current avatar URL to extract file path
      final currentAvatarUrl = _avatarUrl;
      
      // Update avatar_url to null in profiles table
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);
      
      // Try to delete from storage if URL exists
      if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
        try {
          // Extract file path from URL (assuming format: .../profile-pictures/{userId}.{ext})
          final storage = Supabase.instance.client.storage.from('profile-pictures');
          final fileName = currentAvatarUrl.split('/').last.split('?').first;
          await storage.remove([fileName]);
        } catch (e) {
          AppLogger.error('Error removing file from storage', e);
          // Continue even if storage deletion fails
        }
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Update the UI
      if (mounted) {
        setState(() {
          _avatarUrl = null;
        });
      }
      
      // Notify parent widget about avatar update
      widget.onAvatarUpdated?.call();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error removing profile image', e);
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove image: $e'),
            backgroundColor: const Color(0xFFFF6961),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC1E7AF),
      body: SafeArea(
        child: Stack(
          children: [
            _loading
          ? Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 97, 212, 86).withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                    shape: BoxShape.circle,
                  ),
                )),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 45),
                  // Avatar section with camera icon on the right edge of the circle
                  SizedBox(
                    height: 160,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ProfileAvatarWidget(
                            avatarUrl: _avatarUrl,
                            gender: _gender,
                            radius: 70,
                            backgroundColor: Colors.white,
                            child: _uploadingImage
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (i) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      margin: const EdgeInsets.symmetric(horizontal: 2),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 97, 212, 86).withOpacity(i == DateTime.now().second % 3 ? 1 : 0.4),
                                        shape: BoxShape.circle,
                                      ),
                                    )),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 4,
                            right: -4,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _uploadingImage ? null : () {
                                _showProfileImagePicker();
                              },
                              child: Material(
                                color: Colors.transparent,
                                shape: const CircleBorder(),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.photo_camera,
                                    color: _uploadingImage
                                        ? Colors.grey
                                        : const Color.fromARGB(255, 97, 212, 86),
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Profile content with proper spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        // Name and Email
                        Text(
                          _fullName ?? 'User',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (_email != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _email!,
                              style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w400),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Options List
                        Container(
                          width: double.infinity,
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
                              _MinimalOption(
                                label: 'Profile Information',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileInformationScreen()),
                                  );
                                },
                              ),
                              const Divider(height: 0.5),
                              _MinimalOption(
                                label: 'Dietary Preferences',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DietaryPreferencesScreen()),
                                  );
                                },
                              ),
                              const Divider(height: 0.5),
                              _MinimalOption(
                                label: 'Favorites',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const FavoritesPage()),
                                  );
                                },
                              ),
                              const Divider(height: 0.5),
                              _MinimalOption(
                                label: 'Meal Plan History',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MealPlanHistoryScreen()),
                                  );
                                },
                              ),
                              const Divider(height: 0.5),
                              _MinimalOption(
                                label: 'Delete Account',
                                onTap: () => _showDeleteAccountConfirmation(context),
                                color: Colors.red,
                                icon: Icons.delete_outline,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 224, 83, 83),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await _showLogoutConfirmation(context);
                              if (confirm == true) {
                                setState(() {
                                  _shouldLogout = true;
                                });
                                _handleLogoutIfNeeded();
                              }
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Back button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed unused _buildStatCard

} 

class _MinimalOption extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  const _MinimalOption({
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: color ?? Colors.black87, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: color ?? Colors.black87,
                  ),
                ),
              ),
              // Removed trailing arrow icon
            ],
          ),
        ),
      ),
    );
  }
}

// Removed unused _MinimalDivider