import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'events_screen.dart';
import 'community_screen.dart';
import 'join_screen.dart';
import 'shorts_screen.dart';
import 'polls_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _fabOpen = false;
  late final AnimationController _fabController;
  late final Animation<double> _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fabAnim = CurvedAnimation(parent: _fabController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    _fabOpen ? _fabController.forward() : _fabController.reverse();
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() => _fabOpen = false);
      _fabController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Main content — 4 tabs
          IndexedStack(
            index: _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex,
            children: const [
              HomeScreen(),
              CommunityScreen(),
              NewsScreen(),
              EventsScreen(),
            ],
          ),
          // Dim overlay when FAB open
          if (_fabOpen)
            GestureDetector(
              onTap: _closeFab,
              child: Container(color: Colors.black.withValues(alpha: 0.65)),
            ),
          // FAB menu
          if (_fabOpen)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fabAnim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(_fabAnim),
                  child: _FabMenu(primary: primary, onClose: _closeFab),
                ),
              ),
            ),
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
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: f.appName, index: 0, selected: _selectedIndex, onTap: (i) { _closeFab(); setState(() => _selectedIndex = i); }, primary: primary),
                _NavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Forum', index: 1, selected: _selectedIndex, onTap: (i) { _closeFab(); setState(() => _selectedIndex = i); }, primary: primary),
                // Center FAB
                Expanded(
                  child: GestureDetector(
                    onTap: _toggleFab,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
                          ),
                          child: AnimatedRotation(
                            turns: _fabOpen ? 0.125 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: const Icon(Icons.add, color: Colors.white, size: 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _NavItem(icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper_rounded, label: 'News', index: 3, selected: _selectedIndex, onTap: (i) { _closeFab(); setState(() => _selectedIndex = i); }, primary: primary),
                _NavItem(icon: Icons.event_outlined, activeIcon: Icons.event_rounded, label: 'Events', index: 4, selected: _selectedIndex, onTap: (i) { _closeFab(); setState(() => _selectedIndex = i); }, primary: primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FabMenu extends StatelessWidget {
  final Color primary;
  final VoidCallback onClose;

  const _FabMenu({required this.primary, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final items = [
      (Icons.card_membership_rounded, f.joinCtaLabel, () { onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinScreen())); }),
      (Icons.edit_outlined, 'Post', () { onClose(); }),
      (Icons.how_to_vote_outlined, 'Poll', () { onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const PollsScreen())); }),
      (Icons.play_circle_outline_rounded, 'Shorts', () { onClose(); Navigator.push(context, MaterialPageRoute(builder: (_) => const ShortsScreen())); }),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...items.reversed.map((item) => GestureDetector(
          onTap: item.$3,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 120),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$1, color: primary, size: 18),
                const SizedBox(width: 10),
                Text(item.$2, style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        )),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final Color primary;

  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.selected, required this.onTap, required this.primary});

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
            Icon(isActive ? activeIcon : icon, color: isActive ? primary : const Color(0xFF555555), size: 22),
            const SizedBox(height: 3),
            Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? primary : const Color(0xFF555555))),
          ],
        ),
      ),
    );
  }
}
