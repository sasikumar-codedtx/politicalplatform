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
import 'join_screen.dart';
import '../services/device_session.dart';

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
      // Centre button — chat/mic. STRICT login required (no skip path).
      _requireLoginMandatory(() async {
        // Fresh session keyed to the freshly logged-in user.
        await DeviceSession.rotate();
        if (!mounted) return;
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()));
      });
      return;
    }
    if (index == 4) {
      // Profile tab — requires login
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _requireLoginThen(() => setState(() => _selectedIndex = 4));
        return;
      }
    }
    setState(() => _selectedIndex = index);
  }

  /// Strict login — no skip. Used for chat / mic where unauthenticated
  /// access is not allowed at all. Bottom sheet shows only Login + Cancel.
  /// On successful login the [onSuccess] callback runs.
  void _requireLoginMandatory(Future<void> Function() onSuccess) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      onSuccess();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MandatoryLoginSheet(
        onLogin: () async {
          Navigator.pop(context);
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
          if (FirebaseAuth.instance.currentUser != null && mounted) {
            await onSuccess();
            _promptJoinTvk();
          }
        },
      ),
    );
  }

  /// Shows a login bottom sheet. If the user skips, calls [onSkip].
  /// If the user logs in, calls [onSuccess] and then prompts to join TVK.
  void _requireLoginThen(VoidCallback onSuccess) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      onSuccess();
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LoginGateSheet(
        onLogin: () async {
          Navigator.pop(context);
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
          // After login, prompt Join TVK
          if (FirebaseAuth.instance.currentUser != null && mounted) {
            onSuccess();
            _promptJoinTvk();
          }
        },
        onSkip: () {
          Navigator.pop(context);
          onSuccess();
        },
      ),
    );
  }

  void _promptJoinTvk() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _JoinTvkPromptSheet(
        onJoin: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const JoinScreen()));
        },
        onLater: () => Navigator.pop(context),
      ),
    );
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
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
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

// ─── Login gate bottom sheet ──────────────────────────────────────────────────

class _LoginGateSheet extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onSkip;
  const _LoginGateSheet({required this.onLogin, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: Color(0xFFE40101), size: 30),
          ),
          const SizedBox(height: 16),
          Text('Login to Continue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              )),
          const SizedBox(height: 8),
          Text(
            'Login with your mobile number to access\nthis feature. Or skip to browse.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onLogin,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE40101).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text('Login with Mobile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onSkip,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              alignment: Alignment.center,
              child: Text('Skip for Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF555555),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mandatory login sheet (chat / mic — no skip option) ─────────────────────

class _MandatoryLoginSheet extends StatelessWidget {
  final VoidCallback onLogin;
  const _MandatoryLoginSheet({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: Color(0xFFE40101), size: 32),
          ),
          const SizedBox(height: 16),
          Text('Login Required',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              )),
          const SizedBox(height: 8),
          Text(
            'Sign in with your mobile number to chat\nor talk with Vijay. Your messages are private.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onLogin,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE40101),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE40101).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text('Login with Mobile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF999999),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Join TVK prompt sheet (shown after login) ────────────────────────────────

class _JoinTvkPromptSheet extends StatelessWidget {
  final VoidCallback onJoin;
  final VoidCallback onLater;
  const _JoinTvkPromptSheet({required this.onJoin, required this.onLater});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // TVK yellow-red badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCA00), Color(0xFFE40101)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('ACTIVE MEMBER',
                style: GoogleFonts.bebasNeue(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 1.5,
                )),
          ),
          const SizedBox(height: 16),
          Text('Become a TVK Member',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              )),
          const SizedBox(height: 8),
          Text(
            'Get your official TVK member ID card,\naccess exclusive events, and more.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onJoin,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFCA00), Color(0xFFE40101)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE40101).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text('Join TVK Now',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onLater,
            child: Text('Maybe Later',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                )),
          ),
        ],
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
