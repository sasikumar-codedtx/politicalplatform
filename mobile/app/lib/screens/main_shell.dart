import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'fan_page_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'chat_list_screen.dart';
import 'phone_login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // 0=Home 1=Forum  [2=VoiceChat action]  3=News 4=MyTVK
  int _selectedIndex = 0;

  void _onNavTap(int index) {
    if (index == 2) {
      // Centre button — voice chat
      _openVoiceChat();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openVoiceChat() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
    } else {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ChatListScreen()));
    }
  }

  // Tab indices 0,1,3,4 → stack indices 0,1,2,3
  int get _stackIndex {
    if (_selectedIndex <= 1) return _selectedIndex;
    return _selectedIndex - 1; // 3→2, 4→3
  }

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _stackIndex,
        children: const [
          HomeScreen(),
          FanPageScreen(),
          NewsScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: f.appName,
                  index: 0,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: 'Forum',
                  index: 1,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
                // Centre — Talk to My Leader
                Expanded(
                  child: GestureDetector(
                    onTap: () => _onNavTap(2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(Icons.mic_rounded,
                              color: Colors.white, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.newspaper_outlined,
                  activeIcon: Icons.newspaper_rounded,
                  label: 'News',
                  index: 3,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
                _MyTvkNavItem(
                  index: 4,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Standard nav item ────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final Color primary;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primary : const Color(0xFF555555),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? primary : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My TVK tab — shows user avatar when logged in ───────────────────────────

class _MyTvkNavItem extends StatelessWidget {
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final Color primary;

  const _MyTvkNavItem({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final loggedIn =
                    snapshot.hasData && snapshot.data != null;
                if (loggedIn) {
                  return ClipOval(
                    child: Image.asset(
                      'assets/images/av2.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.person_rounded,
                        color: isActive
                            ? primary
                            : const Color(0xFF555555),
                        size: 22,
                      ),
                    ),
                  );
                }
                return Icon(
                  isActive
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color:
                      isActive ? primary : const Color(0xFF555555),
                  size: 22,
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              'My TVK',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color:
                    isActive ? primary : const Color(0xFF555555),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
