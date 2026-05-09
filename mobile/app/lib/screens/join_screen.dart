import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'member_id_screen.dart';

class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Details
                  Text(
                    'Member Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FormField(label: 'Name', placeholder: 'Enter Name'),
                  const SizedBox(height: 16),
                  _FormField(label: 'Email', placeholder: 'Enter Your Email'),
                  const SizedBox(height: 16),
                  _FormField(label: 'Mobile Number', placeholder: 'Enter Your Mobile Number'),
                  const SizedBox(height: 16),
                  // DOB + Gender row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date of Birth', style: _labelStyle),
                            const SizedBox(height: 10),
                            _InputBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('DD MM YY', style: _placeholderStyle),
                                  const Icon(Icons.calendar_today_outlined, color: Colors.black38, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gender', style: _labelStyle),
                            const SizedBox(height: 10),
                            _InputBox(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Select Gender', style: _placeholderStyle),
                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Location Details
                  Text(
                    'Location Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('District', style: _labelStyle),
                  const SizedBox(height: 10),
                  _InputBox(child: Text('Select District', style: _placeholderStyle)),
                  const SizedBox(height: 16),
                  Text('Pin Code', style: _labelStyle),
                  const SizedBox(height: 10),
                  _InputBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Pin Code', style: _placeholderStyle),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Booth Number', style: _labelStyle),
                  const SizedBox(height: 10),
                  _InputBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Booth Number', style: _placeholderStyle),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black38, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Don't know booth number?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE40101),
                        letterSpacing: 0.2,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // KYC Verification
                  Text(
                    'KYC Verification',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Attach Your KYC', style: _labelStyle),
                  const SizedBox(height: 4),
                  Text(
                    'Files only upload : PDF, JPEG, PNG, JPG',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                      letterSpacing: 0.2,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Upload box
                  Container(
                    height: 106,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file_rounded, color: Colors.black54, size: 24),
                          const SizedBox(height: 10),
                          Text(
                            'Tap to Attach Document',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black38,
                              letterSpacing: 0.2,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit button
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberIdScreen())),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE40101),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Submit and Get ID Card',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF1A1A1A),
    letterSpacing: 0.2,
    height: 1.4,
  );

  TextStyle get _placeholderStyle => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black38,
    letterSpacing: 0.2,
    height: 1.4,
  );
}

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 216 + topPad,
      child: Stack(
        children: [
          // Header image
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 216 + topPad,
              child: Image.asset('assets/images/event_3.png', fit: BoxFit.cover),
            ),
          ),
          // Gradient: black at bottom → transparent (inverted)
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
            top: 78 + topPad,
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
            ),
          ),
          // Title block
          Positioned(
            bottom: 0,
            left: 16,
            child: SizedBox(
              width: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                    ).createShader(bounds),
                    child: Text(
                      'Be Part of the Change',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 34,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get updates, contribute, and shape the future with us',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String placeholder;

  const _FormField({required this.label, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1A1A1A),
            letterSpacing: 0.2,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        _InputBox(
          child: Text(
            placeholder,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black38,
              letterSpacing: 0.2,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputBox extends StatelessWidget {
  final Widget child;
  const _InputBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}
