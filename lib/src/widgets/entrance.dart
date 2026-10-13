import 'package:flutter/material.dart';

/// Fade + slide-up entrance animation, staggered by [index].
///
/// Plays once when first built. ListView reuses element state while
/// scrolling, so items that already animated do not replay.
class Entrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;
  final double slideDistance;

  const Entrance({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.slideDistance = 0.12,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = _controller;
    _offset = Tween<Offset>(
      begin: Offset(0, widget.slideDistance),
      end: Offset.zero,
    ).animate(curve);
    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
