import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1A1A1A),
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 1,
            titleSpacing: 20,
            automaticallyImplyLeading: false,
            title: Text('Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18, color: const Color(0xFF1A1A1A))),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF666666)),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Sign Out', style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700)),
                      content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(color: const Color(0xFF666666))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF666666)))),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Sign Out', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  );
                  if (confirmed == true) await FirebaseAuth.instance.signOut();
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(color: border, height: 1),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Member card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary.withValues(alpha: 0.1),
                          border: Border.all(color: primary.withValues(alpha: 0.25), width: 2),
                        ),
                        child: Icon(Icons.person_rounded, color: primary, size: 34),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Member', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                            const SizedBox(height: 3),
                            Text(user?.phoneNumber ?? '', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF666666))),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text('Verified', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: primary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // KYC banner
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFFF8F00), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Complete your KYC', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                            Text('Add name, constituency, and ID to unlock all features.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF666666), height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFF8F00), borderRadius: BorderRadius.circular(8)),
                        child: Text('Start', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                _Section(
                  title: 'MY ACCOUNT',
                  surface: surface,
                  border: border,
                  tiles: [
                    _Tile(icon: Icons.person_outline_rounded, title: 'Personal Information', subtitle: 'Name, constituency, district', primary: primary, surface: surface),
                    _Tile(icon: Icons.badge_outlined, title: 'Voter ID / Aadhaar', subtitle: 'KYC verification', primary: primary, surface: surface, badge: 'SOON'),
                    _Tile(icon: Icons.history_rounded, title: 'Chat History', subtitle: 'View all past conversations', primary: primary, surface: surface),
                  ],
                ),
                _Section(
                  title: 'PREFERENCES',
                  surface: surface,
                  border: border,
                  tiles: [
                    _Tile(icon: Icons.language_rounded, title: 'Language', subtitle: 'English (Tamil coming soon)', primary: primary, surface: surface, badge: 'SOON'),
                    _Tile(icon: Icons.notifications_outlined, title: 'Notifications', subtitle: 'Manage push notifications', primary: primary, surface: surface),
                  ],
                ),
                _Section(
                  title: 'ABOUT',
                  surface: surface,
                  border: border,
                  tiles: [
                    _Tile(icon: Icons.info_outline_rounded, title: 'About ${f.appName}', subtitle: f.partyName, primary: primary, surface: surface),
                    _Tile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: 'How we handle your data', primary: primary, surface: surface),
                    _Tile(icon: Icons.gavel_rounded, title: 'Terms of Service', subtitle: 'Usage terms and conditions', primary: primary, surface: surface),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color surface;
  final Color border;
  final List<_Tile> tiles;

  const _Section({required this.title, required this.surface, required this.border, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: const Color(0xFF999999))),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            children: tiles.asMap().entries.map((e) {
              final isLast = e.key == tiles.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) Divider(color: border, height: 1, indent: 52),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color surface;
  final String? badge;

  const _Tile({required this.icon, required this.title, required this.subtitle, required this.primary, required this.surface, this.badge});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: primary, size: 17),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF999999))),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(6)),
              child: Text(badge!, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF888888), fontWeight: FontWeight.w600)),
            )
          : const Icon(Icons.chevron_right_rounded, color: Color(0xFFCCCCCC), size: 18),
      onTap: badge == null ? () {} : null,
    );
  }
}
