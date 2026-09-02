import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
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
      _darkModeOn = ThemeController.isDark.value;
    });
  }

  Future<void> _setLang(int i) async {
    setState(() => _langIdx = i);
    await LocaleController.set(i); // flips the whole app's language immediately
  }

  Future<void> _setNotifications(bool v) async {
    setState(() => _notificationsOn = v);
    (await SharedPreferences.getInstance()).setBool('pref_notifications', v);
  }

  Future<void> _setDarkMode(bool v) async {
    setState(() => _darkModeOn = v);
    await ThemeController.set(v); // flips the whole app immediately
  }

  void _editProfile() {
    final nameC = TextEditingController(text: ProfileService.displayName.value);
    final cityC = TextEditingController(text: ProfileService.city.value);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
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
                Text(t('settings.edit_profile'), style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: nameC, decoration: InputDecoration(labelText: t('settings.name_label'), border: const OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: cityC, decoration: InputDecoration(labelText: t('settings.city_label'), border: const OutlineInputBorder())),
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
                        : Text(t('settings.save'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(body, style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t('settings.close'))),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t('settings.delete_account_title'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(t('settings.delete_account_body'),
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('settings.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('settings.delete'), style: GoogleFonts.plusJakartaSans(color: const Color(0xFF9F1D1F), fontWeight: FontWeight.w700)),
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
            SnackBar(content: Text(t('settings.reauth_delete'))),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t('settings.delete_failed')}: ${e.message}')));
      }
    }
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(t('settings.sign_out'),
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(t('settings.sign_out_confirm'),
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('settings.cancel'), style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('settings.sign_out'),
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
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back_rounded, size: 24, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('settings.title'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
                    title: t('settings.edit_profile'),
                    subtitle: t('settings.edit_profile_subtitle'),
                    onTap: _editProfile,
                  ),
                  const SizedBox(height: 12),

                  // ── Notifications ─────────────────────────────────
                  _ToggleTile(
                    icon: Icons.notifications_outlined,
                    title: t('settings.notifications_title'),
                    subtitle: t('settings.notifications_subtitle'),
                    value: _notificationsOn,
                    onChanged: _setNotifications,
                  ),
                  const SizedBox(height: 12),

                  // ── App Theme ─────────────────────────────────────
                  _ToggleTile(
                    icon: Icons.dark_mode_outlined,
                    title: t('settings.theme_title'),
                    subtitle: t('settings.theme_subtitle'),
                    value: _darkModeOn,
                    onChanged: _setDarkMode,
                  ),
                  const SizedBox(height: 12),

                  // ── Language ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
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
                                Text(t('settings.language_title'),
                                    style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(t('settings.language_subtitle'),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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
                    title: t('settings.about_title'),
                    subtitle: t('settings.about_subtitle'),
                    onTap: () => _showInfoDialog(
                      t('settings.about_dialog_title'),
                      t('settings.about_dialog_body'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Help & Support ────────────────────────────────
                  _SettingsTile(
                    icon: Icons.support_rounded,
                    title: t('settings.help_title'),
                    subtitle: t('settings.help_subtitle'),
                    onTap: () => _showInfoDialog(
                      t('settings.help_dialog_title'),
                      t('settings.help_dialog_body'),
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
                        label: loggedIn ? t('settings.log_out') : t('settings.log_in'),
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
                              label: t('settings.delete_account'),
                              color: AppColors.textSecondary,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(subtitle,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
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
