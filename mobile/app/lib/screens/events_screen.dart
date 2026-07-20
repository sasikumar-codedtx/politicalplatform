import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE40101))),
      );
    }

    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(topPad: topPad),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: List.generate(_events.length, (i) => Padding(
                  padding: EdgeInsets.only(bottom: i < _events.length - 1 ? 16 : 0),
                  child: _EventCard(
                    event: _events[i],
                    imagePath: _eventImages[i % _eventImages.length],
                  ),
                )),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 234 + topPad,
      child: Stack(
        children: [
          // TVK flag image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/tvk_flag.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: transparent at top → black at bottom
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
            top: topPad + 14,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          // Title + location row at bottom
          Positioned(
            bottom: 0,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                    ).createShader(bounds),
                    child: Text(
                      'Nearby Events',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 34,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Tirupur',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 16),
                    ],
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
            // Background image
            Positioned.fill(
              child: Image.asset(imagePath, fit: BoxFit.cover),
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
        color: Colors.white,
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
                    color: Colors.black87,
                    height: 1,
                  ),
                ),
                Text(
                  weekday,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.3),
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
