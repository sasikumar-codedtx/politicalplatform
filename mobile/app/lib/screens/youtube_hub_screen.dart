import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/youtube_video.dart';
import '../models/youtube_playlist.dart';
import '../services/youtube_service.dart';
import 'video_player_screen.dart';
import 'shorts_reel_screen.dart';
import 'playlist_detail_screen.dart';

class YoutubeHubScreen extends StatefulWidget {
  /// 0 = Live, 1 = Videos, 2 = Shorts, 3 = Playlists
  final int initialTab;

  const YoutubeHubScreen({super.key, this.initialTab = 0});

  @override
  State<YoutubeHubScreen> createState() => _YoutubeHubScreenState();
}

class _YoutubeHubScreenState extends State<YoutubeHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = ['Live', 'Videos', 'Shorts', 'Playlists'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _Header(topPad: topPad)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                labelColor: const Color(0xFFE40101),
                unselectedLabelColor: const Color(0xFF555555),
                indicatorColor: const Color(0xFFE40101),
                indicatorWeight: 2.5,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                isScrollable: false,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _LiveTab(),
            _VideosTab(),
            _ShortsTab(),
            _PlaylistsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double topPad;
  const _Header({required this.topPad});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220 + topPad,
      child: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            child: SizedBox(
              height: 220 + topPad,
              child: Image.asset(
                'assets/images/tvk_flag.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.4, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Back button
          Positioned(
            top: 16 + topPad,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          // Title block
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE40101), Color(0xFF7E0101)],
                  ).createShader(bounds),
                  child: Text(
                    'TVK VIDEOS',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 34,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Official channel — Live streams, videos & shorts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white,
                    height: 1.4,
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

// ─── Sticky tab-bar delegate ──────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: Colors.white,
      elevation: overlapsContent ? 2 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => old.tabBar != tabBar;
}

// ─── Live Tab ─────────────────────────────────────────────────────────────────

class _LiveTab extends StatefulWidget {
  const _LiveTab();

  @override
  State<_LiveTab> createState() => _LiveTabState();
}

class _LiveTabState extends State<_LiveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  YouTubeVideo? _liveVideo;
  YouTubeVideo? _upcomingVideo;
  YouTubeVideo? _recentVideo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final live = await YouTubeService.getLiveStream();
    final upcoming = live == null ? await YouTubeService.getUpcomingLive() : null;
    final recent = (live == null)
        ? await YouTubeService.getVideos(count: 1).then(
            (v) => v.isNotEmpty ? v.first : null)
        : null;
    if (mounted) {
      setState(() {
        _liveVideo = live;
        _upcomingVideo = upcoming;
        _recentVideo = recent;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE40101),
          strokeWidth: 2,
        ),
      );
    }

    if (_liveVideo != null) {
      return _LivePlayerSection(video: _liveVideo!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_upcomingVideo != null) ...[
            _UpcomingCard(video: _upcomingVideo!),
            const SizedBox(height: 20),
          ],
          if (_recentVideo != null) ...[
            Text(
              'Most Recent Video',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            _VideoCard(video: _recentVideo!),
          ],
          if (_upcomingVideo == null && _recentVideo == null)
            _OfflineCard(),
        ],
      ),
    );
  }
}

class _LivePlayerSection extends StatefulWidget {
  final YouTubeVideo video;
  const _LivePlayerSection({required this.video});

  @override
  State<_LivePlayerSection> createState() => _LivePlayerSectionState();
}

class _LivePlayerSectionState extends State<_LivePlayerSection> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
        forceHD: false,
        isLive: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: false,
        progressIndicatorColor: const Color(0xFFE40101),
      ),
      builder: (context, player) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              player,
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE40101),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.video.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.video.channelTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final YouTubeVideo video;
  const _UpcomingCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE40101).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              color: Color(0xFFE40101),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Live',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFFE40101),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  video.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Set a reminder',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.notifications_outlined,
            color: Color(0xFFE40101),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _OfflineCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          const Icon(Icons.live_tv_outlined, size: 40, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            'Not live right now',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check the Videos tab for recent content.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Videos Tab ───────────────────────────────────────────────────────────────

class _VideosTab extends StatefulWidget {
  const _VideosTab();

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<YouTubeVideo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final videos = await YouTubeService.getVideos(count: 20);
    if (mounted) setState(() { _videos = videos; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE40101),
          strokeWidth: 2,
        ),
      );
    }
    if (_videos.isEmpty) {
      return Center(
        child: Text(
          'No videos available.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videos.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _VideoCard(video: _videos[index]),
      ),
    );
  }
}

// ─── Shorts Tab ───────────────────────────────────────────────────────────────

class _ShortsTab extends StatefulWidget {
  const _ShortsTab();

  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<_ShortsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<YouTubeVideo> _shorts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shorts = await YouTubeService.getShorts(count: 20);
    if (mounted) setState(() { _shorts = shorts; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE40101),
          strokeWidth: 2,
        ),
      );
    }
    if (_shorts.isEmpty) {
      return Center(
        child: Text(
          'No shorts available.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      );
    }

    // 2-column portrait grid — each card is 9:16 aspect ratio
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 9 / 16,
      ),
      itemCount: _shorts.length,
      itemBuilder: (context, index) => _ShortCard(
        video: _shorts[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShortsReelScreen(
              videos: _shorts,
              initialIndex: index,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Playlists Tab ────────────────────────────────────────────────────────────

class _PlaylistsTab extends StatefulWidget {
  const _PlaylistsTab();

  @override
  State<_PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<_PlaylistsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<YouTubePlaylist> _playlists = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final playlists = await YouTubeService.getPlaylists(maxResults: 20);
    if (mounted) setState(() { _playlists = playlists; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE40101),
          strokeWidth: 2,
        ),
      );
    }
    if (_playlists.isEmpty) {
      return Center(
        child: Text(
          'No playlists available.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _playlists.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _PlaylistCard(playlist: _playlists[index]),
      ),
    );
  }
}

// ─── Shared card widgets ──────────────────────────────────────────────────────

// Landscape 16:9 video card (used in Live fallback + Videos tab)
class _VideoCard extends StatelessWidget {
  final YouTubeVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(video: video),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 40,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                      loadingBuilder: (_, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFFEEEEEE),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFE40101),
                                    ),
                                  ),
                                ),
                    ),
                    if (video.isLive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE40101),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LIVE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info row
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          video.channelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        video.formattedDate,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Portrait 9:16 short card (Shorts tab grid)
class _ShortCard extends StatelessWidget {
  final YouTubeVideo video;
  final VoidCallback onTap;
  const _ShortCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, e, s) => Container(
                color: const Color(0xFFEEEEEE),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 32,
                  color: Color(0xFFCCCCCC),
                ),
              ),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Container(
                      color: const Color(0xFFEEEEEE),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE40101),
                        ),
                      ),
                    ),
            ),
            // Bottom gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 90,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
            ),
            // Play button
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE40101).withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            // Title at bottom
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                video.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final YouTubePlaylist playlist;
  const _PlaylistCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistDetailScreen(playlist: playlist),
        ),
      ),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 100,
              height: 64,
              child: playlist.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      playlist.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, e, s) => Container(
                        color: const Color(0xFFEEEEEE),
                        child: const Icon(
                          Icons.playlist_play_rounded,
                          color: Colors.black26,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFEEEEEE),
                      child: const Icon(
                        Icons.playlist_play_rounded,
                        color: Colors.black26,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${playlist.videoCount} videos',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFFE40101),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '·',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      playlist.formattedDate,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.black38,
            size: 20,
          ),
        ],
      ),
    ),
    );
  }
}
