import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network poster with a warm gradient fallback (title initial) so a
/// missing/stale image URL never shows a broken-image icon.
class PosterImage extends StatelessWidget {
  final String? url;
  final String title;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const PosterImage({
    super.key,
    required this.url,
    required this.title,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.surfaceContainerHighest,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          title.isEmpty ? '?' : title[0].toUpperCase(),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ),
    );

    if (url == null || url!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: borderRadius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}

/// Compact "8.71 | 2.31M" style badge, DailyAL-like.
class ScoreBadge extends StatelessWidget {
  final double? mean;
  final int? members;

  const ScoreBadge({super.key, this.mean, this.members});

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    if (mean == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text =
        members != null ? '${mean!.toStringAsFixed(2)} | ${_compact(members!)}' : mean!.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}

/// Red rank badge ("#1").
class RankBadge extends StatelessWidget {
  final int? rank;

  const RankBadge({super.key, this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD84A4A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$rank',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Poster card used in rails and grids: poster + badges + title.
class PosterCard extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final double? mean;
  final int? members;
  final int? rank;
  final double width;
  final VoidCallback? onTap;

  const PosterCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.mean,
    this.members,
    this.rank,
    this.width = 140,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AspectRatio instead of height = width * 1.42: the width can be
            // double.infinity (grids), which made the height infinite and the
            // poster render blank.
            AspectRatio(
              aspectRatio: 1 / 1.42,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PosterImage(
                      url: imageUrl,
                      title: title,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: ScoreBadge(mean: mean, members: members),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: RankBadge(rank: rank),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
