import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import './dietary_preferences_screen.dart';
import './meal_plan_history_screen.dart'; // Added import for MealPlanHistoryScreen
import './meal_tracker_screen.dart'; // Add this import for the new page
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  File? _profileImage;
  String? _profileImagePath;
  String? _avatarUrl;
  bool _uploadingImage = false;

  // Example health goals
  final List<String> _availableHealthGoals = [
    'Lose Weight',
    'Build Muscle',
    'Improve Endurance',  
    'Eat Healthier',
    'Maintain Weight',
  ];

  bool _hasShownInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadProfileImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasShownInitialLoading && _loading) {
      _hasShownInitialLoading = true;
      // Use a microtask to avoid showing dialog during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showInitialLoadingDialog();
        }
      });
    }
  }

  Future<void> _showInitialLoadingDialog() async {
    // Show loading dialog for initial profile fetch
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
                  const Text(
                    'Loading Profile...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please wait while we load your profile',
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

    // Wait for profile to finish loading
    while (_loading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }
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
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (!mounted) return;
        if (data != null) {
          setState(() {
            _dietType = data['diet_type'] as String?;
            _allergies = data['allergies'] as List<dynamic>? ?? [];
            _servings = data['servings'] as int?;
            _avatarUrl = data['avatar_url'] as String?;
            if (data['health_goals'] != null) {
              _healthGoals = List<String>.from(data['health_goals']);
            }
          });
        }
      } catch (e) {
        print('Error fetching user preferences: $e');
      }
    }
    if (!mounted) return;
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

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final key = 'profile_image_path_${user.id}';
    final path = prefs.getString(key);
    if (path != null && await File(path).exists()) {
      if (mounted) {
        setState(() {
          _profileImagePath = path;
          _profileImage = File(path);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _profileImagePath = null;
          _profileImage = null;
        });
      }
    }
  }

  Future<void> _saveProfileImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final key = 'profile_image_path_${user.id}';
    await prefs.setString(key, path);
  }

  Future<void> _deleteProfileImage() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final key = 'profile_image_path_${user.id}';
    if (_profileImagePath != null) {
      final file = File(_profileImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      if (mounted) {
        setState(() {
          _profileImage = null;
          _profileImagePath = null;
        });
      }
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profile_pictures');
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedImage = await File(pickedFile.path).copy('${profileDir.path}/$fileName');
      await _saveProfileImagePath(savedImage.path);
      if (mounted) {
        setState(() {
          _profileImage = savedImage;
          _profileImagePath = savedImage.path;
        });
      }
    }
  }

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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showProfileImagePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickAndUploadProfileImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Use Image URL'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showImageUrlDialog();
                },
              ),
            ],  
          ),
        );
      },
    );
  }

  Future<void> _showImageUrlDialog() async {
    if (!mounted) return;
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'https://example.com/image.jpg'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.startsWith('http')) {
                Navigator.pop(context, url);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      
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
                    const Text(
                      'Updating Profile Picture...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please wait while we update your profile',
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
        await Supabase.instance.client.from('profiles').update({'avatar_url': result}).eq('id', user.id);
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        if (mounted) {
          setState(() {
            _avatarUrl = result;
          });
        }
        
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
        print('Error updating profile image URL: $e');
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile picture: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 241, 241, 241),
      body: _loading
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
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with avatar and camera icon (not in scroll view)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 103, 196, 106),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                    ),
                    // Avatar and camera icon always within bounds
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Stack(
                        clipBehavior: Clip.none,
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
                                    ? Icon(Icons.person, size: 90, color: const Color.fromARGB(255, 97, 212, 86))
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: -8,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _uploadingImage ? null : () {
                                print('Camera icon tapped!');
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
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    Icons.camera_alt, 
                                    color: _uploadingImage 
                                        ? Colors.grey 
                                        : const Color.fromARGB(255, 97, 212, 86), 
                                    size: 24
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
                // The rest of the profile content is scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 105), // More space for avatar overlap
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
                              _MinimalOption(
                                label: 'Dietary Preferences',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => DietaryPreferencesScreen()),
                                  );
                                },
                              ),
                              _MinimalDivider(),
                              _MinimalOption(
                                label: 'Meal Tracker',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => MealTrackerScreen()),
                                  );
                                },
                              ),
                              _MinimalDivider(),
                              _MinimalOption(
                                label: 'Meal Plan History',
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
                        const SizedBox(height: 24),
                        // Restored Logout Button with more padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              child: const Text('Logout', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 224, 83, 83), // Modern blue-gray
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: Colors.grey[300],
        thickness: 1,
        height: 0,
      ),
    );
  }
} 