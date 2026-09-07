import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const List<_ServiceCategory> _categories = [
    _ServiceCategory(
      titleKey: 'services.cat_vehicle',
      icon: Icons.directions_car_outlined,
      color: Color(0xFF19AAED),
      services: [
        _Service(icon: Icons.search_rounded, titleKey: 'services.vahan_title', subtitleKey: 'services.vahan_subtitle', badge: 'LIVE'),
        _Service(icon: Icons.credit_card_outlined, titleKey: 'services.sarathi_title', subtitleKey: 'services.sarathi_subtitle', badge: 'LIVE'),
        _Service(icon: Icons.receipt_long_outlined, titleKey: 'services.road_tax_title', subtitleKey: 'services.road_tax_subtitle', badge: 'SOON'),
      ],
    ),
    _ServiceCategory(
      titleKey: 'services.cat_social',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF138808),
      services: [
        _Service(icon: Icons.people_outline_rounded, titleKey: 'services.scheme_eligibility_title', subtitleKey: 'services.scheme_eligibility_subtitle', badge: 'SOON'),
        _Service(icon: Icons.receipt_outlined, titleKey: 'services.ration_card_title', subtitleKey: 'services.ration_card_subtitle', badge: 'SOON'),
        _Service(icon: Icons.health_and_safety_outlined, titleKey: 'services.ayushman_title', subtitleKey: 'services.ayushman_subtitle', badge: 'SOON'),
      ],
    ),
    _ServiceCategory(
      titleKey: 'services.cat_civic',
      icon: Icons.location_city_outlined,
      color: Color(0xFF9C27B0),
      services: [
        _Service(icon: Icons.how_to_vote_outlined, titleKey: 'services.voter_id_title', subtitleKey: 'services.voter_id_subtitle', badge: 'SOON'),
        _Service(icon: Icons.person_pin_outlined, titleKey: 'services.constituency_title', subtitleKey: 'services.constituency_subtitle', badge: 'SOON'),
        _Service(icon: Icons.map_outlined, titleKey: 'services.polling_booth_title', subtitleKey: 'services.polling_booth_subtitle', badge: 'SOON'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        title: Text(t('services.title'), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: AppColors.border, height: 1),
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
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(category.icon, color: category.color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(t(category.titleKey), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(service.icon, color: accentColor, size: 22),
        ),
        title: Text(t(service.titleKey), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(t(service.subtitleKey), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isLive ? accentColor.withValues(alpha: 0.1) : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isLive ? t('services.badge_live') : t('services.badge_soon'),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: isLive ? accentColor : AppColors.textMuted),
          ),
        ),
        onTap: isLive ? () {} : null,
      ),
    );
  }
}

class _ServiceCategory {
  final String titleKey;
  final IconData icon;
  final Color color;
  final List<_Service> services;
  const _ServiceCategory({required this.titleKey, required this.icon, required this.color, required this.services});
}

class _Service {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String badge;
  const _Service({required this.icon, required this.titleKey, required this.subtitleKey, required this.badge});
}
