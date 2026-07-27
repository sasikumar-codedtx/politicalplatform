import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/profile_service.dart';
import '../services/agent_service.dart';
import '../widgets/loading_overlay.dart';
import '../config/app_colors.dart';

// Figma: 1328-9683 — TVK Member ID card result screen (lanyard + white card)

const _kRed = Color(0xFFE10600);
const _kCardRed = Color(0xFFC1121C);

class MemberIdScreen extends StatefulWidget {
  final File? photoFile;

  /// Pass the member row to show it directly. When null the latest membership
  /// for the logged-in account is fetched.
  final Map<String, dynamic>? member;
  const MemberIdScreen({super.key, this.photoFile, this.member});

  @override
  State<MemberIdScreen> createState() => _MemberIdScreenState();
}

class _MemberIdScreenState extends State<MemberIdScreen> {
  final _cardKey = GlobalKey();
  Map<String, dynamic>? _member;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _member = widget.member;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    final m = await AgentService.getMember();
    if (mounted) setState(() { _member = m; _loading = false; });
  }

  String get _shareText {
    final m = _member;
    final id = m?['member_id'] ?? '';
    final name = m?['name'] ?? '';
    return 'I am now a TVK member! 🚩\nName: $name\nMember ID: $id\n\nJoin TVK on the My TVK app.';
  }

  /// Shares the card as a PNG so WhatsApp (and anything else) shows the image,
  /// falling back to text if the card could not be rendered.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = await _captureCard();
      if (file != null) {
        await Share.shareXFiles([XFile(file.path)], text: _shareText);
      } else {
        await Share.share(_shareText);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<File?> _captureCard() async {
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Wait out any in-flight paint so the photo is included, not a blank frame.
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 60));
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      final dir = await getTemporaryDirectory();
      // Unique name per share — reusing one path made the share sheet show its
      // cached thumbnail of the previous card design.
      final file = File(
          '${dir.path}/tvk_member_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final dark = AppColors.isDark;

    // No AppBar here, so AppBarTheme.systemOverlayStyle never applies — set the
    // status-bar icon colour for the current theme explicitly.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
      backgroundColor: AppColors.bg,
      body: Container(
        decoration: dark
            ? BoxDecoration(color: AppColors.bg)
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFDF8E6), Color(0xFFFCE7DC)],
                ),
              ),
        child: LoadingOverlay(
          isLoading: _loading || _sharing,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: topPad + 56,
                  left: 20,
                  right: 20,
                  bottom: 32 + bottomPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Lanyard(),
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: Center(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: _TvkIdCard(
                              photoFile: widget.photoFile, member: _member),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'Your id card is ready!',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 40,
                        height: 1.0,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Get your id card',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        height: 1.0,
                        letterSpacing: 0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: _kRed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Back to Home',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _RoundAction(
                top: topPad + 10,
                left: 16,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
              _RoundAction(
                top: topPad + 10,
                right: 16,
                icon: Icons.ios_share_rounded,
                onTap: _share,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

// ─── Lanyard strap + clip hanging above the card ─────────────────────────────

class _Lanyard extends StatelessWidget {
  const _Lanyard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFFFD000), Color(0xFFFFF3C0), Color(0xFFB00E0E)],
              stops: [0.0, 0.46, 0.74],
            ),
          ),
        ),
        Container(
          width: 46,
          height: 15,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Container(
          width: 20,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 3),
          ),
        ),
      ],
    );
  }
}

// ─── TVK ID Card — white card inset in a red holder ──────────────────────────

class _TvkIdCard extends StatelessWidget {
  final File? photoFile;
  final Map<String, dynamic>? member;
  const _TvkIdCard({this.photoFile, this.member});

  String _v(String key, String fallback) {
    final val = member?[key];
    return (val is String && val.trim().isNotEmpty) ? val : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final cardW = (sw * 0.62).clamp(220.0, 290.0);

    return Container(
      width: cardW,
      decoration: BoxDecoration(
        color: _kCardRed,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/tvk_flag.png',
                height: 22, fit: BoxFit.contain),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'தமிழக வெற்றிக் கழகம்',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kRed,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD40000),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: photoFile != null
                      ? Image.file(photoFile!, fit: BoxFit.cover)
                      : ValueListenableBuilder<String?>(
                          valueListenable: ProfileService.avatar,
                          builder: (_, path, _) => path != null
                              ? Image.file(File(path), fit: BoxFit.cover)
                              : const Icon(Icons.person_rounded,
                                  color: Colors.white70, size: 64),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(label: 'Name', value: _v('name', '—')),
            _InfoRow(label: 'Mobile No', value: _v('mobile', '—')),
            _InfoRow(label: 'District', value: _v('district', '—')),
            _InfoRow(label: 'Booth No', value: _v('booth', '—')),
          ],
        ),
      ),
    );
  }
}

// ─── Info row: label : value ─────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 12.5,
      color: const Color(0xFF1A1A1A),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: style),
          ),
          Text(':', style: style),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: style),
          ),
        ],
      ),
    );
  }
}

// ─── Circular top action button ──────────────────────────────────────────────

class _RoundAction extends StatelessWidget {
  final double top;
  final double? left;
  final double? right;
  final IconData icon;
  final VoidCallback onTap;
  const _RoundAction({
    required this.top,
    this.left,
    this.right,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 17),
        ),
      ),
    );
  }
}
