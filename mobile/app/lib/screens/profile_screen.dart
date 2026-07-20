import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../services/agent_service.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/loading_overlay.dart';
import 'settings_screen.dart';
import 'polls_screen.dart';
import 'members_screen.dart';
import 'leader_screen.dart';
import 'youtube_hub_screen.dart';
import 'complaints_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  int _complaintCount = 0;
  int _pollsCount = 0;
  int _donationTotal = 0;
  bool _loading = true;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    ProfileService.load();
    _loadStats();
    // Reset the stats when the user logs out so no previous user's numbers
    // linger in the (kept-alive) profile tab; reload when someone logs in.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        if (mounted) setState(() { _complaintCount = 0; _pollsCount = 0; _donationTotal = 0; _loading = false; });
      } else {
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
    if (FirebaseAuth.instance.currentUser == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    final complaints = await AgentService.getComplaints();
    if (mounted) setState(() { _complaintCount = complaints.length; _loading = false; });
    // Polls-participated and donation totals need their own backend counters
    // (not built yet); they stay 0 per user until those endpoints exist.
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF9F1D1F)),
              title: Text('Take a photo', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF9F1D1F)),
              title: Text('Choose from gallery', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
        title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final ok = await onSave(result);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save — check your connection and login.')),
        );
      }
    }
  }

  void _openLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final lang in ['English', 'தமிழ் (Tamil)', 'हिंदी (Hindi)'])
              ListTile(
                leading: const Icon(Icons.translate_rounded, color: Color(0xFF9F1D1F)),
                title: Text(lang, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language set to $lang')),
                  );
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _go(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Column(
        children: [
          // ── App Bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _go(const SettingsScreen()),
                  child: const Icon(Icons.settings_outlined, size: 24, color: Colors.black),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _openLanguageSheet,
                  child: const Icon(Icons.translate_rounded, size: 24, color: Colors.black),
                ),
              ],
            ),
          ),
          // ── Scrollable body ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileCard(
                    onEditAvatar: _pickAvatar,
                    onEditName: () => _editText(
                      title: 'Your name',
                      initial: ProfileService.displayName.value,
                      onSave: ProfileService.saveName,
                    ),
                    onEditCity: () => _editText(
                      title: 'Your city',
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

                  _SectionTitle(title: "Your Area's Political Pulse"),
                  const SizedBox(height: 12),
                  const _AreaPulseCard(),
                  const SizedBox(height: 20),

                  _SectionTitle(title: 'Your Local TVK Members'),
                  const SizedBox(height: 12),
                  _MemberCard(
                    name: 'Mr. Ramesh',
                    role: 'Youth Wing Coordinator',
                    ward: 'Ward -14',
                    activeSince: '2024',
                    lastMeet: 'Last Meet 04- Jun 2025',
                    imagePath: 'assets/images/leader_vijay.png',
                    onViewSpeech: () => _go(const YoutubeHubScreen()),
                  ),
                  const SizedBox(height: 12),
                  _MemberCard(
                    name: 'Ms. Kavitha',
                    role: 'Ward In-Charge',
                    ward: 'Ward -14',
                    activeSince: '2024',
                    lastMeet: 'Last Meet 24- Jun 2025',
                    imagePath: 'assets/images/leader_anand.png',
                    onViewSpeech: () => _go(const YoutubeHubScreen()),
                  ),
                  const SizedBox(height: 20),

                  _SectionTitle(title: 'About TVK'),
                  const SizedBox(height: 12),
                  _AboutTvkCard(onViewJourney: () => _go(const LeaderScreen())),
                ],
              ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          Column(
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 6, offset: const Offset(0, 2))],
                        ),
                        child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF4A4949)),
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
                    name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111111),
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
                    user?.phoneNumber?.isNotEmpty == true ? user!.phoneNumber! : city,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4A4949),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(label: 'Volunteer since 2024', color: const Color(0xFF4CAE4F)),
              _StatusPill(
                label: 'Earned 20 TVK Badges',
                color: const Color(0xFF093492),
                icon: Icons.verified_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatBox(value: pollsValue, label: 'Polls\nparticipated', onTap: () => onTapStat(0)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(value: complaintsValue, label: 'Complaints\nsubmitted', onTap: () => onTapStat(1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(value: donationValue, label: 'Total Amount\nDonated', onTap: () => onTapStat(2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF9F1D1F),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'Join as member',
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

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _StatusPill({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;
  const _StatBox({required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 93),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF9F1D1F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Area Pulse Card ──────────────────────────────────────────────────────────

class _AreaPulseCard extends StatelessWidget {
  const _AreaPulseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chennai- Ward 42',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF09416D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.manage_accounts_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  '12 Issues resolved this month',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, size: 36, color: Color(0xFF09416D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('03', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF09416D))),
                            Text('Events\nconducted', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF09416D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_vote_rounded, size: 36, color: Color(0xFF09416D)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1,148', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF09416D))),
                            Text('Polls turnout\nvotes in May', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF09416D))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  final String name;
  final String role;
  final String ward;
  final String activeSince;
  final String lastMeet;
  final String imagePath;
  final VoidCallback onViewSpeech;

  const _MemberCard({
    required this.name,
    required this.role,
    required this.ward,
    required this.activeSince,
    required this.lastMeet,
    required this.imagePath,
    required this.onViewSpeech,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(imagePath, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: const Color(0xFFEEEEEE), child: const Icon(Icons.person_rounded, color: Color(0xFF9F1D1F)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    Text(role, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBECFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ward,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3B42C3)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF9F1D1F)),
              const SizedBox(width: 6),
              Text('Active since : $activeSince',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFE68E0C)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(lastMeet,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFE68E0C))),
              ),
              GestureDetector(
                onTap: onViewSpeech,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9D8D8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_rounded, size: 16, color: Color(0xFF9F1D1F)),
                      const SizedBox(width: 4),
                      Text('View Speech',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF9F1D1F))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(4, 4))],
      ),
      child: Column(
        children: [
          Column(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          Container(color: const Color(0xFF9F1D1F), child: const Icon(Icons.flag_rounded, color: Colors.white))),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'தமிழக வெற்றிக் கழகம்',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111111)),
              ),
              const SizedBox(height: 2),
              Text(
                'பிறப்பொக்கும் எல்லா உயிர்க்கும் !',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF4A4949)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Founded Year', value: '2023'),
          const SizedBox(height: 12),
          _InfoRow(label: 'Leader', value: 'Mr.Vijay'),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onViewJourney,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF9F1D1F)),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                'View Journey & Milestones',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9F1D1F),
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
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF111111))),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF9F1D1F))),
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
        color: Colors.black,
      ),
    );
  }
}
