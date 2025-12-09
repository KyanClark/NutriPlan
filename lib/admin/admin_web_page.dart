import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tabs/recipe_management_tab.dart';
import 'tabs/feedback_management_tab.dart';

class AdminWebPage extends StatefulWidget {
  const AdminWebPage({super.key});

  @override
  State<AdminWebPage> createState() => _AdminWebPageState();
}

class _AdminWebPageState extends State<AdminWebPage> {
  int _selectedIndex = 0; // 0 = recipes, 1 = feedback
  bool _isDarkMode = false;

  void _onLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Sign out from Supabase Auth
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Ignore sign out errors
    }
    if (mounted) {
      // Go back to admin login page
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    final Color scaffoldBg = _isDarkMode ? const Color(0xFF0F0F0F) : Colors.grey[100]!;
    final Color panelBg = _isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final Color sidebarText = _isDarkMode ? Colors.white : const Color(0xFF4CAF50);
    final Color sidebarIcon = _isDarkMode ? Colors.white : const Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/widgets/NutriPlan_Logo.png',
                height: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'NutriPlan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Sidebar
              Container(
                width: isWideScreen ? 240 : 200,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 20,
                            color: sidebarIcon,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Panel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: sidebarText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SidebarItem(
                      icon: Icons.restaurant_menu,
                      label: 'Recipe Management',
                      selected: _selectedIndex == 0,
                      onTap: () {
                        setState(() => _selectedIndex = 0);
                      },
                    ),
                    _SidebarItem(
                      icon: Icons.feedback,
                      label: 'Feedback Management',
                      selected: _selectedIndex == 1,
                      onTap: () {
                        setState(() => _selectedIndex = 1);
                      },
                    ),
                    const Spacer(),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: _onLogout,
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: panelBg,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _selectedIndex == 0
                          ? RecipeManagementTab(
                              isDarkMode: _isDarkMode,
                              onToggleDarkMode: (value) {
                                setState(() => _isDarkMode = value);
                              },
                            )
                          : FeedbackManagementTab(
                              isDarkMode: _isDarkMode,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: selected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? const Color(0xFF4CAF50) : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? const Color(0xFF4CAF50) : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}






