import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:malclient/src/core/providers.dart';
import 'package:malclient/src/data/models/media.dart';
import 'package:malclient/src/widgets/poster_card.dart';
import 'package:malclient/src/widgets/section_widgets.dart';

const _weekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

String _shortDay(String day) => switch (day) {
      'monday' => 'Mon',
      'tuesday' => 'Tue',
      'wednesday' => 'Wed',
      'thursday' => 'Thu',
      'friday' => 'Fri',
      'saturday' => 'Sat',
      'sunday' => 'Sun',
      _ => day,
    };

/// Schedule tab: weekday selector + airing timeline cards with countdowns.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late String _day;

  @override
  void initState() {
    super.initState();
    _day = _weekdays[DateTime.now().weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final seasonal = ref.watch(seasonalAnimeProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Airing Schedule',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _weekdays.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = _weekdays[i];
                  final selected = d == _day;
                  return Center(
                    child: ChoiceChip(
                      label: Text(_shortDay(d)),
                      selected: selected,
                      onSelected: (_) => setState(() => _day = d),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: seasonal.when(
                data: (items) {
                  final dayItems = items
                      .where((a) => a.broadcastDay == _day)
                      .toList();
                  if (dayItems.isEmpty) {
                    return Center(
                      child: Text(
                        'Nothing scheduled for ${_shortDay(_day)}.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: dayItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) =>
                        _ScheduleCard(anime: dayItems[i]),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => AsyncSection.error(
                  error: e,
                  onRetry: () => ref.invalidate(seasonalAnimeProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final AnimeSummary anime;

  const _ScheduleCard({required this.anime});

  /// Time until the next episode, based on broadcast day/time.
  /// Null when the schedule info is missing.
  Duration? _countdown() {
    if (anime.broadcastDay == null) return null;
    final targetWeekday = _weekdays.indexOf(anime.broadcastDay!) + 1; // Mon=1
    if (targetWeekday < 1) return null;
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    var delta = (targetWeekday - now.weekday) % 7;
    day = day.add(Duration(days: delta));
    final parts = (anime.broadcastTime ?? '00:00').split(':');
    final h = (int.tryParse(parts[0]) ?? 0) % 24;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    var airing = DateTime(day.year, day.month, day.day, h, m);
    if (!airing.isAfter(now)) airing = airing.add(const Duration(days: 7));
    return airing.difference(now);
  }

  static String _fmt(Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final countdown = _countdown();

    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/detail/anime/${anime.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              PosterImage(
                url: anime.imageUrl,
                title: anime.title,
                width: 64,
                height: 92,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (anime.studio != null)
                      Text(
                        anime.studio!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: scheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          countdown != null
                              ? 'Ep in ${_fmt(countdown)}'
                              : (anime.broadcastTime ?? 'Time TBA'),
                          style: textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        ScoreBadge(
                          mean: anime.mean,
                          members: anime.numListUsers,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
