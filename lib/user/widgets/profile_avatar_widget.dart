import 'package:flutter/material.dart';

/// Widget that displays a user's profile picture with gender-based default fallback
class ProfileAvatarWidget extends StatelessWidget {
  final String? avatarUrl;
  final String? gender; // 'male' or 'female'
  final double radius;
  final Color? backgroundColor;
  final Widget? child; // Optional child widget (e.g., camera icon overlay)

  const ProfileAvatarWidget({
    super.key,
    this.avatarUrl,
    this.gender,
    required this.radius,
    this.backgroundColor,
    this.child,
  });

  /// Get the default profile picture asset path based on gender
  static String getDefaultProfilePicture(String? gender) {
    if (gender?.toLowerCase() == 'female') {
      return 'assets/default-profile-pictures/woman.png';
    }
    // Default to young-boy.png for male or unknown gender
    return 'assets/default-profile-pictures/young-boy.png';
  }

  @override
  Widget build(BuildContext context) {
    // If avatar URL exists and is not empty, use it
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[200],
        backgroundImage: NetworkImage(avatarUrl!),
        child: child,
      );
    }

    // Otherwise, use default picture based on gender
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      backgroundImage: AssetImage(getDefaultProfilePicture(gender)),
      onBackgroundImageError: (exception, stackTrace) {
        // Fallback to icon if asset fails to load
      },
      child: child, // Only show child if explicitly provided (e.g., uploading indicator)
    );
  }
}

