import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fan_post.dart';
import '../services/fan_post_service.dart';

class CreateFanPostScreen extends StatefulWidget {
  const CreateFanPostScreen({super.key});

  @override
  State<CreateFanPostScreen> createState() => _CreateFanPostScreenState();
}

class _CreateFanPostScreenState extends State<CreateFanPostScreen> {
  final _textController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  int _selectedMediaChip = -1;
  bool _submitting = false;

  String get _userId =>
      FirebaseAuth.instance.currentUser?.phoneNumber ?? 'anonymous';

  String get _userName =>
      FirebaseAuth.instance.currentUser?.phoneNumber?.replaceAll('+91', '') ??
      'User';

  @override
  void initState() {
    super.initState();
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);

    PostMediaType mediaType = PostMediaType.none;
    String? mediaUrl;
    final urlText = _mediaUrlController.text.trim();
    if (_selectedMediaChip == 0 && urlText.isNotEmpty) {
      mediaType = PostMediaType.image;
      mediaUrl = urlText;
    } else if (_selectedMediaChip == 1 && urlText.isNotEmpty) {
      mediaType = PostMediaType.video;
      mediaUrl = urlText;
    }

    final post = FanPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId,
      userName: _userName,
      text: text,
      mediaType: mediaType,
      mediaUrl: mediaUrl,
      status: PostStatus.pending,
      createdAt: DateTime.now(),
    );

    await FanPostService.savePost(post);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Post submitted for review!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF388E3C),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasText = _textController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'Create Post',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
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
                    : Colors.black26,
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFE40101),
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Posting as $_userName',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 8,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: const Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        color: Colors.black38,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Add Media (optional)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MediaChip(
                        label: 'Image URL',
                        selected: _selectedMediaChip == 0,
                        onTap: () => setState(() {
                          _selectedMediaChip = _selectedMediaChip == 0 ? -1 : 0;
                          _mediaUrlController.clear();
                        }),
                      ),
                      const SizedBox(width: 10),
                      _MediaChip(
                        label: 'Video URL',
                        selected: _selectedMediaChip == 1,
                        onTap: () => setState(() {
                          _selectedMediaChip = _selectedMediaChip == 1 ? -1 : 1;
                          _mediaUrlController.clear();
                        }),
                      ),
                    ],
                  ),
                  if (_selectedMediaChip >= 0) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mediaUrlController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _selectedMediaChip == 0
                            ? 'Enter image URL...'
                            : 'Enter video URL...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: Colors.black38,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.black12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE40101)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFFF57F17),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your post will be reviewed before appearing on the community wall.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFFF57F17),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _MediaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MediaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE40101) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFFE40101) : Colors.black26,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
      ),
    );
  }
}
