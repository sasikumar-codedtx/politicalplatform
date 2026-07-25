import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _hideUI();
    _controller = VideoPlayerController.asset('assets/images/splashvideo.mov')
      ..initialize().then((_) {
        if (mounted) {
          // The video platform view can restore the bars as it attaches, so
          // hide them again once it is actually on screen.
          _hideUI();
          setState(() => _initialized = true);
          _controller.setLooping(false);
          _controller.setVolume(1.0);
          _controller.play();
          _controller.addListener(_onVideoUpdate);
        }
      }).catchError((_) {
        // If video fails to load, skip to next screen immediately
        widget.onComplete();
      });
  }

  void _onVideoUpdate() {
    if (!_controller.value.isPlaying &&
        _controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration) {
      _controller.removeListener(_onVideoUpdate);
      _restoreUI();
      widget.onComplete();
    }
  }

  /// Fully hides the status + navigation bars (no clock, wifi or battery over
  /// the splash video). immersiveSticky still flashes them on some devices.
  void _hideUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void _restoreUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _restoreUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAB0001),
      body: _initialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
