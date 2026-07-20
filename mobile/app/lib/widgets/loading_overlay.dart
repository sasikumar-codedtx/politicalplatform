import 'package:flutter/material.dart';

/// Wraps [child] and shows a dimmed spinner on top while [isLoading] is true.
/// Reuse on any screen that fetches data so loading is visible, not frozen.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({super.key, required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.12),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF9F1D1F)),
              ),
            ),
          ),
      ],
    );
  }
}
