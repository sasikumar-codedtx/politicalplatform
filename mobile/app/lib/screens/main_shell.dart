import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import 'home_screen.dart';
import 'fan_page_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import '../models/chat_session.dart';
import 'phone_login_screen.dart';
import 'join_screen.dart';
import '../services/device_session.dart';
import '../services/profile_service.dart';
import 'dart:async';
import 'dart:io';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  // 0=Home 1=Forum  [2=VoiceChat action]  3=News 4=MyTVK
  int _selectedIndex = 0;
  StreamSubscription<User?>? _authSub;

  // Hide the top status bar (clock/wifi/battery/sim/notifications) while inside
  // the app; keep the bottom nav gestures.
  void _hideStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: [SystemUiOverlay.bottom]);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-hide after resume (some OS transitions restore the bars).
    if (state == AppLifecycleState.resumed) _hideStatusBar();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hideStatusBar();
    ProfileService.load(); // so the My TVK icon shows the saved photo on launch
    // On logout, leave the (gated) profile tab and return to Home.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && mounted && _selectedIndex == 4) {
        setState(() => _selectedIndex = 0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) {
      // Centre AI button — opens the assistant chat DIRECTLY (no history list
      // first; past chats live in the chat screen's drawer). STRICT login.
      _requireLoginMandatory(() async {
        final sid = await DeviceSession.sessionId();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              session: ChatSession(
                id: sid,
                title: t('main_shell.ask_ai'),
                createdAt: DateTime.now(),
                lastMessage: '',
              ),
            ),
          ),
        );
      });
      return;
    }
    if (index == 4) {
      // My TVK — login is mandatory (no Skip). If declined, stay put.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _requireLoginMandatory(() async => setState(() => _selectedIndex = 4));
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
      backgroundColor: AppColors.surface,
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


  void _promptJoinTvk() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
    final bg = AppColors.bg;
    final border = AppColors.border;

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
                  label: t('main_shell.nav_home'),
                  index: 0,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
                _NavItem(
                  icon: Icons.people_outline_rounded,
                  activeIcon: Icons.people_rounded,
                  label: t('main_shell.nav_forum'),
                  index: 1,
                  selected: _selectedIndex,
                  onTap: _onNavTap,
                  primary: primary,
                ),
                // Center AI assistant — prominent, login-gated (via _onNavTap(2)).
                _AiCenterButton(primary: primary, onTap: () => _onNavTap(2)),
                _NavItem(
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign_rounded,
                  label: t('main_shell.nav_news'),
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

// ─── Center AI assistant button ───────────────────────────────────────────────

class _AiCenterButton extends StatelessWidget {
  final Color primary;
  final VoidCallback onTap;
  const _AiCenterButton({required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, Color.lerp(primary, Colors.black, 0.30)!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.40),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              t('main_shell.nav_ai'),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
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
              color: isActive ? primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared bottom-sheet pieces ──────────────────────────────────────────────

Widget _sheetHandle() {
  return Container(
    width: 40, height: 4,
    decoration: BoxDecoration(
      color: AppColors.border,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

Widget _sheetLoginButton(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
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
      child: Text(t('main_shell.login_with_mobile'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          )),
    ),
  );
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
          _sheetHandle(),
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
          Text(t('main_shell.login_required'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            t('main_shell.login_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _sheetLoginButton(onLogin),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text(t('main_shell.cancel'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
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
          _sheetHandle(),
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
            child: Text(t('main_shell.active_member'),
                style: GoogleFonts.bebasNeue(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 1.5,
                )),
          ),
          const SizedBox(height: 16),
          Text(t('main_shell.become_member_title'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 8),
          Text(
            t('main_shell.become_member_subtitle'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
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
              child: Text(t('main_shell.join_now'),
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
            child: Text(t('main_shell.maybe_later'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
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
            ValueListenableBuilder<String?>(
              valueListenable: ProfileService.avatar,
              builder: (context, path, _) {
                if (path != null) {
                  return ClipOval(
                    child: Image.file(
                      File(path),
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.person_rounded,
                        color: isActive ? primary : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  );
                }
                return Icon(
                  isActive
                      ? Icons.person_rounded
                      : Icons.person_outline_rounded,
                  color: isActive ? primary : AppColors.textSecondary,
                  size: 22,
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              t('main_shell.nav_my_tvk'),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
                color:
                    isActive ? primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
