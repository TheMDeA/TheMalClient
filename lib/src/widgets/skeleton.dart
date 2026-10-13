import 'package:flutter/material.dart';

/// Pulsing skeleton placeholder for loading states.
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}

/// Skeleton mimicking a My List row.
class SkeletonListRow extends StatelessWidget {
  const SkeletonListRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(
              width: 64,
              height: 92,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 180, height: 14),
                  const SizedBox(height: 6),
                  const Skeleton(width: 220, height: 18),
                  const SizedBox(height: 6),
                  const Skeleton(width: 140, height: 12),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Skeleton(width: 60, height: 16),
                      Spacer(),
                      Skeleton(width: 32, height: 32,
                          borderRadius:
                              BorderRadius.all(Radius.circular(16))),
                      SizedBox(width: 8),
                      Skeleton(width: 32, height: 32,
                          borderRadius:
                              BorderRadius.all(Radius.circular(16))),
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

/// Skeleton mimicking a poster grid.
class SkeletonPosterGrid extends StatelessWidget {
  final int count;

  const SkeletonPosterGrid({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Skeleton(
              width: double.infinity,
              borderRadius:
                  BorderRadius.all(Radius.circular(12)),
            ),
          ),
          SizedBox(height: 6),
          Skeleton(width: double.infinity, height: 12),
        ],
      ),
    );
  }
}
