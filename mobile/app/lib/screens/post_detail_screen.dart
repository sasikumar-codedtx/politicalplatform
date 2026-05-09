import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostDetailScreen extends StatefulWidget {
  final String author;
  final String role;
  final String text;
  final bool hasImage;
  final String date;

  const PostDetailScreen({
    super.key,
    required this.author,
    required this.role,
    required this.text,
    required this.hasImage,
    required this.date,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _liked = false;
  int _likeCount = 128;

  static final _mockComments = [
    _Comment(author: 'Ravi Kumar', role: 'Member', text: 'Very inspiring! TVK is the future of Tamil Nadu.', time: '2h ago'),
    _Comment(author: 'Priya S', role: 'Volunteer', text: 'Absolutely agree. We need this change now!', time: '3h ago'),
    _Comment(author: 'Murugan TN', role: 'Member', text: 'நம்ம தலைவர் வாழ்க! TVK வாழ்க!', time: '4h ago'),
    _Comment(author: 'Senthil K', role: 'Supporter', text: 'This post is so true. Sharing this with everyone I know.', time: '5h ago'),
    _Comment(author: 'Kavitha R', role: 'Volunteer', text: 'Great content. Keep posting updates like this.', time: '6h ago'),
  ];

  final _comments = List<_Comment>.from(_mockComments);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _comments.insert(0, _Comment(author: 'You', role: 'Member', text: text, time: 'Just now'));
      _commentController.clear();
    });
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text('Post', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                const Spacer(),
                const Icon(Icons.more_horiz_rounded, color: Colors.black54, size: 22),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEEEE)),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Post card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Post header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.author, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), letterSpacing: 0.2)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(widget.role, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF1A1A1A))),
                                      const SizedBox(width: 8),
                                      Text('· ${widget.date}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFE40101), borderRadius: BorderRadius.circular(6)),
                              child: Text('Follow', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Post text
                        Text(widget.text, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF1A1A1A), height: 1.6)),
                        const SizedBox(height: 14),
                        // Post image
                        if (widget.hasImage)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: double.infinity,
                              height: 220,
                              child: Image.asset('assets/images/event_2.png', fit: BoxFit.cover),
                            ),
                          ),
                        const SizedBox(height: 14),
                        // Action row
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() { _liked = !_liked; _likeCount += _liked ? 1 : -1; }),
                              child: Row(
                                children: [
                                  Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: _liked ? const Color(0xFFE40101) : Colors.black54),
                                  const SizedBox(width: 5),
                                  Text('$_likeCount', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Colors.black54),
                                const SizedBox(width: 5),
                                Text('${_comments.length}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                            const SizedBox(width: 20),
                            const Icon(Icons.repeat_rounded, size: 20, color: Colors.black54),
                            const Spacer(),
                            const Icon(Icons.ios_share_rounded, size: 20, color: Colors.black54),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Comments header
                  Text('Comments (${_comments.length})', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 12),
                  // Comments list
                  ..._comments.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CommentItem(comment: c),
                  )),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Comment input bar
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10 + bottomPad),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF333333), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _commentController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF1A1A1A)),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Write a comment...',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(color: Color(0xFFE40101), shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final _Comment comment;
  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.person_rounded, color: Colors.black38, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(comment.author, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                        const SizedBox(width: 6),
                        Text('· ${comment.role}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(comment.text, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.black54, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(comment.time, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black38)),
                  const SizedBox(width: 16),
                  Text('Like', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(width: 16),
                  Text('Reply', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Comment {
  final String author;
  final String role;
  final String text;
  final String time;
  const _Comment({required this.author, required this.role, required this.text, required this.time});
}
