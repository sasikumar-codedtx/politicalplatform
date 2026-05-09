import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _textController = TextEditingController();
  bool _imageAttached = false;
  String _selectedVisibility = 'Everyone';
  static const _visibilityOptions = ['Everyone', 'Members Only', 'Volunteers Only'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _canPost => _textController.text.trim().isNotEmpty;

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
                    child: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Create Post', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const Spacer(),
                GestureDetector(
                  onTap: _canPost ? _submit : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: _canPost ? const Color(0xFFE40101) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Post', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: _canPost ? Colors.white : Colors.black38)),
                  ),
                ),
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
                  // Author info
                  Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TVK Member', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                          const SizedBox(height: 4),
                          // Visibility selector
                          GestureDetector(
                            onTap: _showVisibilityPicker,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.public_rounded, size: 12, color: Colors.black54),
                                  const SizedBox(width: 4),
                                  Text(_selectedVisibility, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Text field
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    minLines: 5,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, color: const Color(0xFF1A1A1A), height: 1.6),
                    decoration: InputDecoration.collapsed(
                      hintText: "What's on your mind? Share an update, opinion or announcement...",
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 16, color: Colors.black38, height: 1.6),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  // Attached image preview
                  if (_imageAttached)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: Image.asset('assets/images/event_2.png', fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _imageAttached = false),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Bottom toolbar
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12 + bottomPad),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                Text('Add to post:', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black38)),
                const SizedBox(width: 16),
                _ToolbarBtn(icon: Icons.image_outlined, label: 'Photo', onTap: () => setState(() => _imageAttached = true)),
                const SizedBox(width: 16),
                _ToolbarBtn(icon: Icons.location_on_outlined, label: 'Location', onTap: () {}),
                const SizedBox(width: 16),
                _ToolbarBtn(icon: Icons.tag_rounded, label: 'Tag', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVisibilityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Who can see this?', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
            const SizedBox(height: 16),
            ..._visibilityOptions.map((opt) => GestureDetector(
              onTap: () { setState(() => _selectedVisibility = opt); Navigator.pop(context); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text(opt, style: GoogleFonts.plusJakartaSans(fontSize: 15, color: const Color(0xFF1A1A1A))),
                    const Spacer(),
                    if (_selectedVisibility == opt) const Icon(Icons.check_rounded, color: Color(0xFFE40101), size: 18),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  void _submit() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post published!', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }
}
