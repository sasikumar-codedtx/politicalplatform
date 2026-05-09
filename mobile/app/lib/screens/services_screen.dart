import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const List<_ServiceCategory> _categories = [
    _ServiceCategory(
      title: 'Vehicle Services',
      icon: Icons.directions_car_outlined,
      color: Color(0xFF19AAED),
      services: [
        _Service(icon: Icons.search_rounded, title: 'Vahan — Vehicle Lookup', subtitle: 'Check registration, RC details, tax', badge: 'LIVE'),
        _Service(icon: Icons.credit_card_outlined, title: 'Sarathi — Driving Licence', subtitle: 'Check DL validity and details', badge: 'LIVE'),
        _Service(icon: Icons.receipt_long_outlined, title: 'Road Tax Payment', subtitle: 'Pay road tax online', badge: 'SOON'),
      ],
    ),
    _ServiceCategory(
      title: 'Social Schemes',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF138808),
      services: [
        _Service(icon: Icons.people_outline_rounded, title: 'Scheme Eligibility Check', subtitle: 'Find schemes you qualify for', badge: 'SOON'),
        _Service(icon: Icons.receipt_outlined, title: 'Ration Card Services', subtitle: 'Check PDS status and ration card', badge: 'SOON'),
        _Service(icon: Icons.health_and_safety_outlined, title: 'Ayushman Bharat', subtitle: 'Check health cover eligibility', badge: 'SOON'),
      ],
    ),
    _ServiceCategory(
      title: 'Civic Services',
      icon: Icons.location_city_outlined,
      color: Color(0xFF9C27B0),
      services: [
        _Service(icon: Icons.how_to_vote_outlined, title: 'Voter ID Lookup', subtitle: 'Find your voter registration', badge: 'SOON'),
        _Service(icon: Icons.person_pin_outlined, title: 'Constituency Finder', subtitle: 'Find your MP and MLA', badge: 'SOON'),
        _Service(icon: Icons.map_outlined, title: 'Polling Booth Locator', subtitle: 'Find your nearest polling booth', badge: 'SOON'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Color(AppConfig.current.primaryColor);

    return Scaffold(
      backgroundColor: Color(AppConfig.current.backgroundColor),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Text('Citizen Services', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Color(AppConfig.current.borderColor), height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _categories.map((cat) => _CategorySection(category: cat)).toList(),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final _ServiceCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 16),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: category.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(category.icon, color: category.color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(category.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF333333))),
            ],
          ),
        ),
        ...category.services.map((s) => _ServiceTile(service: s, accentColor: category.color)),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _Service service;
  final Color accentColor;
  const _ServiceTile({required this.service, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isLive = service.badge == 'LIVE';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(service.icon, color: accentColor, size: 22),
        ),
        title: Text(service.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
        subtitle: Text(service.subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isLive ? accentColor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            service.badge,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isLive ? accentColor : Colors.grey[400]),
          ),
        ),
        onTap: isLive ? () {} : null,
      ),
    );
  }
}

class _ServiceCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<_Service> services;
  const _ServiceCategory({required this.title, required this.icon, required this.color, required this.services});
}

class _Service {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  const _Service({required this.icon, required this.title, required this.subtitle, required this.badge});
}
