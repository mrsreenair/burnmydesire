import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/user_prefs.dart';
import '../providers/db_providers.dart';
import '../providers/pro_provider.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/milestone_card.dart';
import '../widgets/ember_ui.dart';
import '../utils/math_utils.dart';
import 'paywall_screen.dart';

/// Pro analytics: total protected, real-market projection, resistance
/// stats, weak spots, and per-item history (PROJECT.md F6).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(dashboardUnlockedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your wealth'), automaticallyImplyLeading: false),
      body: unlocked ? const _Dashboard() : const _LockedView(),
    );
  }
}

class _LockedView extends StatelessWidget {
  const _LockedView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '📈',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'See your wealth grow',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Projections, resistance streaks, and your full burn '
              'history are part of Pro.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () => Navigator.of(
                context,
              ).push(emberRoute(const PaywallScreen())),
              child: const Text('Go Pro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final items = ref.watch(itemsProvider).value ?? const <Item>[];
    final live = ref.watch(liveItemsProvider);
    final protected = ref.watch(protectedCentsProvider);
    final market = ref.watch(marketDataProvider).value;
    final categories = ref.watch(spendCategoriesProvider).value ?? const [];
    final goalIds = ref.watch(burnGoalsProvider).value ?? const [];

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Nothing burned yet.\nYour protected wealth shows up here '
            'after your first burn.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final purchases = items.where((i) => i.category != 'emotion').length;
    final thoughts = items.length - purchases;
    final strongest = items.reduce(
      (a, b) => a.resistanceCount >= b.resistanceCount ? a : b,
    );

    final fund = market?.funds.first;
    final targetYear = DateTime.now().year + kDefaultHorizonYears;
    final projected = fund?.projectedValueCents(
      protected,
      kDefaultHorizonYears,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
      children: [
        if (protected > 0)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Wealth protected', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.wealthGradient.createShader(b),
                    blendMode: BlendMode.srcIn,
                    child: CountUpText(
                      protected,
                      formatter: formatEuros,
                      style: theme.textTheme.displayMedium,
                    ),
                  ),
                  if (fund != null && projected != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Invested today, that could be '
                      '${formatEuros(projected)} by $targetYear at the '
                      '${fund.name}\'s real ${fund.yearsAvailable}-year '
                      'average (${(fund.fullHistoryCagr * 100).toStringAsFixed(1)}%/yr).',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (protected > 0) ...[
          const SizedBox(height: 12),
          _ShareMilestone(protectedCents: protected, burns: items.length),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _StatTile(label: 'Purchases resisted', value: '$purchases'),
            const SizedBox(width: 12),
            _StatTile(label: 'Thoughts burned', value: '$thoughts'),
            const SizedBox(width: 12),
            _StatTile(
              label: 'Best streak',
              value: '${strongest.resistanceCount}×',
            ),
          ],
        ),
        if (goalIds.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'What you\'re burning',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (id, label, emoji) in burnGoals)
                if (goalIds.contains(id)) Chip(label: Text('$emoji $label')),
            ],
          ),
        ],
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Your spending weak spots',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in categories)
                Chip(label: Text('${_emojiFor(label)} $label')),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Burn history',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in live) _ItemTile(item: item),
        const SizedBox(height: 16),
        Text(
          'Projections assume historical average returns repeat. Past '
          'performance doesn\'t guarantee future results. Not investment '
          'advice.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _emojiFor(String label) {
    for (final (name, emoji) in spendCategories) {
      if (name == label) return emoji;
    }
    return '✨';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(imageStoreProvider);
    final theme = Theme.of(context);
    final when = item.lastBurnedAt ?? item.createdAt;
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            store.file(item.imageFile),
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.image_outlined),
            ),
          ),
        ),
        title: Text(
          item.category == 'emotion'
              ? 'A thought you let go'
              : '${formatEuros(item.priceCents)} protected',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          'Resisted ${item.resistanceCount}× · last burn '
          '${DateFormat.yMMMd().format(when)}',
        ),
      ),
    );
  }
}

/// The viral loop: the effect is the ad, so make the win trivially
/// shareable — without ever revealing what was resisted.
class _ShareMilestone extends StatefulWidget {
  const _ShareMilestone({required this.protectedCents, required this.burns});

  final int protectedCents;
  final int burns;

  @override
  State<_ShareMilestone> createState() => _ShareMilestoneState();
}

class _ShareMilestoneState extends State<_ShareMilestone> {
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final bytes = await renderMilestoneCard(
        protectedCents: widget.protectedCents,
        burns: widget.burns,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/burn-my-desire-milestone.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'I protected ${formatEuros(widget.protectedCents)} by '
              'burning what I wanted instead of buying it.',
        ),
      );
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t create the card.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _share,
      icon: const Icon(Icons.ios_share, size: 18),
      label: Text(_busy ? 'Preparing…' : 'Share this win'),
    );
  }
}
