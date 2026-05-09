import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../models/event.dart';
import '../viewmodels/events_viewmodel.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventsViewModel()..load(),
      child: const _EventsView(),
    );
  }
}

class _EventsView extends StatelessWidget {
  const _EventsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventsViewModel>();
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            floating: true,
            snap: true,
            pinned: true,
            elevation: 0,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: _TvkBanner(
                title: "NEARBY EVENTS",
                subtitle: 'RALLIES, MEETINGS & PROGRAMMES FROM TVK.\nBE THERE. BE HEARD.',
                primary: primary,
              ),
              collapseMode: CollapseMode.pin,
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: bg,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(f.surfaceColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.location_on_outlined, color: Color(0xFF666666), size: 16),
                            const SizedBox(width: 6),
                            Text('Chennai, Tamil Nadu', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF666666), size: 20),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(f.surfaceColor),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: border),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF888888), size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : vm.events.isEmpty
                ? Center(child: Text('No events scheduled', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: vm.events.length,
                    itemBuilder: (context, index) {
                      final event = vm.events[index];
                      return _EventCard(event: event, primary: primary, border: border);
                    },
                  ),
      ),
    );
  }
}

class _TvkBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color primary;
  const _TvkBanner({required this.title, required this.subtitle, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC49A00), Color(0xFF7D1400)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.event_rounded, color: Colors.white, size: 34),
              ),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: primary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final PartyEvent event;
  final Color primary;
  final Color border;

  const _EventCard({required this.event, required this.primary, required this.border});

  String _monthAbbr(String date) {
    final parts = date.split(' ');
    return parts.isNotEmpty ? parts[0].toUpperCase().substring(0, 3) : '';
  }

  String _day(String date) {
    final parts = date.split(' ');
    return parts.length > 1 ? parts[1].replaceAll(',', '') : '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-bleed image area
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                // Background gradient (placeholder for actual image)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primary.withValues(alpha: 0.6),
                        const Color(0xFF0A0A0A),
                      ],
                    ),
                  ),
                ),
                // Event type badge top-right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.type.toUpperCase(),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                    ),
                  ),
                ),
                // Bottom overlay: date box + title + location
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // White date box
                        Container(
                          width: 44,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _monthAbbr(event.date),
                                style: GoogleFonts.inter(color: primary, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                              Text(
                                _day(event.date),
                                style: GoogleFonts.inter(color: const Color(0xFF111111), fontSize: 20, fontWeight: FontWeight.w900, height: 1.1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                event.title,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.25),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 11),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom detail row
          Container(
            color: const Color(0xFF1E1E1E),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF666666), size: 13),
                const SizedBox(width: 4),
                Text(event.time, style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 12)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.description,
                    style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 11, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('RSVP', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
