import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/agent_service.dart';
import '../config/app_colors.dart';
import '../config/app_strings.dart';
import '../services/local_cache.dart';
import '../widgets/login_gate.dart';
import 'file_grievance_screen.dart';

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
    if (!await requireLogin(context, message: t('complaints.login_required'))) return;
    if (!mounted) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const FileGrievanceScreen()),
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
        title: Text(t('complaints.title'),
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(t('complaints.register'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
        SnackBar(content: Text(t('complaints.attachment_open_failed'))),
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
          SnackBar(content: Text(t('complaints.attachment_open_failed'))),
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
            Text(t('complaints.empty_title'),
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(t('complaints.empty_subtitle'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(t('complaints.register'), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
    final attachmentName = data['attachment_name'] as String? ?? t('complaints.attachment_default');
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
