import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../models/burn_target.dart';
import '../providers/db_providers.dart';
import '../providers/pro_provider.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import 'capture_screen.dart';
import 'paywall_screen.dart';
import 'shock_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _reBurn(BuildContext context, WidgetRef ref, Item item) async {
    final store = ref.read(imageStoreProvider);
    final bytes = await store.read(item.imageFile);
    final image = await decodeImageFromList(bytes);
    if (!context.mounted) return;
    final plan = item.monthlyCents != null && item.months != null
        ? InstallmentPlan(monthlyCents: item.monthlyCents!, months: item.months!)
        : null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShockScreen(
          target: BurnTarget(
            itemId: item.id,
            image: image,
            imageBytes: bytes,
            priceCents: item.priceCents,
            plan: plan,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider).value ?? const <Item>[];
    final protected = ref.watch(protectedCentsProvider);
    final store = ref.watch(imageStoreProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Burn My Desire'),
        actions: [
          IconButton(
            tooltip: 'Go Pro',
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (protected > 0) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('${formatEuros(protected)} protected',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'worth ${formatEuros(futureValueCents(protected, years: kDefaultHorizonYears))} '
                        'in $kDefaultHorizonYears years',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(
                            'Craving something you\nshouldn\'t buy?',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          tileColor: theme.colorScheme.surfaceContainerHigh,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(store.file(item.imageFile),
                                width: 48, height: 48, fit: BoxFit.cover),
                          ),
                          title: Text(formatEuros(item.priceCents)),
                          subtitle:
                              Text('resisted ${item.resistanceCount}×'),
                          trailing: const Text('🔥'),
                          onTap: () => _reBurn(context, ref, item),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ref.read(canAddItemProvider)
                      ? const CaptureScreen()
                      : const PaywallScreen(),
                ),
              ),
              icon: const Icon(Icons.local_fire_department),
              label: const Text('I want something…'),
            ),
          ],
        ),
      ),
    );
  }
}
