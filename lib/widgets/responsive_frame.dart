import 'package:flutter/material.dart';

/// Keeps the app readable on every screen:
/// - limits very large or very small font settings so layouts do not break;
/// - on tablets and large screens, shows the app in a centered column
///   so buttons and fields do not stretch across the screen.
class ResponsiveFrame extends StatelessWidget {
  const ResponsiveFrame({super.key, required this.child});

  final Widget child;

  static const double maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final scaled = mq.copyWith(
      textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
    );
    if (mq.size.width <= maxWidth + 40) {
      return MediaQuery(data: scaled, child: child);
    }
    return ColoredBox(
      color: const Color(0xFFE8EBF3),
      child: Center(
        child: Container(
          width: maxWidth,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24)],
          ),
          child: MediaQuery(
            data: scaled.copyWith(size: Size(maxWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}