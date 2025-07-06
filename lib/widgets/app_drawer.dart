import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  final UserProfile? userProfile;
  
  const AppDrawer({super.key, this.userProfile});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header with user info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userProfile?.name.isNotEmpty == true 
                      ? userProfile!.name 
                      : 'Welcome!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NutriPlan User',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Profile info section
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Profile Information'),
                  const SizedBox(height: 12),
                  
                  if (userProfile != null) ...[
                    _buildInfoTile(
                      icon: Icons.fitness_center,
                      title: 'Health Goal',
                      subtitle: userProfile!.healthGoal,
                    ),
                    _buildInfoTile(
                      icon: Icons.restaurant_menu,
                      title: 'Dietary Preferences',
                      subtitle: userProfile!.dietaryPreferences.isEmpty 
                          ? 'None set' 
                          : userProfile!.dietaryPreferences.join(', '),
                    ),
                    _buildInfoTile(
                      icon: Icons.warning,
                      title: 'Allergies',
                      subtitle: userProfile!.allergies.isEmpty 
                          ? 'None' 
                          : userProfile!.allergies.join(', '),
                    ),
                    _buildInfoTile(
                      icon: Icons.attach_money,
                      title: 'Budget',
                      subtitle: '\$${userProfile!.budget.toStringAsFixed(2)}',
                    ),
                  ] else ...[
                    _buildInfoTile(
                      icon: Icons.info_outline,
                      title: 'No Profile Set',
                      subtitle: 'Tap to create your profile',
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  
                  _buildDrawerTile(
                    icon: Icons.edit,
                    title: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings coming soon!')),
                      );
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Navigate to help
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support coming soon!')),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('App Info'),
                  const SizedBox(height: 12),
                  
                  _buildInfoTile(
                    icon: Icons.info,
                    title: 'Version',
                    subtitle: '1.0.0',
                  ),
                  _buildInfoTile(
                    icon: Icons.copyright,
                    title: 'NutriPlan',
                    subtitle: '© 2024 All rights reserved',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
} 