import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberIdScreen extends StatelessWidget {
  const MemberIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // App bar
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 16 + topPad, bottom: 16),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Member ID Card', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const Spacer(),
                const Icon(Icons.ios_share_rounded, color: Colors.black54, size: 22),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Success banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Application Approved!', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green)),
                              Text('Welcome to TVK family. Your ID has been generated.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // ID Card — keeps its dark red gradient design
                  _IdCard(),
                  const SizedBox(height: 28),
                  // QR Code section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text('Scan to Verify', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
                        const SizedBox(height: 16),
                        Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                          ),
                          child: const Center(
                            child: Icon(Icons.qr_code_2_rounded, size: 130, color: Colors.black),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('TVK-2026-00124897', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54, letterSpacing: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Member privileges
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member Privileges', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                        const SizedBox(height: 14),
                        _Privilege(icon: Icons.event_available_rounded, label: 'Priority event registration'),
                        _Privilege(icon: Icons.how_to_vote_rounded, label: 'Voting rights in party elections'),
                        _Privilege(icon: Icons.group_rounded, label: 'Access to exclusive member community'),
                        _Privilege(icon: Icons.receipt_long_rounded, label: 'Direct grievance submission'),
                        _Privilege(icon: Icons.workspace_premium_rounded, label: 'TVK merchandise discounts'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Bottom action buttons
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottomPad, top: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE40101),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Download ID Card', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.ios_share_rounded, color: Color(0xFF1A1A1A), size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A0000), Color(0xFF3D0000), Color(0xFF1A0000)],
        ),
        border: Border.all(color: const Color(0xFFE40101).withValues(alpha: 0.4), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30, top: -30,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE40101).withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              left: -20, bottom: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE40101).withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('TVK', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tamilaga Vettri Kazhagam', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                          Text('Official Member Card', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Member info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 70, height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE40101).withValues(alpha: 0.5), width: 1),
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white38, size: 36),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Vijay Prabhakar', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
                            const SizedBox(height: 4),
                            _CardRow(label: 'Member ID', value: 'TVK-2026-00124897'),
                            _CardRow(label: 'District', value: 'Chennai North'),
                            _CardRow(label: 'Booth', value: 'Ward 42, Booth 7'),
                            _CardRow(label: 'Joined', value: 'May 2026'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Divider
                  Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 12),
                  // Footer
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A3D0A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.green, size: 12),
                            const SizedBox(width: 4),
                            Text('Verified Member', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('Valid till Dec 2027', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38)),
                    ],
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

class _CardRow extends StatelessWidget {
  final String label;
  final String value;
  const _CardRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white38)),
            TextSpan(text: value, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Privilege extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Privilege({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFE40101), size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
