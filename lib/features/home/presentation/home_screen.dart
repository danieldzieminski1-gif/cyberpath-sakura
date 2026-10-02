import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../content/data/content_repository.dart';
import '../../live/data/live_repository.dart';
import '../../progress/application/providers.dart';
import '../../progress/domain/progress.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final due = ref.watch(dueCardsProvider).length;
    ref.watch(contentRevisionProvider); // rebuild when remote lessons arrive
    ref.watch(lessonSyncProvider); // kicks off background lesson sync (fails silently offline)
    final next = nextLesson(p.completed);
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: Sakura.pink,
          backgroundColor: Sakura.midnightHi,
          onRefresh: () async {
            ref.invalidate(lessonSyncProvider);
            ref.invalidate(liveFeedProvider);
            await ref.read(liveFeedProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_greeting()} ✿', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('Ready to build real skills?', style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                  ]),
                ),
                IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: () => context.push('/search')),
              ]).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06),
              const SizedBox(height: 16),
              AppCard(
                glow: true,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('Level ${p.level}', style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${p.xp} XP', style: t.textTheme.titleMedium?.copyWith(color: t.colorScheme.primary)),
                  ]),
                  const SizedBox(height: 12),
                  Semantics(
                    label: 'Level progress',
                    value: '${(ProgressEngine.levelProgress(p.xp) * 100).round()} percent',
                    child: LinearProgressIndicator(value: ProgressEngine.levelProgress(p.xp), minHeight: 10, borderRadius: BorderRadius.circular(10)),
                  ),
                  const SizedBox(height: 10),
                  Text('${p.streak}-day streak · ${p.completed.length} lessons done', style: t.textTheme.bodySmall),
                ]),
              ).animate().fadeIn(duration: 400.ms, delay: 60.ms).slideY(begin: 0.06),
              const SectionTitle('Continue'),
              if (next != null)
                AppCard(
                  onTap: () => context.push('/lesson/${next.id}'),
                  child: Row(children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: Sakura.glowGradient),
                      child: const Icon(Icons.play_arrow_rounded, size: 32, color: Sakura.midnight),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(next.title, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${next.summary} · ${next.minutes} min', style: t.textTheme.bodySmall),
                      ]),
                    ),
                  ]),
                ).animate().fadeIn(duration: 400.ms, delay: 120.ms).slideY(begin: 0.06)
              else
                const AppCard(child: Text('You finished every lesson. Keep sharp with Review and the Terminal Lab.')),
              const SectionTitle('Today'),
              AppCard(
                onTap: () => context.go('/review'),
                child: Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: t.colorScheme.secondary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(due == 0 ? 'No cards due. Nice work.' : '$due flashcards ready to review')),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
              _ThreatPulse(),
              const SectionTitle('Quick actions'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  _Action('Terminal Lab', Icons.terminal_rounded, () => context.push('/terminal')),
                  _Action('Glossary', Icons.abc_rounded, () => context.push('/glossary')),
                  _Action('Notes', Icons.sticky_note_2_outlined, () => context.push('/notes')),
                  _Action('Quick Quiz', Icons.bolt_rounded, () => context.push('/lesson/quick')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Live cyber news + CISA "recently exploited" list, with offline fallbacks.
class _ThreatPulse extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(liveFeedProvider);
    final t = Theme.of(context);
    Widget pill = const SizedBox.shrink();
    final data = feed.valueOrNull;
    if (data != null) {
      if (data.isLive) {
        pill = const StatusPill(label: 'LIVE', color: Color(0xFF8EE3C2), icon: Icons.wifi_tethering_rounded);
      } else if (data.updatedAt != null) {
        pill = StatusPill(label: 'CACHED · ${timeAgo(data.updatedAt)}', color: Sakura.lavender, icon: Icons.history_rounded);
      } else {
        pill = const StatusPill(label: 'OFFLINE', color: Sakura.peach, icon: Icons.cloud_off_rounded);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle('Threat Pulse', trailing: pill),
      if (data == null)
        const AppCard(child: Column(children: [SkeletonLine(), SkeletonLine(width: 220), SkeletonLine(width: 160)]))
      else ...[
        if (data.kev.isNotEmpty) ...[
          AppCard(
            glow: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.local_fire_department_rounded, size: 18, color: t.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Newly exploited in the wild', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              for (final k in data.kev.take(3)) _NewsTile(k, dense: true),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: [for (final n in data.items.take(5)) _NewsTile(n)]),
        ),
      ],
    ]).animate().fadeIn(duration: 400.ms, delay: 180.ms);
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile(this.item, {this.dense = false});
  final NewsItem item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final meta = [item.source, if (item.at != null) timeAgo(item.at)].where((e) => e.isNotEmpty).join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: item.url.isEmpty ? null : () => openExternal(item.url),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 6 : 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: item.tag == 'EXPLOITED' ? Sakura.peach : Sakura.pink, boxShadow: [BoxShadow(color: Sakura.pink.withAlpha(150), blurRadius: 8)]),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              if (item.subtitle.isNotEmpty) Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
              if (meta.isNotEmpty) Text(meta, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.secondary)),
            ]),
          ),
          if (item.url.isNotEmpty) Icon(Icons.north_east_rounded, size: 16, color: t.colorScheme.primary),
        ]),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 10), Expanded(child: Text(label))]),
      );
}
