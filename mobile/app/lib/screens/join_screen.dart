import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'face_capture_screen.dart';

// Figma: 1328-4236 — Join TVK registration form

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String? _district;
  final _pinCtrl = TextEditingController();
  final _boothCtrl = TextEditingController();

  final _genderOptions = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];
  final _districtOptions = [
    'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem',
    'Tirunelveli', 'Vellore', 'Erode', 'Thoothukudi', 'Dindigul',
    'Thanjavur', 'Tiruppur', 'Ranipet', 'Sivaganga', 'Virudhunagar',
    'Nagapattinam', 'Cuddalore', 'Villupuram', 'Kancheepuram',
    'Chengalpattu', 'Kallakurichi', 'Tiruvannamalai', 'Krishnagiri',
    'Dharmapuri', 'Namakkal', 'Ariyalur', 'Perambalur', 'Karur',
    'Nilgiris', 'Tiruvarur', 'Pudukkottai', 'Ramanathapuram',
    'Tenkasi', 'Kanyakumari', 'Mayiladuthurai', 'Tirupathur',
    'Chengam', 'Tirupattur',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _boothCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFE40101)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _onSubmit() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (_mobileCtrl.text.trim().length < 10) {
      _showError('Please enter a valid mobile number');
      return;
    }
    // Navigate to face capture
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceCaptureScreen()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        backgroundColor: const Color(0xFFE40101),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _JoinHeader(topPad: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Member Details ─────────────────────────────
                    _SectionTitle('Member Details'),
                    const SizedBox(height: 16),
                    _Field(
                      label: 'Name',
                      placeholder: 'Enter your full name',
                      controller: _nameCtrl,
                      inputType: TextInputType.name,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Email',
                      placeholder: 'Enter your email address',
                      controller: _emailCtrl,
                      inputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Mobile Number',
                      placeholder: 'Enter 10-digit mobile number',
                      controller: _mobileCtrl,
                      inputType: TextInputType.phone,
                      maxLength: 10,
                    ),
                    const SizedBox(height: 14),

                    // DOB + Gender row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Date of Birth'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDob,
                                child: _InputBox(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _dob == null
                                              ? 'DD / MM / YYYY'
                                              : '${_dob!.day.toString().padLeft(2, '0')} / ${_dob!.month.toString().padLeft(2, '0')} / ${_dob!.year}',
                                          style: _dob == null
                                              ? _placeholderStyle
                                              : _valueStyle,
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined,
                                          color: Colors.black38, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Gender'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  final val = await _showPicker(
                                      context, _genderOptions, 'Select Gender');
                                  if (val != null) setState(() => _gender = val);
                                },
                                child: _InputBox(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _gender ?? 'Select',
                                          style: _gender == null
                                              ? _placeholderStyle
                                              : _valueStyle,
                                        ),
                                      ),
                                      const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: Colors.black38,
                                          size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Location Details ───────────────────────────
                    _SectionTitle('Location Details'),
                    const SizedBox(height: 16),
                    _FieldLabel('District'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final val = await _showPicker(
                            context, _districtOptions, 'Select District');
                        if (val != null) setState(() => _district = val);
                      },
                      child: _InputBox(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _district ?? 'Select District',
                                style: _district == null
                                    ? _placeholderStyle
                                    : _valueStyle,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Colors.black38, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Pin Code',
                      placeholder: 'Enter pin code',
                      controller: _pinCtrl,
                      inputType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 14),
                    _Field(
                      label: 'Booth Number',
                      placeholder: 'Enter booth number',
                      controller: _boothCtrl,
                      inputType: TextInputType.text,
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Don't know your booth number?",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE40101),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── KYC Verification ───────────────────────────
                    _SectionTitle('KYC Verification'),
                    const SizedBox(height: 8),
                    _FieldLabel('Attach Your KYC Document'),
                    const SizedBox(height: 4),
                    Text(
                      'Accepted formats: PDF, JPEG, PNG, JPG',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.black38),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file_rounded,
                                color: Colors.black38, size: 24),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to attach document',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13, color: Colors.black38),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit button ──────────────────────────────
                    GestureDetector(
                      onTap: _onSubmit,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE40101),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFE40101).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Submit & Get ID Card',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  TextStyle get _placeholderStyle => GoogleFonts.plusJakartaSans(
      fontSize: 14, color: Colors.black38, fontWeight: FontWeight.w400);

  TextStyle get _valueStyle => GoogleFonts.plusJakartaSans(
      fontSize: 14, color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w500);

  Future<String?> _showPicker(
      BuildContext context, List<String> options, String title) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              )),
          const SizedBox(height: 12),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (ctx, i) => ListTile(
                title: Text(options[i],
                    style: GoogleFonts.plusJakartaSans(fontSize: 14)),
                onTap: () => Navigator.pop(ctx, options[i]),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _JoinHeader extends StatelessWidget {
  final double topPad;
  const _JoinHeader({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: topPad + 220,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // TVK flag background
          Positioned.fill(
            child: Image.asset(
              'assets/images/tvk_flag.png',
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(color: const Color(0xFF8B0000)),
            ),
          ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC000000),
                    Color(0x88000000),
                    Color(0xFF000000),
                  ],
                  stops: [0.0, 0.5, 1.0],
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
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          // Title
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFCA00), Color(0xFFE40101)],
                  ).createShader(bounds),
                  child: Text(
                    'Be Part of\nthe Change',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 38,
                      color: Colors.white,
                      height: 1.05,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Register as a TVK member — get updates, contribute,\nand shape Tamil Nadu\'s future.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.5,
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF444444),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final TextInputType inputType;
  final int? maxLength;

  const _Field({
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.inputType,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF1A1A1A),
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14, color: Colors.black38),
            filled: true,
            fillColor: const Color(0xFFF0F0F0),
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE40101), width: 1.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}
