import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({super.key});

  static const List<_Issue> _issues = [
    _Issue(icon: Icons.agriculture_rounded, title: 'Farmers of India', tag: 'Agriculture', description: 'The Modi government must revoke all three of the black agricultural laws and listen to the voice of our Annadattas. Congress guarantees MSP as a legal right.', points: ['Legal guarantee of MSP', 'Debt waiver for farmers', 'Crop insurance reform']),
    _Issue(icon: Icons.work_outline_rounded, title: 'Job Destruction', tag: 'Economy', description: 'Ever-shrinking employment opportunities has made joblessness an epidemic. Congress will create 30 lakh government jobs every year.', points: ['30 lakh government jobs annually', 'MNREGA protection', 'Skill India 2.0']),
    _Issue(icon: Icons.school_outlined, title: 'Education for All', tag: 'Education', description: 'Congress commits to 6% of GDP for education. Every child deserves access to quality schooling regardless of their economic background.', points: ['6% GDP for education', 'Free university education', 'Student loan relief']),
    _Issue(icon: Icons.local_hospital_outlined, title: 'Universal Healthcare', tag: 'Health', description: 'Congress will bring the Right to Health Act and expand public health infrastructure across rural and urban India.', points: ['Right to Health Act', '25 lakh health workers', '₹25 lakh free insurance']),
    _Issue(icon: Icons.people_alt_outlined, title: 'Social Justice', tag: 'Equality', description: 'A full socio-economic caste census to uncover the real picture of inequality and ensure proper representation for all.', points: ['Caste census in year 1', 'OBC sub-categorisation', 'SC/ST act protection']),
    _Issue(icon: Icons.public_rounded, title: 'Foreign Policy', tag: 'Foreign Policy', description: 'It is high time the government learned that muscular tactics are no substitute for mature and deft diplomacy.', points: ['Restore border status quo', 'Strengthen SAARC', 'Diplomatic dialogue priority']),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Color(AppConfig.current.primaryColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Key Issues', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _issues.length,
        itemBuilder: (context, index) => _IssueCard(issue: _issues[index], primary: primary),
      ),
    );
  }
}

class _IssueCard extends StatefulWidget {
  final _Issue issue;
  final Color primary;
  const _IssueCard({required this.issue, required this.primary});

  @override
  State<_IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<_IssueCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: widget.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(widget.issue.icon, color: widget.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: widget.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(widget.issue.tag, style: GoogleFonts.inter(color: widget.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 5),
                        Text(widget.issue.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: Colors.grey[100]),
                  const SizedBox(height: 8),
                  Text(widget.issue.description, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF444444), height: 1.6)),
                  const SizedBox(height: 12),
                  ...widget.issue.points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: widget.primary, size: 16),
                        const SizedBox(width: 8),
                        Text(p, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF333333))),
                      ],
                    ),
                  )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Issue {
  final IconData icon;
  final String title;
  final String tag;
  final String description;
  final List<String> points;
  const _Issue({required this.icon, required this.title, required this.tag, required this.description, required this.points});
}
