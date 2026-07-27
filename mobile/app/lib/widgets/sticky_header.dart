import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';

/// Shared sliver header pieces so every screen gets the same sticky behavior
/// (collapsing hero / pinned tabs / pinned simple bar) instead of each screen
/// hand-rolling its own.

/// Pins a [TabBar] below a collapsing hero (or at the top of a screen).
class PinnedTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color? background;
  const PinnedTabBar(this.tabBar, {this.background});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(color: background ?? AppColors.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(PinnedTabBar old) =>
      old.tabBar != tabBar || old.background != background;
}

/// A circular translucent back button used as the default hero leading.
class HeaderBackButton extends StatelessWidget {
  final Color background;
  final Color iconColor;
  const HeaderBackButton({
    super.key,
    this.background = const Color(0x73000000),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: iconColor, size: 16),
          ),
        ),
      ),
    );
  }
}

/// Collapsing hero app bar: expanded shows [background] + [title]; when
/// scrolled it shrinks to a compact pinned bar with the leading + title.
class SliverHeroBar extends StatelessWidget {
  final double expandedHeight;
  final Widget background;
  final Widget title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color backgroundColor;
  final EdgeInsetsGeometry titlePadding;
  final PreferredSizeWidget? bottom;

  const SliverHeroBar({
    super.key,
    required this.expandedHeight,
    required this.background,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor = const Color(0xFF1A0000),
    this.titlePadding = const EdgeInsets.only(left: 16, bottom: 14),
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      backgroundColor: backgroundColor,
      elevation: 0,
      leadingWidth: 60,
      automaticallyImplyLeading: false,
      leading: leading ?? const HeaderBackButton(),
      actions: actions,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: titlePadding,
        title: title,
        background: background,
      ),
    );
  }
}

/// Pinned compact app bar for screens with no hero (forms, lists).
class SliverSimpleBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  const SliverSimpleBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Text(title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          )),
      leading: leading,
      actions: actions,
      bottom: bottom,
    );
  }
}
