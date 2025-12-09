import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../widgets/profile_avatar_widget.dart';
import '../home/home_page.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AccountSwitchScreen extends StatefulWidget {
  const AccountSwitchScreen({super.key});

  @override
  State<AccountSwitchScreen> createState() => _AccountSwitchScreenState();
}

class _AccountSwitchScreenState extends State<AccountSwitchScreen> {
  static const _savedAccountsKey = 'saved_accounts';
  List<Map<String, dynamic>> _savedAccounts = [];
  bool _isLoading = true;

  Widget _buildBrandRow({
    Color color = Colors.black87,
    double fontSize = 24,
    double logoSize = 40,
    double letterSpacing = 1.2,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/widgets/NutriPlan_Logo.png',
          height: logoSize,
        ),
        const SizedBox(width: 10),
        Text(
          'NutriPlan',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding to ensure build completes first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
    });
  }

  Future<void> _init() async {
    // Always show splash screen - load saved accounts
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_savedAccountsKey) ?? [];
      final accounts = <Map<String, dynamic>>[];
      for (final raw in rawList) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          accounts.add(map);
        } catch (_) {
          // ignore bad entries
        }
      }

      if (!mounted) return;
      setState(() {
        _savedAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors gracefully
      if (!mounted) return;
      setState(() {
        _savedAccounts = [];
        _isLoading = false;
      });
    }
  }

  void _openLogin({String? initialInput}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LoginScreen(initialInput: initialInput),
      ),
    );
  }

  Future<void> _loginWithAccount({
    required String displayName,
    required String identifier,
  }) async {
    if (!mounted) return;

    // If there's no active session (e.g. app fully restarted), just go to login
    if (Supabase.instance.client.auth.currentSession == null) {
      _openLogin(initialInput: identifier);
      return;
    }

    // 1) Show loading dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(height: 16),
                Text(
                  'Logging you in...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    // 2) Show success / check animation dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 70,
                  width: 70,
                  child: Lottie.asset(
                    'assets/widgets/Checked.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome back, $displayName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    // 3) Go straight to home (session is still active)
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Future<void> _removeAccount(String userId, String displayName) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Account'),
        content: Text('Are you sure you want to remove $displayName from saved accounts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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

    final prefs = await SharedPreferences.getInstance();
    _savedAccounts.removeWhere((a) => a['user_id'] == userId);
    final encoded = _savedAccounts.map((a) => jsonEncode(a)).toList();
    await prefs.setStringList(_savedAccountsKey, encoded);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBrandRow(
                color: Colors.white,
                fontSize: 32,
                logoSize: 52,
                letterSpacing: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Healthy recipes, smarter planning.\nPick an account or sign in to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color.fromARGB(220, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 32),
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  if (_savedAccounts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Saved accounts',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._savedAccounts.map((acc) {
                          final displayName =
                              (acc['display_name'] as String?) ?? 'NutriPlan user';
                          final identifier =
                              (acc['identifier'] as String?) ?? '';
                          final avatarUrl = acc['avatar_url'] as String?;
                          final gender = acc['gender'] as String?;
                          final userId = acc['user_id'] as String? ?? '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () => _loginWithAccount(
                                displayName: displayName,
                                identifier: identifier,
                              ),
                              leading: ProfileAvatarWidget(
                                avatarUrl: avatarUrl,
                                gender: gender,
                                radius: 22,
                                backgroundColor: Colors.grey[200],
                              ),
                              title: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: identifier.isNotEmpty
                                  ? Text(
                                      identifier,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                color: Colors.grey[600],
                                onPressed: () => _removeAccount(userId, displayName),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  // Bottom actions
                  if (_savedAccounts.isNotEmpty) ...[
                    ElevatedButton(
                      onPressed: () => _openLogin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Login another account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else ...[
                    // No saved accounts: show only Login / Sign up
                    ElevatedButton(
                      onPressed: () => _openLogin(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
    );
  }
}


