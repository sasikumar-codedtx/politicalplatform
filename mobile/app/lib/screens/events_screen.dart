import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../widgets/sticky_header.dart';
import '../models/event.dart';
import '../services/content_service.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<PartyEvent> _events = [];
  bool _loading = true;

  static const _eventImages = [
    'assets/images/event_1.png',
    'assets/images/event_2.png',
    'assets/images/event_3.png',
    'assets/images/event_4.png',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final events = await ContentService.getEvents();
    if (mounted) setState(() { _events = events; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.bg,
      // Sticky/collapsing header: the flag hero collapses under a pinned bar
      // (back + title stay visible) while the event list scrolls — same
      // sliver pattern as News/Forum.
      body: CustomScrollView(
        slivers: [
          SliverHeroBar(
            expandedHeight: 216 + topPad,
            background: const _EventsHeroBg(),
            title: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE40101), Color(0xFF7E0101)],
              ).createShader(bounds),
              child: Text(t('events.title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.bebasNeue(
                    fontSize: LocaleController.isTamil ? 20 : 26, color: Colors.white, letterSpacing: 0.2)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: EdgeInsets.only(bottom: i < _events.length - 1 ? 16 : 0),
                  child: _EventCard(
                    event: _events[i],
                    imagePath: _eventImages[i % _eventImages.length],
                  ),
                ),
                childCount: _events.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Flag hero background for the collapsing app bar.
class _EventsHeroBg extends StatelessWidget {
  const _EventsHeroBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.4, 1.0],
              colors: [Colors.transparent, Colors.transparent, Colors.black],
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final PartyEvent event;
  final String imagePath;
  const _EventCard({required this.event, required this.imagePath});

  String _month(String date) => date.split(' ').first;

  String _day(String date) {
    final parts = date.split(' ');
    return parts.length > 1 ? parts[1].replaceAll(',', '') : '';
  }

  String _weekday(String date) {
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
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
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event, imagePath: imagePath))),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 168,
        child: Stack(
          children: [
            // Background image — admin-published image when present, else the
            // bundled asset fallback.
            Positioned.fill(
              child: event.imageUrl != null
                  ? Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => Image.asset(imagePath, fit: BoxFit.cover),
                    )
                  : Image.asset(imagePath, fit: BoxFit.cover),
            ),
            // Gradient overlay: transparent maroon → #a23435
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00A23435), Color(0xFFA23435)],
                  ),
                ),
              ),
            ),
            // Content: date box + info anchored to the card bottom
            Positioned(
              left: 16,
              bottom: 12,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateBox(
                    month: _month(event.date),
                    day: _day(event.date),
                    weekday: _weekday(event.date),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
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
          ],
        ),
      ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String month;
  final String day;
  final String weekday;

  const _DateBox({required this.month, required this.day, required this.weekday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 41,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Red month header
          Container(
            width: 41,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0xFFA23435),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              month,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Day number
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                Text(
                  weekday,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
