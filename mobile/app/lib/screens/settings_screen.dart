import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import 'phone_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  bool _darkModeOn = false;
  int _langIdx = 1; // 0 = Tamil, 1 = English
  bool _editSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _langIdx = p.getInt('app_language') ?? _langIdx;
      _notificationsOn = p.getBool('pref_notifications') ?? _notificationsOn;
      _darkModeOn = p.getBool('pref_dark_mode') ?? _darkModeOn;
    });
  }

  Future<void> _setLang(int i) async {
    setState(() => _langIdx = i);
    (await SharedPreferences.getInstance()).setInt('app_language', i);
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notificationsOn = v);
    (await SharedPreferences.getInstance()).setBool('pref_notifications', v);
  }

  Future<void> _setDarkMode(bool v) async {
    setState(() => _darkModeOn = v);
    (await SharedPreferences.getInstance()).setBool('pref_dark_mode', v);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dark mode ${v ? 'on' : 'off'} — applies app-wide in a future update.')),
      );
    }
  }

  void _editProfile() {
    final nameC = TextEditingController(text: ProfileService.displayName.value);
    final cityC = TextEditingController(text: ProfileService.city.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          bool submitting = _editSubmitting;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: cityC, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            _editSubmitting = true;
                            setSheet(() {});
                            await ProfileService.saveName(nameC.text);
                            await ProfileService.saveCity(cityC.text);
                            _editSubmitting = false;
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F1D1F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Save', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => _editSubmitting = false);
  }

  void _showInfoDialog(String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4A4949), height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Account', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text('This permanently deletes your account. This cannot be undone.',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF4A4949))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9F1D1F), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((r) => r.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in again, then delete your account.')),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.message}')));
      }
    }
  }

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
      // Back to the app root (Home). MainShell also resets to the Home tab
      // on logout, so the user never lands on a gated screen.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
              // Extra bottom padding clears the Android system nav bar so the
              // Delete account / Log out buttons are never hidden behind it.
              padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + MediaQuery.of(context).padding.bottom),
              child: Column(
                children: [
                  // ── Edit Profile ──────────────────────────────────
                  _SettingsTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Update your info to stay connected.',
                    onTap: _editProfile,
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ─────────────────────────────────
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Preferences',
                    subtitle: 'Manage your app notifications.',
                    value: _notificationsOn,
                    onChanged: _setNotifications,
                  ),
                  const SizedBox(height: 12),

                  // ── App Theme ─────────────────────────────────────
                  _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'App Theme',
                    subtitle: 'Enable mode which you prefer.',
                    value: _darkModeOn,
                    onChanged: _setDarkMode,
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
                                onTap: () => _setLang(0),
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
                                onTap: () => _setLang(1),
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
                    onTap: () => _showInfoDialog(
                      'About My TVK',
                      'My TVK is the official citizen platform of Tamilaga Vettri Kazhagam — chat with the leader, track projects and news, join as a member, and raise complaints.\n\nFounded 2023 · Leader: Thiru Vijay',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Help & Support ────────────────────────────────
                  _SettingsTile(
                    icon: Icons.support_rounded,
                    title: 'Help and Support',
                    subtitle: 'Contact our support team.',
                    onTap: () => _showInfoDialog(
                      'Help & Support',
                      'Need help?\n\nEmail: support@tvkvijay.com\nPhone: 1800-000-0000\n\nOur team responds within 24 hours.',
                    ),
                  ),
                  const SizedBox(height: 120),

                  // ── Bottom action buttons ─────────────────────────
                  // Logged out → single Log in button. Logged in → Delete
                  // account + Log out. Labels shrink to fit so they never
                  // overflow on narrow screens.
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final loggedIn = snapshot.data != null;
                      final loginBtn = _ActionButton(
                        label: loggedIn ? 'Log out' : 'Log in',
                        color: const Color(0xFF9F1D1F),
                        onTap: loggedIn
                            ? _confirmSignOut
                            : () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const PhoneLoginScreen())),
                      );
                      if (!loggedIn) return loginBtn;
                      return Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Delete account',
                              color: const Color(0xFF4A4949),
                              onTap: _confirmDeleteAccount,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: loginBtn),
                        ],
                      );
                    },
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

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.28,
            ),
          ),
        ),
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
