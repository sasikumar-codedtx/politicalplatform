import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../config/tn_reference_data.dart';
import '../services/agent_service.dart';
import '../services/profile_service.dart';
import '../widgets/loading_overlay.dart';

// Single continuous, scrollable "File a Grievance" page — replaces the old
// Register-Complaint bottom sheet. Same section-card pattern throughout.

class FileGrievanceScreen extends StatefulWidget {
  const FileGrievanceScreen({super.key});

  @override
  State<FileGrievanceScreen> createState() => _FileGrievanceScreenState();
}

class _FileGrievanceScreenState extends State<FileGrievanceScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _taluk = TextEditingController();
  final _village = TextEditingController();
  final _ward = TextEditingController();
  final _pincode = TextEditingController();
  final _address = TextEditingController();
  final _department = TextEditingController();
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _previousRef = TextEditingController();

  Bilingual? _district;
  Bilingual? _localBody;
  Bilingual? _category;
  Bilingual? _subcategory;
  bool _hasPrevious = false;
  bool _isUrgent = false;
  bool _declared = false;
  bool _submitting = false;
  File? _file;
  String? _fileName;

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    final name = ProfileService.displayName.value;
    if (name.isNotEmpty && name != 'Member') _name.text = name;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _taluk.dispose();
    _village.dispose();
    _ward.dispose();
    _pincode.dispose();
    _address.dispose();
    _department.dispose();
    _title.dispose();
    _desc.dispose();
    _previousRef.dispose();
    super.dispose();
  }

  void _onCategoryChanged(Bilingual cat) {
    setState(() {
      _category = cat;
      _subcategory = null;
      _department.text = kCategoryDepartment[cat]?.label ?? '';
    });
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    final path = res?.files.single.path;
    if (path != null) setState(() { _file = File(path); _fileName = res!.files.single.name; });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.plusJakartaSans(fontSize: 14)), backgroundColor: AppColors.red),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final pin = _pincode.text.trim();
    if (_name.text.trim().isEmpty ||
        _district == null ||
        _localBody == null ||
        _village.text.trim().isEmpty ||
        _address.text.trim().isEmpty ||
        _category == null ||
        _subcategory == null ||
        _title.text.trim().isEmpty ||
        _desc.text.trim().isEmpty ||
        !_declared) {
      _showError(t('grievance.required_fields'));
      return;
    }
    if (pin.length != 6 || int.tryParse(pin) == null) {
      _showError(t('grievance.pincode_invalid'));
      return;
    }
    setState(() => _submitting = true);
    final result = await AgentService.registerComplaint(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      category: _category!.en,
      subcategory: _subcategory!.en,
      department: _department.text.trim(),
      district: _district!.en,
      taluk: _taluk.text.trim(),
      localBody: _localBody!.en,
      village: _village.text.trim(),
      ward: _ward.text.trim(),
      pincode: pin,
      address: _address.text.trim(),
      previousRef: _hasPrevious ? _previousRef.text.trim() : '',
      isUrgent: _isUrgent,
      file: _file,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result == null) {
      _showError(t('grievance.submit_failed'));
      return;
    }
    setState(() => _result = result);
  }

  void _fileAnother() {
    setState(() {
      _result = null;
      _taluk.clear();
      _village.clear();
      _ward.clear();
      _pincode.clear();
      _address.clear();
      _department.clear();
      _title.clear();
      _desc.clear();
      _previousRef.clear();
      _district = null;
      _localBody = null;
      _category = null;
      _subcategory = null;
      _hasPrevious = false;
      _isUrgent = false;
      _declared = false;
      _file = null;
      _fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(t('grievance.appbar_title'),
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: LoadingOverlay(
        isLoading: _submitting,
        child: _result != null ? _SuccessView(result: _result!, onTrack: () => Navigator.pop(context, true), onFileAnother: _fileAnother) : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('grievance.subtitle'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          const SizedBox(height: 20),

          _SectionCard(
            number: '1',
            title: t('grievance.section1_title'),
            subtitle: t('grievance.section1_subtitle'),
            children: [
              _Field(label: '${t('grievance.name_label')} *', hint: t('grievance.name_hint'), controller: _name, inputType: TextInputType.name),
              const SizedBox(height: 12),
              _FieldLabel(t('grievance.mobile_label')),
              const SizedBox(height: 8),
              _InputBox(
                child: Text(FirebaseAuth.instance.currentUser?.phoneNumber ?? '—', style: _valueStyle),
              ),
              const SizedBox(height: 12),
              _Field(label: t('grievance.email_label'), hint: t('grievance.email_hint'), controller: _email, inputType: TextInputType.emailAddress),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '2',
            title: t('grievance.section2_title'),
            subtitle: t('grievance.section2_subtitle'),
            children: [
              _FieldLabel('${t('grievance.district_label')} *'),
              const SizedBox(height: 8),
              _Picker(value: _district?.label, placeholder: t('grievance.select_district'), onTap: () async {
                final v = await _showBilingualPicker(context, kTnDistricts, t('grievance.select_district'));
                if (v != null) setState(() => _district = v);
              }),
              const SizedBox(height: 12),
              _Field(label: t('grievance.taluk_label'), hint: t('grievance.taluk_hint'), controller: _taluk, inputType: TextInputType.text),
              const SizedBox(height: 12),
              _FieldLabel('${t('grievance.local_body_label')} *'),
              const SizedBox(height: 8),
              _Picker(value: _localBody?.label, placeholder: t('grievance.select_local_body'), onTap: () async {
                final v = await _showBilingualPicker(context, kLocalBodyTypes, t('grievance.select_local_body'));
                if (v != null) setState(() => _localBody = v);
              }),
              const SizedBox(height: 12),
              _Field(label: '${t('grievance.village_label')} *', hint: t('grievance.village_hint'), controller: _village, inputType: TextInputType.text),
              const SizedBox(height: 12),
              _Field(label: t('grievance.ward_label'), hint: t('grievance.ward_hint'), controller: _ward, inputType: TextInputType.text),
              const SizedBox(height: 12),
              _Field(label: '${t('grievance.pincode_label')} *', hint: t('grievance.pincode_hint'), controller: _pincode, inputType: TextInputType.number, maxLength: 6),
              const SizedBox(height: 12),
              _Field(label: '${t('grievance.address_label')} *', hint: t('grievance.address_hint'), controller: _address, inputType: TextInputType.multiline, maxLines: 3),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '3',
            title: t('grievance.section3_title'),
            subtitle: t('grievance.section3_subtitle'),
            children: [
              _FieldLabel('${t('grievance.category_label')} *'),
              const SizedBox(height: 8),
              _Picker(value: _category?.label, placeholder: t('grievance.select'), onTap: () async {
                final v = await _showBilingualPicker(context, kGrievanceCategories.keys.toList(), t('grievance.category_label'));
                if (v != null) _onCategoryChanged(v);
              }),
              if (_category != null) ...[
                const SizedBox(height: 12),
                _FieldLabel('${t('grievance.subcategory_label')} *'),
                const SizedBox(height: 8),
                _Picker(value: _subcategory?.label, placeholder: t('grievance.select'), onTap: () async {
                  final v = await _showBilingualPicker(context, kGrievanceCategories[_category] ?? [], t('grievance.subcategory_label'));
                  if (v != null) setState(() => _subcategory = v);
                }),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '4',
            title: t('grievance.section4_title'),
            subtitle: t('grievance.section4_subtitle'),
            children: [
              _Field(label: t('grievance.department_label'), hint: t('grievance.department_hint'), controller: _department, inputType: TextInputType.text),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '5',
            title: t('grievance.section5_title'),
            subtitle: '',
            children: [
              _Field(label: '${t('grievance.title_label')} *', hint: t('grievance.title_hint'), controller: _title, inputType: TextInputType.text),
              const SizedBox(height: 12),
              _FieldLabel('${t('grievance.desc_label')} *'),
              const SizedBox(height: 8),
              TextField(
                controller: _desc,
                minLines: 4, maxLines: 8, maxLength: 2000,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: t('grievance.desc_hint'),
                  hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.red, width: 1.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '6',
            title: t('grievance.section6_title'),
            subtitle: '',
            children: [
              Row(
                children: [
                  _Chip(label: t('grievance.no'), active: !_hasPrevious, onTap: () => setState(() => _hasPrevious = false)),
                  const SizedBox(width: 8),
                  _Chip(label: t('grievance.yes'), active: _hasPrevious, onTap: () => setState(() => _hasPrevious = true)),
                ],
              ),
              if (_hasPrevious) ...[
                const SizedBox(height: 12),
                _Field(label: t('grievance.previous_ref_label'), hint: t('grievance.previous_ref_hint'), controller: _previousRef, inputType: TextInputType.text),
              ],
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '7',
            title: t('grievance.section7_title'),
            subtitle: t('grievance.section7_subtitle'),
            children: [
              _file == null
                  ? GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.upload_file_rounded, color: AppColors.red, size: 26),
                            const SizedBox(height: 6),
                            Text(t('grievance.attach_evidence'), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                            Text(t('grievance.attach_types'), style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_rounded, color: AppColors.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_fileName ?? t('grievance.selected_file'), maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ),
                          GestureDetector(
                            onTap: () => setState(() { _file = null; _fileName = null; }),
                            child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 16),

          _SectionCard(
            number: '8',
            title: t('grievance.section8_title'),
            subtitle: '',
            children: [
              Text(t('grievance.urgency_question'), style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Chip(label: t('grievance.no'), active: !_isUrgent, onTap: () => setState(() => _isUrgent = false)),
                  const SizedBox(width: 8),
                  _Chip(label: t('grievance.yes'), active: _isUrgent, onTap: () => setState(() => _isUrgent = true)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => setState(() => _declared = !_declared),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(value: _declared, activeColor: AppColors.red, onChanged: (v) => setState(() => _declared = v ?? false)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(t('grievance.declaration'), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(t('grievance.file_button'), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _valueStyle => GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500);

  Future<Bilingual?> _showBilingualPicker(BuildContext context, List<Bilingual> options, String title) {
    return showModalBottomSheet<Bilingual>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (ctx, i) => ListTile(
                title: Text(options[i].label, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
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

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback onTrack;
  final VoidCallback onFileAnother;
  const _SuccessView({required this.result, required this.onTrack, required this.onFileAnother});

  @override
  Widget build(BuildContext context) {
    final id = result['id'];
    final grievanceId = 'GRV-${DateTime.now().year}-${id.toString().padLeft(6, '0')}';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFFE7F5E8), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D32), size: 34),
            ),
            const SizedBox(height: 18),
            Text(t('grievance.success_title'), textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(t('grievance.success_subtitle'), textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(t('grievance.grievance_id_label'), style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(grievanceId, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.red)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onTrack,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(t('grievance.track_button'), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: onFileAnother,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary, side: BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(t('grievance.file_another_button'), style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section building blocks ────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final List<Widget> children;
  const _SectionCard({required this.number, required this.title, required this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26, height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                child: Text(number, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted, height: 1.3)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary));
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType inputType;
  final int? maxLength;
  final int maxLines;
  const _Field({required this.label, required this.hint, required this.controller, required this.inputType, this.maxLength, this.maxLines = 1});

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
          maxLines: maxLines,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textMuted),
            filled: true, fillColor: AppColors.surfaceAlt,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.red, width: 1.5)),
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
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
      child: child,
    );
  }
}

class _Picker extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  const _Picker({required this.value, required this.placeholder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _InputBox(
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                style: value == null
                    ? GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textMuted)
                    : GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.red : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.red : AppColors.border),
        ),
        child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }
}
