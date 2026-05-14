import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Slides 1-3 use the generic photo layout; slide 0 is the TVK collage
  static const _photoSlides = [
    _SlideData(
      image: 'assets/images/onboard_1_social_justice.jpg',
      title: 'Social',
      subtitle: 'Justice',
      description:
          'We promote social justice principles to ensure equality for all social groups and to create equal opportunities for all without discrimination.',
      contentTop: 576.0,
    ),
    _SlideData(
      image: 'assets/images/onboard_2_technology.jpg',
      title: 'Technological',
      subtitle: 'development',
      description:
          'We want to use modern technologies in public welfare work, simplify political processes, and improve public service.',
      contentTop: 576.0,
    ),
    _SlideData(
      image: 'assets/images/onboard_3_opportunity.jpg',
      title: 'Opportunity',
      subtitle: 'for the younger generation',
      description:
          'We want to use modern technologies in public welfare work, simplify political processes, and improve public service.',
      contentTop: 488.0,
      hasCta: true,
    ),
  ];

  static const _totalSlides = 4; // 1 TVK collage + 3 photo slides

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _totalSlides,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _TvkCollageSlide(
                    activeIndex: _currentPage,
                    totalSlides: _totalSlides,
                  );
                }
                return _OnboardSlide(
                  data: _photoSlides[index - 1],
                  activeIndex: _currentPage,
                  totalSlides: _totalSlides,
                  onCta: widget.onDone,
                );
              },
            ),
            // Skip — hidden on last slide (index 3)
            if (_currentPage < _totalSlides - 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: widget.onDone,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Slide 0: TVK Collage ─────────────────────────────────────────────────────
// Blurred TVK flag background + all 6 leader portraits + Vijay centre-top

class _TvkCollageSlide extends StatelessWidget {
  final int activeIndex;
  final int totalSlides;

  const _TvkCollageSlide({
    required this.activeIndex,
    required this.totalSlides,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SizedBox(
      width: sw,
      height: sh,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Black base
          Container(color: Colors.black),

          // ── Blurred, rotated TVK flag (bg)
          Positioned(
            left: sw / 2 - 337.5 - 12,
            top: -140,
            width: 675,
            height: 619,
            child: Transform.rotate(
              angle: -0.349, // -20° in radians
              child: Opacity(
                opacity: 0.55,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Image.asset(
                    'assets/images/tvk_flag.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          // ── Vijay (white shirt, top-centre)
          Positioned(
            left: 30,
            top: 30,
            width: 360,
            height: 365,
            child: Image.asset(
              'assets/images/vijay_home_hero.png',
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Velu Nachiyar
          Positioned(
            left: 0,
            top: 220,
            width: 270,
            height: 285,
            child: Image.asset(
              'assets/images/leader_velunachiyar.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Anjalai Ammal
          Positioned(
            left: 155,
            top: 250,
            width: 285,
            height: 215,
            child: Image.asset(
              'assets/images/leader_anjalai.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Periyar
          Positioned(
            left: -15,
            top: 300,
            width: 225,
            height: 200,
            child: Image.asset(
              'assets/images/leader_periyar.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomLeft,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Kamarajar
          Positioned(
            left: 215,
            top: 298,
            width: 270,
            height: 210,
            child: Image.asset(
              'assets/images/leader_kamarajar.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Ambedkar
          Positioned(
            left: 90,
            top: 272,
            width: 260,
            height: 265,
            child: Image.asset(
              'assets/images/leader_ambedkar.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            ),
          ),

          // ── Bottom fade: collage → black
          Positioned(
            top: 352,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.18, 1.0],
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Black fill below collage
          Positioned(
            top: 562,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(color: Colors.black),
          ),

          // ── Text + dots  (Figma top:562)
          Positioned(
            top: 562,
            left: 16,
            width: sw - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tamilaga Vettri Kazhagam',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We want to use modern technologies in public welfare work, simplify political processes, and improve public service.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 23 / 16,
                  ),
                ),
                const SizedBox(height: 24),
                _DotIndicator(activeIndex: activeIndex, total: totalSlides),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide data model ─────────────────────────────────────────────────────────

class _SlideData {
  final String image;
  final String title;
  final String subtitle;
  final String description;
  final double contentTop;
  final bool hasCta;

  const _SlideData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.contentTop,
    this.hasCta = false,
  });
}

// ─── Generic photo slide (slides 1-3) ────────────────────────────────────────

class _OnboardSlide extends StatelessWidget {
  final _SlideData data;
  final int activeIndex;
  final int totalSlides;
  final VoidCallback onCta;

  const _OnboardSlide({
    required this.data,
    required this.activeIndex,
    required this.totalSlides,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return SizedBox(
      width: sw,
      height: sh,
      child: Stack(
        children: [
          // Photo
          Positioned(
            top: 0, left: 0, right: 0, height: 570,
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  Container(color: const Color(0xFF1A1A1A)),
            ),
          ),
          // Top dark vignette
          Positioned(
            top: 0, left: 0, right: 0, height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x80000000), Colors.transparent],
                ),
              ),
            ),
          ),
          // Bottom fade
          Positioned(
            top: 352, left: 0, right: 0, height: 234,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.182, 1.0],
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),
          // Black fill
          Positioned(
            top: 570, left: 0, right: 0, bottom: 0,
            child: Container(color: Colors.black),
          ),
          // Content
          Positioned(
            top: data.contentTop,
            left: 16,
            width: sw - 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 23 / 16,
                  ),
                ),
                const SizedBox(height: 24),
                _DotIndicator(activeIndex: activeIndex, total: totalSlides),
                if (data.hasCta) ...[
                  const SizedBox(height: 36),
                  GestureDetector(
                    onTap: onCta,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Bright Future Starts Here !',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dot indicator ────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int activeIndex;
  final int total;

  const _DotIndicator({required this.activeIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == activeIndex;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: isActive ? 26 : 15,
            height: 5,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
