import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/profile_service.dart';

/// Round avatar backed by [ProfileService]. Shows the user's saved photo when
/// present, else [fallbackAsset], else a person icon. Rebuilds live when the
/// photo changes, so the chat header and member ID card update instantly.
class ProfileAvatar extends StatefulWidget {
  final double radius;
  final String? fallbackAsset;
  const ProfileAvatar({super.key, required this.radius, this.fallbackAsset});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  @override
  void initState() {
    super.initState();
    ProfileService.load();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileService.avatar,
      builder: (context, path, _) {
        if (path != null) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: FileImage(File(path)),
          );
        }
        if (widget.fallbackAsset != null) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: AppColors.surfaceAlt,
            backgroundImage: AssetImage(widget.fallbackAsset!),
          );
        }
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: AppColors.surfaceAlt,
          child: Icon(Icons.person_rounded, size: widget.radius, color: const Color(0xFF9F1D1F)),
        );
      },
    );
  }
}
