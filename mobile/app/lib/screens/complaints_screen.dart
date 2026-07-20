import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';

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

  Future<void> _load() async {
    final items = await AgentService.getComplaints();
    if (mounted) setState(() { _complaints = items; _loading = false; });
  }

  Future<void> _register() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _RegisterComplaintSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text('My Complaints',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register,
        backgroundColor: const Color(0xFF9F1D1F),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Register Complaint', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9F1D1F)))
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
            const Icon(Icons.assignment_outlined, size: 56, color: Color(0xFF9F1D1F)),
            const SizedBox(height: 16),
            Text('No complaints yet',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text('Raise an issue and track its status here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF666666))),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('Register Complaint', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F1D1F),
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
        return (bg: const Color(0xFFFDE7E7), fg: const Color(0xFF9F1D1F));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] as String? ?? 'Pending');
    final c = _statusColors(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF555555), height: 1.4)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.folder_outlined, size: 13, color: Color(0xFF999999)),
              const SizedBox(width: 4),
              Text(data['category'] as String? ?? 'General',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF999999))),
            ],
          ),
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

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _title.text.trim();
    if (title.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final result = await AgentService.registerComplaint(
      title: title, description: _desc.text.trim(), category: _category,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Register Complaint',
              style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            minLines: 2, maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((cat) {
              final active = cat == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF9F1D1F) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? const Color(0xFF9F1D1F) : const Color(0xFFDDDDDD)),
                  ),
                  child: Text(cat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : const Color(0xFF555555),
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9F1D1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Submit', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
