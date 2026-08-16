import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config.dart';
import '../data/database.dart';
import '../data/weekly_report.dart';
import '../providers/currency_provider.dart';
import '../providers/db_providers.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import '../widgets/tilt_card.dart';
import 'ash_report_screen.dart';

/// The memorial: every desire that reached its Final Burn. No photos —
/// they were deleted on purpose — just the ledger and the date it died.
///
/// Deliberately quiet. This page is a record of wins, not a gallery of
/// temptations, so nothing here should be able to restart a craving.
class AshesScreen extends ConsumerWidget {
  const AshesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final destroyed = ref.watch(destroyedItemsProvider);
    // Rebuild when the currency changes — this screen sits in the tab
    // stack, so nothing else would repaint its amounts.
    ref.watch(currencyProvider);
    final protectedForever = destroyed.fold(0, (s, i) => s + i.priceCents);
    final report = ref.watch(weeklyReportProvider);

    return Scaffold(
      body: PaperBackdrop(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
            children: [
              // komoot's archive header: big title, plain count beneath.
              Reveal(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ashes', style: theme.textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(
                      destroyed.isEmpty
                          ? 'Desires you ended forever'
                          : '${destroyed.length} '
                                '${destroyed.length == 1 ? 'desire' : 'desires'} '
                                'destroyed forever',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // The week, always reachable from here — the memorial is
              // the natural home for a look back (GROWTH.md M4).
              if (report != null && !report.isEmpty)
                Reveal(
                  delay: const Duration(milliseconds: 40),
                  child: _WeekCard(
                    report: report,
                    onTap: () async {
                      await markAshReportSeen(report.window);
                      ref.invalidate(ashReportSeenProvider);
                      if (context.mounted) {
                        await Navigator.of(
                          context,
                        ).push(emberRoute(const AshReportScreen()));
                      }
                    },
                  ),
                ),
              const SizedBox(height: 28),
              if (destroyed.isEmpty)
                const Reveal(
                  delay: Duration(milliseconds: 80),
                  child: _EmptyAshes(),
                )
              else ...[
                if (protectedForever > 0)
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: _ForeverCard(cents: protectedForever),
                  ),
                const SizedBox(height: 28),
                ..._buildGroups(context, destroyed),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Fetch-style period grouping: a month label, then that month's dead.
  List<Widget> _buildGroups(BuildContext context, List<Item> destroyed) {
    final byMonth = <String, List<Item>>{};
    for (final item in destroyed) {
      final when = item.destroyedAt ?? item.createdAt;
      byMonth
          .putIfAbsent(DateFormat('MMMM yyyy').format(when), () => [])
          .add(item);
    }

    final widgets = <Widget>[];
    var index = 0;
    for (final entry in byMonth.entries) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 24, bottom: 12),
          child: Text(
            entry.key.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMid,
            ),
          ),
        ),
      );
      for (final item in entry.value) {
        widgets.add(
          Reveal(
            delay: Duration(milliseconds: 120 + 50 * index++),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AshTile(item: item),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

/// This week (or last), in one row: count, money, and a chevron.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.report, required this.onTap});

  final WeeklyReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final n = report.burns;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.paperHigh,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow(opacity: 0.06),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ember.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_view_week_outlined,
                size: 20,
                color: AppColors.ember,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.window.label} in ashes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.protectedCents > 0
                        ? '$n ${n == 1 ? 'burn' : 'burns'} · '
                              '${formatMoney(report.protectedCents)} kept'
                        : '$n ${n == 1 ? 'burn' : 'burns'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMid),
          ],
        ),
      ),
    );
  }
}

/// The one number that makes the memorial worth visiting.
class _ForeverCard extends StatelessWidget {
  const _ForeverCard({required this.cents});

  final int cents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow(),
      ),
      child: Column(
        children: [
          Text('Protected forever', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ShaderMask(
            shaderCallback: (b) => AppColors.wealthGradient.createShader(b),
            blendMode: BlendMode.srcIn,
            child: CountUpText(
              cents,
              formatter: formatMoney,
              style: theme.textTheme.displayMedium,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'These desires can never tempt you again — their photos are '
            'gone. The money stays counted.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tombstone. Candle instead of a thumbnail: there is no image left,
/// and that is the point.
class _AshTile extends StatelessWidget {
  const _AshTile({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = item.destroyedAt ?? item.createdAt;
    final isThought = item.category == 'emotion';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paperHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.field,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🕯️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isThought
                      ? 'A thought, gone for good'
                      : '${formatMoney(item.priceCents)} protected forever',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15.5,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Resisted ${item.resistanceCount}× · '
                  '${DateFormat.MMMd().format(when)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAshes extends StatelessWidget {
  const _EmptyAshes();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const CardFan(
            cards: [
              Text('🕯️', style: TextStyle(fontSize: 26)),
              Text('🔥', style: TextStyle(fontSize: 26)),
              Text('🤍', style: TextStyle(fontSize: 26)),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Nothing has died yet.',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Burn a desire $kFinalBurnCount times — or hold it and let it '
            'go — and it ends up here for good.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
