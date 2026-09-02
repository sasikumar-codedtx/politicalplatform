import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../models/news_item.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsItem item;
  const NewsDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // ── iOS-style navigation bar with back button ────────────────
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          item.category,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image (no back button — AppBar handles it)
            _Hero(item: item, topPad: 0),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + date row
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE40101).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE40101),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(item.date, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 10),
                      Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(item.time, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    item.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Summary (lead paragraph)
                  Text(
                    item.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 20),
                  // Article body
                  ..._bodyParagraphs(item).map((para) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      para,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  // Share row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.ios_share_rounded, color: AppColors.textPrimary, size: 20),
                        const SizedBox(width: 10),
                        Text(t('news_detail.share_this_article'), style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        const Spacer(),
                        _ActionIcon(icon: Icons.thumb_up_outlined),
                        const SizedBox(width: 16),
                        _ActionIcon(icon: Icons.bookmark_border_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _bodyParagraphs(NewsItem item) => [
    '${t('news_detail.body_p1')} ${item.summary}',
    t('news_detail.body_p2'),
    t('news_detail.body_p3'),
    t('news_detail.body_p4'),
    t('news_detail.body_p5'),
  ];
}

class _Hero extends StatelessWidget {
  final NewsItem item;
  final double topPad;
  const _Hero({required this.item, required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 260 + topPad,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset('assets/images/event_1.png', fit: BoxFit.cover),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 16 + topPad,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          // Share button
          Positioned(
            top: 16 + topPad,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  const _ActionIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: AppColors.textSecondary, size: 20);
  }
}
