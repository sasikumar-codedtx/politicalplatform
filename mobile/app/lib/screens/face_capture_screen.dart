import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'member_id_screen.dart';

// Figma: 1328-9652 — Face/photo capture screen for TVK member ID card

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  File? _capturedImage;
  bool _flashOn = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(
    ImageSource source, [
    CameraDevice camera = CameraDevice.rear,
  ]) async {
    final xFile = await _picker.pickImage(
      source: source,
      preferredCameraDevice: camera,
      imageQuality: 90,
    );
    if (xFile != null && mounted) {
      setState(() => _capturedImage = File(xFile.path));
    }
  }

  void _proceed() {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please capture or select a photo first',
            style: GoogleFonts.plusJakartaSans(fontSize: 14),
          ),
          backgroundColor: const Color(0xFFE40101),
        ),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MemberIdScreen(photoFile: _capturedImage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final sw = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera preview area (black bg + face guide) ──────────────────
            Positioned.fill(
              child: _capturedImage != null
                  ? Image.file(_capturedImage!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF111111)),
            ),

            // ── Face guide overlay ───────────────────────────────────────────
            if (_capturedImage == null)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topPad + 60),
                    Text(
                      'Photo ID Card',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Position your face inside the frame',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Face guide rectangle — Figma 347px wide
                    _FaceGuideFrame(size: sw * 0.78),
                  ],
                ),
              ),

            // ── Captured photo: re-take prompt ──────────────────────────────
            if (_capturedImage != null)
              Positioned(
                top: topPad + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Photo ready! Tap "Use Photo" or retake',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Back button ─────────────────────────────────────────────────
            Positioned(
              top: topPad + 14,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),

            // ── Flash toggle ────────────────────────────────────────────────
            Positioned(
              top: topPad + 14,
              right: 16,
              child: GestureDetector(
                onTap: () => setState(() => _flashOn = !_flashOn),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    _flashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _flashOn ? const Color(0xFFFFCA00) : Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ),

            // ── Bottom action sheet ──────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(32, 28, 32, 28 + bottomPad),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: _capturedImage == null
                    ? _CaptureActions(
                        onGallery: () => _pickImage(ImageSource.gallery),
                        onCapture: () =>
                            _pickImage(ImageSource.camera, CameraDevice.front),
                        onFlash: () => setState(() => _flashOn = !_flashOn),
                        flashOn: _flashOn,
                      )
                    : _UsePhotoActions(
                        onRetake: () => setState(() => _capturedImage = null),
                        onUse: _proceed,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Face guide frame widget ──────────────────────────────────────────────────

class _FaceGuideFrame extends StatelessWidget {
  final double size;
  const _FaceGuideFrame({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.2,
      child: CustomPaint(
        painter: _FaceFramePainter(),
        child: Center(
          child: Container(
            width: size * 0.55,
            height: size * 0.55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 28.0;
    const r = 12.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Draw rounded corner brackets
    _drawCorner(canvas, paint, rect.topLeft, cornerLen, r, 0);
    _drawCorner(canvas, paint, rect.topRight, cornerLen, r, 1);
    _drawCorner(canvas, paint, rect.bottomLeft, cornerLen, r, 2);
    _drawCorner(canvas, paint, rect.bottomRight, cornerLen, r, 3);
  }

  void _drawCorner(Canvas canvas, Paint paint, Offset origin,
      double len, double r, int corner) {
    // corner: 0=TL, 1=TR, 2=BL, 3=BR
    final path = Path();
    final double sx = (corner == 1 || corner == 3) ? -1 : 1;
    final double sy = (corner == 2 || corner == 3) ? -1 : 1;

    path.moveTo(origin.dx + sx * len, origin.dy);
    path.lineTo(origin.dx + sx * r, origin.dy);
    path.quadraticBezierTo(origin.dx, origin.dy, origin.dx, origin.dy + sy * r);
    path.lineTo(origin.dx, origin.dy + sy * len);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Capture actions (before photo taken) ────────────────────────────────────

class _CaptureActions extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onFlash;
  final bool flashOn;

  const _CaptureActions({
    required this.onGallery,
    required this.onCapture,
    required this.onFlash,
    required this.flashOn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Take your photo',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Make sure your face is clearly visible and well-lit',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.black45,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Gallery — 48px icon
            GestureDetector(
              onTap: onGallery,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: const Icon(Icons.photo_library_outlined,
                        size: 22, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gallery',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Capture — 96px red button
            GestureDetector(
              onTap: onCapture,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE40101),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE40101).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 36),
              ),
            ),

            // Flash — 48px icon
            GestureDetector(
              onTap: onFlash,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: flashOn
                          ? const Color(0xFFFFF8E1)
                          : const Color(0xFFF5F5F5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: flashOn
                            ? const Color(0xFFFFCA00)
                            : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Icon(
                      flashOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      size: 22,
                      color: flashOn
                          ? const Color(0xFFFFCA00)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Flash',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Use photo actions (after photo taken) ────────────────────────────────────

class _UsePhotoActions extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const _UsePhotoActions({required this.onRetake, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Use this photo?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your photo will appear on your TVK member ID card',
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onRetake,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Retake',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onUse,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE40101),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE40101).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Use Photo',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
