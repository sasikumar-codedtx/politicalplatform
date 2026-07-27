import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../config/app_colors.dart';
import '../services/fan_post_service.dart';
import '../services/profile_service.dart';

class CreateFanPostScreen extends StatefulWidget {
  const CreateFanPostScreen({super.key});

  @override
  State<CreateFanPostScreen> createState() => _CreateFanPostScreenState();
}

class _CreateFanPostScreenState extends State<CreateFanPostScreen> {
  final _textController = TextEditingController();
  final _nameController = TextEditingController();
  File? _attachment;
  String? _attachmentName;
  bool _submitting = false;

  String get _userName {
    final n = _nameController.text.trim();
    return n.isEmpty ? 'TVK Member' : n;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
    _nameController.addListener(() => setState(() {}));
    // Prefill the name from the saved profile when available.
    final saved = ProfileService.displayName.value;
    if (saved.trim().isNotEmpty && saved != 'Member') _nameController.text = saved;
  }

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.media, // images + videos
      withData: false,
    );
    final path = res?.files.single.path;
    if (path != null) {
      setState(() {
        _attachment = File(path);
        _attachmentName = res!.files.single.name;
      });
    }
  }

  bool get _canPost =>
      _textController.text.trim().isNotEmpty || _attachment != null;

  Future<void> _submit() async {
    if (!_canPost || _submitting) return;
    setState(() => _submitting = true);

    await FanPostService.createPost(
      text: _textController.text.trim(),
      userName: _userName,
      file: _attachment,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post published!', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: const Color(0xFF388E3C),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _canPost;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Create Post',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: hasText ? _submit : null,
            child: Text(
              'Post',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: hasText
                    ? const Color(0xFFE40101)
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name — shown as the poster (not the phone number)
                  Text(
                    'Your Name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 15, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE40101)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 8,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Add Photo or Video (optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_attachment == null)
                    GestureDetector(
                      onTap: _pickAttachment,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.add_photo_alternate_outlined,
                                size: 30, color: Color(0xFFE40101)),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to attach an image or video',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _AttachmentPreview(
                      file: _attachment!,
                      name: _attachmentName ?? 'attachment',
                      onRemove: () => setState(() {
                        _attachment = null;
                        _attachmentName = null;
                      }),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: hasText && !_submitting ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE40101),
                    disabledBackgroundColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Post',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final File file;
  final String name;
  final VoidCallback onRemove;
  const _AttachmentPreview(
      {required this.file, required this.name, required this.onRemove});

  bool get _isImage {
    final n = name.toLowerCase();
    return n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png') ||
        n.endsWith('.gif') || n.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _isImage
                ? Image.file(file, width: 54, height: 54, fit: BoxFit.cover)
                : Container(
                    width: 54, height: 54,
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.videocam_rounded,
                        color: Color(0xFFE40101)),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
