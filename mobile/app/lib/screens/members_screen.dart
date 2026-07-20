import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/agent_service.dart';
import '../widgets/loading_overlay.dart';
import 'join_screen.dart';
import 'member_id_screen.dart';

/// Every TVK membership registered under this login. Server-backed, so the
/// same account shows the same cards on any device.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<Map<String, dynamic>> _members = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AgentService.listMembers();
    if (mounted) setState(() { _members = items; _loading = false; });
  }

  Future<void> _addMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JoinScreen()),
    );
    if (mounted) _load();
  }

  void _openCard(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MemberIdScreen(member: member)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: LoadingOverlay(
        isLoading: _loading,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(12, topPad + 8, 20, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      'My Memberships',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const SizedBox.shrink()
                  : _members.isEmpty
                      ? _EmptyState(onJoin: _addMember)
                      : RefreshIndicator(
                          color: const Color(0xFF9F1D1F),
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            itemCount: _members.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _MemberRow(
                              member: _members[i],
                              onTap: () => _openCard(_members[i]),
                            ),
                          ),
                        ),
            ),
            if (!_loading && _members.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomPad),
                child: _PrimaryButton(label: '＋  New Member', onTap: _addMember),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onTap;
  const _MemberRow({required this.member, required this.onTap});

  String _v(String key, String fallback) {
    final val = member[key];
    return (val is String && val.trim().isNotEmpty) ? val : fallback;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'TVK',
                style: GoogleFonts.bebasNeue(
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _v('name', 'TVK Member'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_v('member_id', '—')}  ·  ${_v('district', '—')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.black38, size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onJoin;
  const _EmptyState({required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 14),
            Text(
              'No membership yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Join TVK to get your official member ID card.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            _PrimaryButton(label: 'Join as member', onTap: onJoin),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF9F1D1F),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.32,
          ),
        ),
      ),
    );
  }
}
