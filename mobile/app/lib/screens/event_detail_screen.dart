import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../models/event.dart';

class EventDetailScreen extends StatefulWidget {
  final PartyEvent event;
  final String imagePath;
  const EventDetailScreen({super.key, required this.event, required this.imagePath});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _rsvped = false;

  String _month(String date) => date.split(' ').first;
  String _day(String date) {
    final parts = date.split(' ');
    return parts.length > 1 ? parts[1].replaceAll(',', '') : '';
  }
  String _weekday(String date) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final parts = date.split(' ');
    if (parts.length < 3) return '';
    final m = months[parts[0]] ?? 1;
    final d = int.tryParse(parts[1].replaceAll(',', '')) ?? 1;
    final y = int.tryParse(parts[2]) ?? 2026;
    return days[DateTime(y, m, d).weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final event = widget.event;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  _HeroImage(imagePath: widget.imagePath, topPad: topPad, event: event),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event type badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA23435).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.type.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFA23435)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          event.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.4, letterSpacing: 0.2),
                        ),
                        const SizedBox(height: 20),
                        // Date + time + location cards
                        Row(
                          children: [
                            _InfoCard(
                              icon: Icons.calendar_today_outlined,
                              label: t('event_detail.date'),
                              value: '${_weekday(event.date)}, ${_month(event.date)} ${_day(event.date)}',
                            ),
                            const SizedBox(width: 12),
                            _InfoCard(
                              icon: Icons.access_time_rounded,
                              label: t('event_detail.time'),
                              value: event.time,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Location card full width
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
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
                              const Icon(Icons.location_on_outlined, color: Color(0xFFE40101), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t('event_detail.location'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(
                                      event.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(t('event_detail.view_map'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textPrimary)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // About
                        Text(t('event_detail.about_this_event'), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 10),
                        Text(
                          event.description,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary, height: 1.7),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t('event_detail.attendance_note'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textSecondary, height: 1.7),
                        ),
                        const SizedBox(height: 20),
                        // What to expect
                        Text(t('event_detail.what_to_expect'), style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        ...[
                          t('event_detail.expect_opening_address'),
                          t('event_detail.expect_policy_discussions'),
                          t('event_detail.expect_qa_session'),
                          t('event_detail.expect_networking'),
                          t('event_detail.expect_cultural_programme'),
                        ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 7),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Color(0xFFE40101), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 24),
                        // Attendees count
                        Container(
                          padding: const EdgeInsets.all(14),
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
                              Icon(Icons.people_outline_rounded, color: AppColors.textPrimary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(t('event_detail.people_attending'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary)),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.ios_share_rounded, color: AppColors.textSecondary, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom RSVP button
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + MediaQuery.of(context).padding.bottom, top: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: GestureDetector(
              onTap: () => setState(() => _rsvped = !_rsvped),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _rsvped ? Colors.transparent : const Color(0xFFE40101),
                  borderRadius: BorderRadius.circular(10),
                  border: _rsvped ? Border.all(color: const Color(0xFFE40101), width: 1) : null,
                ),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_rsvped ? Icons.check_circle_outline_rounded : Icons.how_to_vote_outlined, color: _rsvped ? const Color(0xFFE40101) : Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _rsvped ? t('event_detail.attending') : t('event_detail.rsvp_attend'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: LocaleController.isTamil ? 13 : 16,
                              fontWeight: FontWeight.w600,
                              color: _rsvped ? const Color(0xFFE40101) : Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imagePath;
  final double topPad;
  final PartyEvent event;
  const _HeroImage({required this.imagePath, required this.topPad, required this.event});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280 + topPad,
      child: Stack(
        children: [
          Positioned.fill(
            child: event.imageUrl != null
                ? Image.network(
                    event.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, e, s) => Image.asset(imagePath, fit: BoxFit.cover),
                  )
                : Image.asset(imagePath, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [Colors.transparent, Colors.transparent, Colors.black],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16 + topPad,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            top: 16 + topPad,
            right: 16,
            child: Container(
              width: 40, height: 40,
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

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
            Icon(icon, color: const Color(0xFFE40101), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
