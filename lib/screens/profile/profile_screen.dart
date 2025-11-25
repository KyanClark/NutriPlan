import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_screen.dart';
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
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (data != null) {
          setState(() {
            _avatarUrl = data['avatar_url'] as String?;
          });
        }
      } catch (e) {
        print('Error fetching user preferences: $e');
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
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
      print('Error uploading profile image: $e');
      
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
          print('Error removing file from storage: $e');
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
      print('Error removing profile image: $e');
      
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
                  // Avatar section
                  SizedBox(
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Colors.white,
                          backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? NetworkImage(_avatarUrl!)
                              : null,
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
                              : (_avatarUrl == null || _avatarUrl!.isEmpty)
                                  ? const Icon(Icons.person, size: 90, color: Color.fromARGB(255, 97, 212, 86))
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: MediaQuery.of(context).size.width / 2 - 70 - 120,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _uploadingImage ? null : () {
                              _showProfileImagePicker();
                            },
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: Container(
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
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.photo_camera, 
                                  color: _uploadingImage
                                      ? Colors.grey 
                                      : const Color.fromARGB(255, 97, 212, 86), 
                                  size: 16
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
  const _MinimalOption({required this.label, required this.onTap});
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
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
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