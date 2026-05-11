import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  int _langIdx = 1; // 0 = Tamil, 1 = English

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Sign Out',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: const Color(0xFF111111))),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4A4949))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4A4949))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9F1D1F), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_rounded, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Content ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  // ── Edit Profile ──────────────────────────────────
                  _SettingsTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your info to stay connected.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ─────────────────────────────────
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Preferences',
                    subtitle: 'Manage your app notifications.',
                    value: _notificationsOn,
                    onChanged: (v) => setState(() => _notificationsOn = v),
                  ),
                  const SizedBox(height: 12),

                  // ── App Theme ─────────────────────────────────────
                  _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'App Theme',
                    subtitle: 'Enable mode which you prefer.',
                    value: _darkModeOn,
                    onChanged: (v) => setState(() => _darkModeOn = v),
                  ),
                  const SizedBox(height: 12),

                  // ── Language ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEBEBEB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.translate_rounded, size: 18, color: Color(0xFF111111)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Language',
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
                                Text('Switch between languages.',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _langIdx = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _langIdx == 0 ? const Color(0xFF9F1D1F) : const Color(0xFFF9D8D8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Tamil',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _langIdx == 0 ? Colors.white : const Color(0xFF9F1D1F),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _langIdx = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _langIdx == 1 ? const Color(0xFF9F1D1F) : const Color(0xFFF9D8D8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'English',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _langIdx == 1 ? Colors.white : const Color(0xFF9F1D1F),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── About us ──────────────────────────────────────
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About us',
                    subtitle: 'Learn more about the app.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),

                  // ── Help & Support ────────────────────────────────
                  _SettingsTile(
                    icon: Icons.support_rounded,
                    title: 'Help and Support',
                    subtitle: 'Contact our support team.',
                    onTap: () {},
                  ),
                  const SizedBox(height: 120),

                  // ── Bottom action buttons ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF4A4949)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Delete account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A4949),
                                letterSpacing: 0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmSignOut,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF9F1D1F)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Log out',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9F1D1F),
                                letterSpacing: 0.28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF111111)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toggle Tile ──────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF111111)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF111111))),
                Text(subtitle,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 53,
              height: 30,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? const Color(0xFF9F1D1F) : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedAlign(
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 2, offset: const Offset(0, 1))],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
