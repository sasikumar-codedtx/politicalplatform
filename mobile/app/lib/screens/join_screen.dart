import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'Male';
  String _district = '';
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = AppConfig.current;
    final primary = Color(f.primaryColor);
    final bg = Color(f.backgroundColor);
    final surface = Color(f.surfaceColor);
    final border = Color(f.borderColor);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          f.joinCtaLabel,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF1A1A1A)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: border, height: 1),
        ),
      ),
      body: _submitted ? _SuccessView(primary: primary, bg: bg) : _FormView(
        formKey: _formKey,
        nameCtrl: _nameCtrl,
        dobCtrl: _dobCtrl,
        gender: _gender,
        district: _district,
        primary: primary,
        surface: surface,
        border: border,
        onGenderChange: (v) => setState(() => _gender = v ?? 'Male'),
        onDistrictChange: (v) => setState(() => _district = v ?? ''),
        onSubmit: _submit,
        flavor: f,
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController dobCtrl;
  final String gender;
  final String district;
  final Color primary;
  final Color surface;
  final Color border;
  final ValueChanged<String?> onGenderChange;
  final ValueChanged<String?> onDistrictChange;
  final VoidCallback onSubmit;
  final FlavorConfig flavor;

  const _FormView({
    required this.formKey, required this.nameCtrl, required this.dobCtrl,
    required this.gender, required this.district, required this.primary,
    required this.surface, required this.border,
    required this.onGenderChange, required this.onDistrictChange,
    required this.onSubmit, required this.flavor,
  });

  static const _districts = [
    'Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli',
    'Salem', 'Tirunelveli', 'Erode', 'Vellore', 'Thoothukudi', 'Dindigul',
    'Thanjavur', 'Ranipet', 'Sivaganga', 'Virudhunagar', 'Nagapattinam',
    'Kancheepuram', 'Ramanathapuram', 'Cuddalore', 'Villupuram', 'Namakkal',
  ];

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 18),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primary, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.card_membership_rounded, color: primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Become a Member',
                          style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Join the ${flavor.partyName} movement',
                          style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Personal Details', style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 12),
            TextFormField(
              controller: nameCtrl,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              decoration: _inputDecoration('Full Name *', Icons.person_outline_rounded),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: dobCtrl,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              readOnly: true,
              decoration: _inputDecoration('Date of Birth *', Icons.cake_outlined),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1940),
                  lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                );
                if (picked != null) {
                  dobCtrl.text = '${picked.day}/${picked.month}/${picked.year}';
                }
              },
              validator: (v) => (v == null || v.isEmpty) ? 'Select date of birth' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: district.isEmpty ? null : district,
              dropdownColor: surface,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
              decoration: _inputDecoration('District *', Icons.location_city_outlined),
              hint: const Text('Select District', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
              items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: onDistrictChange,
              validator: (v) => (v == null || v.isEmpty) ? 'Select your district' : null,
            ),
            const SizedBox(height: 16),
            Text('Gender', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: ['Male', 'Female', 'Other'].map((g) {
                final isSelected = gender == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onGenderChange(g),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withValues(alpha: 0.1) : surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? primary : border),
                      ),
                      child: Text(
                        g,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: isSelected ? primary : const Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Submit Application',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your information is protected and will only be used for party membership purposes.',
              style: GoogleFonts.inter(color: const Color(0xFF999999), fontSize: 11, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final Color primary;
  final Color bg;

  const _SuccessView({required this.primary, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: primary, size: 44),
            ),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for joining the movement. Your membership application is under review.',
              style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 14, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('Back to Home', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
