import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  String? _avatarUrl;
  bool _isLoading = false;

  String? get avatarUrl => _avatarUrl;
  bool get isLoading => _isLoading;

  Future<void> fetchUserAvatar() async {
    if (_avatarUrl != null) return; // Already loaded
    
    _isLoading = true;
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      
      _avatarUrl = data?['avatar_url'] as String?;
    } catch (e) {
      AppLogger.error('Error fetching user avatar', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAvatar(String? newAvatarUrl) {
    _avatarUrl = newAvatarUrl;
    notifyListeners();
  }

  void clearAvatar() {
    _avatarUrl = null;
    notifyListeners();
  }
}
