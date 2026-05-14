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

  static const _slides = [
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
    _SlideData(
      image: 'assets/images/onboard_4_tvk_collage.jpg',
      title: 'Tamilaga Vettri',
      subtitle: 'Kazhagam',
      description:
          'We want to use modern technologies in public welfare work, simplify political processes, and improve public service.',
      contentTop: 562.0,
    ),
  ];

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
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) => _OnboardSlide(
                data: _slides[index],
                activeIndex: _currentPage,
                totalSlides: _slides.length,
                onCta: widget.onDone,
              ),
            ),
            // Skip button — top-right, hidden on last page
            if (_currentPage < _slides.length - 1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: widget.onDone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// ── Slide data model ──────────────────────────────────────────────────────────

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

// ── Single slide ──────────────────────────────────────────────────────────────

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
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenW,
      height: screenH,
      child: Stack(
        children: [
          // 1. Background photo — full width, top 570px
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 570,
            child: Image.asset(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1A1A)),
            ),
          ),

          // 2. Top gradient (dark header overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 1.0],
                  colors: [Color(0x80000000), Colors.transparent],
                ),
              ),
            ),
          ),

          // 3. Bottom fade gradient (photo → black)
          Positioned(
            top: 352,
            left: 0,
            right: 0,
            height: 234,
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

          // 4. Black fill below photo
          Positioned(
            top: 570,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(color: Colors.black),
          ),

          // 5. Text content + dots + optional CTA
          Positioned(
            top: data.contentTop,
            left: 16,
            width: 358,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
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
                // Subtitle
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
                // Description
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
                // Dots
                _DotIndicator(activeIndex: activeIndex, total: totalSlides),
                if (data.hasCta) ...[
                  const SizedBox(height: 36),
                  // CTA button
                  GestureDetector(
                    onTap: onCta,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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

// ── Dot indicator ─────────────────────────────────────────────────────────────

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
