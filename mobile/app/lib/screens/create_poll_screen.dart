import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePollScreen extends StatefulWidget {
  const CreatePollScreen({super.key});

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final _questionController = TextEditingController();
  final _options = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  int _durationDays = 2;
  static const _durations = [1, 2, 3, 5, 7];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _options) { c.dispose(); }
    super.dispose();
  }

  bool get _canSubmit =>
      _questionController.text.trim().isNotEmpty &&
      _options.where((c) => c.text.trim().isNotEmpty).length >= 2;

  void _addOption() {
    if (_options.length >= 6) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options[index].dispose();
      _options.removeAt(index);
    });
  }

  void _submit() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Poll created successfully!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                Text('Create Poll', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question field
                  Text('Poll Question', style: _labelStyle),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      controller: _questionController,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF1A1A1A), height: 1.5),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Ask a question to the community...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black38),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Options
                  Text('Options', style: _labelStyle),
                  const SizedBox(height: 10),
                  ...List.generate(_options.length, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionField(
                      controller: _options[i],
                      index: i,
                      canRemove: _options.length > 2,
                      onRemove: () => _removeOption(i),
                      onChanged: (_) => setState(() {}),
                    ),
                  )),
                  if (_options.length < 6)
                    GestureDetector(
                      onTap: _addOption,
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEEEEEE), width: 1, style: BorderStyle.solid),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFE40101), size: 18),
                            const SizedBox(width: 8),
                            Text('Add Option', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFFE40101), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Poll duration
                  Text('Poll Duration', style: _labelStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _durations.map((d) => GestureDetector(
                      onTap: () => setState(() => _durationDays = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _durationDays == d ? const Color(0xFFE40101).withValues(alpha: 0.15) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _durationDays == d ? const Color(0xFFE40101) : const Color(0xFFEEEEEE),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          d == 1 ? '1 Day' : '$d Days',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _durationDays == d ? const Color(0xFFE40101) : Colors.black54,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Settings
                  Text('Settings', style: _labelStyle),
                  const SizedBox(height: 10),
                  _ToggleSetting(label: 'Anonymous voting', subtitle: 'Voters\' identities will be hidden'),
                  _ToggleSetting(label: 'Show results before voting', subtitle: 'Users can see results before casting vote'),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Submit button
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16 + bottomPad, top: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: GestureDetector(
              onTap: _canSubmit ? _submit : null,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: _canSubmit ? const Color(0xFFE40101) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Publish Poll',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _canSubmit ? Colors.white : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A));
}

class _OptionField extends StatelessWidget {
  final TextEditingController controller;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onChanged;

  const _OptionField({
    required this.controller,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2665BE), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text('${index + 1}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF2665BE), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1A1A1A)),
              decoration: InputDecoration.collapsed(
                hintText: 'Option ${index + 1}',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black38),
              ),
              onChanged: onChanged,
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, color: Colors.black38, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _ToggleSetting extends StatefulWidget {
  final String label;
  final String subtitle;
  const _ToggleSetting({required this.label, required this.subtitle});

  @override
  State<_ToggleSetting> createState() => _ToggleSettingState();
}

class _ToggleSettingState extends State<_ToggleSetting> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A))),
                const SizedBox(height: 2),
                Text(widget.subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
              ],
            ),
          ),
          Switch(
            value: _value,
            onChanged: (v) => setState(() => _value = v),
            activeThumbColor: const Color(0xFFE40101),
            trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? const Color(0xFFE40101).withValues(alpha: 0.3) : const Color(0xFFEEEEEE)),
          ),
        ],
      ),
    );
  }
}
