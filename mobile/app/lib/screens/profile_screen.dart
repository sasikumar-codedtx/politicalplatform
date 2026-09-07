import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../services/profile_service.dart';
import '../services/agent_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/loading_overlay.dart';
import 'settings_screen.dart';
import 'polls_screen.dart';
import 'members_screen.dart';
import 'leader_screen.dart';
import 'complaints_screen.dart';
import 'phone_login_screen.dart';

const _kRed = Color(0xFF9F1D1F);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  int _complaintCount = 0;
  int _pollsCount = 0;
  final int _donationTotal = 0;
  bool _loading = false;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      ProfileService.load();
      _loadStats();
    }
    // Rebuild + (re)load whenever auth changes so the guest view and the real
    // profile swap correctly, and no previous user's numbers linger.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _complaintCount = 0;
          _pollsCount = 0;
          _loading = false;
        });
      } else {
        ProfileService.load();
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    if (mounted) setState(() => _loading = true);
    final complaints = await AgentService.getComplaints();
    final pollsParticipated = await AgentService.pollsParticipated();
    if (mounted) {
      setState(() {
        _complaintCount = complaints.length;
        _pollsCount = pollsParticipated;
        _loading = false;
      });
    }
  }

  Future<void> _login() async {
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
    // authStateChanges listener handles the reload; nothing else needed here.
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: _kRed),
              title: Text(t('profile.take_photo'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: _kRed),
              title: Text(t('profile.choose_from_gallery'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await _picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;
    await ProfileService.saveAvatar(File(picked.path));
  }

  Future<void> _editText({
    required String title,
    required String initial,
    required Future<bool> Function(String) onSave,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t('profile.cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(t('profile.save')),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final ok = await onSave(result);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('profile.save_failed'))),
        );
      }
    }
  }

  void _go(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final loggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: LoadingOverlay(
        isLoading: _loading,
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('profile.title'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _go(const SettingsScreen()),
                    child: Icon(Icons.settings_outlined, size: 24, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: loggedIn ? _buildProfile() : _GuestView(onLogin: _login),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileCard(
            onEditAvatar: _pickAvatar,
            onEditName: () => _editText(
              title: t('profile.your_name'),
              initial: ProfileService.displayName.value,
              onSave: ProfileService.saveName,
            ),
            onEditCity: () => _editText(
              title: t('profile.your_city'),
              initial: ProfileService.city.value,
              onSave: ProfileService.saveCity,
            ),
            pollsValue: _pollsCount.toString(),
            complaintsValue: _complaintCount.toString(),
            donationValue: '₹$_donationTotal',
            onTapStat: (tab) async {
              if (tab == 1) {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ComplaintsScreen()));
                _loadStats();
              } else {
                _go(PollsScreen(initialTab: tab));
              }
            },
            onJoin: () => _go(const MembersScreen()),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: t('profile.about_tvk')),
          const SizedBox(height: 12),
          _AboutTvkCard(onViewJourney: () => _go(const LeaderScreen())),
        ],
      ),
    );
  }
}

// ─── Guest (logged-out) view ────────────────────────────────────────────────

class _GuestView extends StatelessWidget {
  final VoidCallback onLogin;
  const _GuestView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline_rounded, size: 44, color: _kRed),
            ),
            const SizedBox(height: 20),
            Text(t('profile.sign_in_title'),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              t('profile.sign_in_subtitle'),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, height: 1.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t('profile.log_in'),
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final VoidCallback onEditAvatar;
  final VoidCallback onEditName;
  final VoidCallback onEditCity;
  final ValueChanged<int> onTapStat;
  final VoidCallback onJoin;
  final String pollsValue;
  final String complaintsValue;
  final String donationValue;
  const _ProfileCard({
    required this.onEditAvatar,
    required this.onEditName,
    required this.onEditCity,
    required this.onTapStat,
    required this.onJoin,
    required this.pollsValue,
    required this.complaintsValue,
    required this.donationValue,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onEditAvatar,
            child: Stack(
              children: [
                const ProfileAvatar(radius: 51),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.edit_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onEditName,
            child: ValueListenableBuilder<String>(
              valueListenable: ProfileService.displayName,
              builder: (_, name, _) => Text(
                name.trim().isEmpty ? t('profile.add_your_name') : name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: onEditCity,
            child: ValueListenableBuilder<String>(
              valueListenable: ProfileService.city,
              builder: (_, city, _) => Text(
                user?.phoneNumber?.isNotEmpty == true
                    ? user!.phoneNumber!
                    : (city.trim().isEmpty ? t('profile.add_your_city') : city),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatBox(value: pollsValue, label: t('profile.polls_participated'), icon: Icons.how_to_vote_outlined, onTap: () => onTapStat(0)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(value: complaintsValue, label: t('profile.complaints_submitted'), icon: Icons.assignment_outlined, onTap: () => onTapStat(1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(value: donationValue, label: t('profile.total_amount_donated'), icon: Icons.volunteer_activism_outlined, onTap: () => onTapStat(2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                t('profile.join_as_member'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _StatBox({required this.value, required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kRed),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kRed,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, height: 1.2, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── About TVK Card ───────────────────────────────────────────────────────────

class _AboutTvkCard extends StatelessWidget {
  final VoidCallback onViewJourney;
  const _AboutTvkCard({required this.onViewJourney});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 58,
              height: 58,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      Container(color: _kRed, child: const Icon(Icons.flag_rounded, color: Colors.white))),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'தமிழக வெற்றிக் கழகம்',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'பிறப்பொக்கும் எல்லா உயிர்க்கும் !',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: t('profile.founded_year'), value: '2023'),
          const SizedBox(height: 12),
          _InfoRow(label: t('profile.leader'), value: 'Mr. Vijay'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onViewJourney,
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                border: Border.all(color: _kRed),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                t('profile.view_journey'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _kRed,
                  letterSpacing: 0.32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: _kRed)),
      ],
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
