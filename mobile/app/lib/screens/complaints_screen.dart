import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/agent_service.dart';
import '../config/app_colors.dart';
import '../services/local_cache.dart';

const _kRed = Color(0xFF9F1D1F);

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Map<String, dynamic>> _complaints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Paints the last known list immediately, then replaces it with the
  /// server's copy — no spinner on re-open.
  Future<void> _load() async {
    final cached = await LocalCache.read('complaints');
    if (cached is List && cached.isNotEmpty && mounted) {
      setState(() {
        _complaints = cached.cast<Map<String, dynamic>>();
        _loading = false;
      });
    }
    final items = await AgentService.getComplaints();
    if (!mounted) return;
    setState(() { _complaints = items; _loading = false; });
    await LocalCache.write('complaints', items);
  }

  Future<void> _register() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _RegisterComplaintSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('My Complaints',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Register Complaint', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : _complaints.isEmpty
              ? _EmptyState(onRegister: _register)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _complaints.length,
                    itemBuilder: (_, i) => _ComplaintCard(data: _complaints[i]),
                  ),
                ),
    );
  }
}

// Download an attachment (authed) and show it: images inline, anything else
// gets handed to the OS share/open sheet.
Future<void> _viewAttachment(BuildContext context, String id, String name) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: _kRed)),
  );
  final res = await AgentService.complaintAttachment(id);
  if (context.mounted) Navigator.pop(context); // close spinner
  if (res == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment.')),
      );
    }
    return;
  }
  final bytes = Uint8List.fromList(res.bytes);
  if (res.mime.startsWith('image/')) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain)),
            Positioned(
              top: 4, right: 4,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  } else {
    try {
      final dir = await getTemporaryDirectory();
      final safe = name.isEmpty ? 'attachment' : name;
      final f = File('${dir.path}/$safe');
      await f.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(f.path)]);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open attachment.')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRegister;
  const _EmptyState({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 56, color: _kRed),
            const SizedBox(height: 16),
            Text('No complaints yet',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Raise an issue and track its status here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Register Complaint', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ComplaintCard({required this.data});

  ({Color bg, Color fg}) _statusColors(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return (bg: const Color(0xFFE7F5E8), fg: const Color(0xFF2E7D32));
      case 'in progress':
        return (bg: const Color(0xFFFFF3E0), fg: const Color(0xFFE68E0C));
      default: // Pending
        return (bg: const Color(0xFFFDE7E7), fg: _kRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] as String? ?? 'Pending');
    final c = _statusColors(status);
    final hasAttachment = data['has_attachment'] == true;
    final attachmentName = data['attachment_name'] as String? ?? 'Attachment';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['title'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(20)),
                child: Text(status,
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: c.fg)),
              ),
            ],
          ),
          if ((data['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(data['description'] as String,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(data['category'] as String? ?? 'General',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          if (hasAttachment) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _viewAttachment(context, data['id'].toString(), attachmentName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: _kRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kRed.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attachment_rounded, size: 15, color: _kRed),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(attachmentName,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _kRed)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.visibility_rounded, size: 14, color: _kRed),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RegisterComplaintSheet extends StatefulWidget {
  const _RegisterComplaintSheet();

  @override
  State<_RegisterComplaintSheet> createState() => _RegisterComplaintSheetState();
}

class _RegisterComplaintSheetState extends State<_RegisterComplaintSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _categories = ['General', 'Water', 'Roads', 'Electricity', 'Sanitation', 'Health'];
  String _category = 'General';
  bool _submitting = false;
  File? _file;
  String? _fileName;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(withData: false);
    final path = res?.files.single.path;
    if (path != null) {
      setState(() { _file = File(path); _fileName = res!.files.single.name; });
    }
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final result = await AgentService.registerComplaint(
      title: title, description: _desc.text.trim(), category: _category, file: _file,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, true);
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not submit — check connection and login.')),
      );
    }
  }

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kRed, width: 1.4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.campaign_rounded, color: _kRed, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Register a Complaint',
                          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('We\'ll track it and update the status.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(controller: _title, decoration: _dec('Title', 'e.g. Street light not working')),
            const SizedBox(height: 12),
            TextField(controller: _desc, minLines: 3, maxLines: 5, decoration: _dec('Description', 'Describe the issue and location')),
            const SizedBox(height: 16),
            Text('Category',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _categories.map((cat) {
                final active = cat == _category;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? _kRed : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? _kRed : AppColors.border),
                    ),
                    child: Text(cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.textSecondary,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Attachment
            _file == null
                ? GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.upload_file_rounded, color: _kRed, size: 26),
                          const SizedBox(height: 6),
                          Text('Attach evidence',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          Text('Image, PDF, or ZIP',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: _kRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kRed.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: _kRed, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_fileName ?? 'Selected file',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ),
                        GestureDetector(
                          onTap: () => setState(() { _file = null; _fileName = null; }),
                          child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Submit Complaint', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
