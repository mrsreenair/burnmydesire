import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/providers/db_providers.dart';
import 'package:burn_my_desire/providers/pro_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Frozen calendar so "this month" is deterministic.
final _now = DateTime(2026, 8, 15);

Item _item(
  int id, {
  DateTime? createdAt,
  DateTime? destroyedAt,
}) =>
    Item(
      id: id,
      imageFile: '$id.jpg',
      priceCents: 1000,
      category: 'purchase',
      resistanceCount: 1,
      createdAt: createdAt ?? DateTime(2026, 1, id.clamp(1, 28)),
      destroyedAt: destroyedAt,
    );

ProviderContainer _container({
  required List<Item> items,
  bool pro = false,
}) {
  return ProviderContainer(overrides: [
    nowProvider.overrideWithValue(_now),
    itemsProvider.overrideWith((ref) => Stream.value(items)),
    if (pro) proProvider.overrideWithValue(true),
  ]);
}

Future<ProviderContainer> _ready(ProviderContainer c) async {
  c.listen(itemsProvider, (_, _) {});
  await c.read(itemsProvider.future);
  return c;
}

void main() {
  test('free user under both limits can add items', () async {
    final c = await _ready(_container(items: [_item(1), _item(2)]));
    expect(c.read(canAddItemProvider), isTrue);
    expect(c.read(addBlockProvider), AddBlock.none);
  });

  test('free user at the live-item limit is gated', () async {
    final c =
        await _ready(_container(items: [_item(1), _item(2), _item(3)]));
    expect(c.read(canAddItemProvider), isFalse);
    expect(c.read(addBlockProvider), AddBlock.liveLimit);
  });

  test('five captures this month exhaust the monthly allowance', () async {
    // All five this month, but only two still live — the live limit
    // passes and the monthly one must catch it.
    final c = await _ready(_container(items: [
      for (var i = 1; i <= 5; i++)
        _item(
          i,
          createdAt: DateTime(2026, 8, i),
          destroyedAt: i <= 3 ? DateTime(2026, 8, i + 1) : null,
        ),
    ]));
    expect(c.read(newItemsThisMonthProvider), 5);
    expect(c.read(addBlockProvider), AddBlock.monthlyLimit);
    expect(c.read(canAddItemProvider), isFalse);
  });

  test('destroyed tombstones still count — a final burn can\'t be '
      'farmed to refill the month', () async {
    final c = await _ready(_container(items: [
      for (var i = 1; i <= 5; i++)
        _item(
          i,
          createdAt: DateTime(2026, 8, i),
          destroyedAt: DateTime(2026, 8, i + 1),
        ),
    ]));
    // Zero live items, yet the month is spent.
    expect(c.read(liveItemsProvider), isEmpty);
    expect(c.read(addBlockProvider), AddBlock.monthlyLimit);
  });

  test('last month\'s captures don\'t count against this month', () async {
    final c = await _ready(_container(items: [
      for (var i = 1; i <= 5; i++)
        _item(
          i,
          createdAt: DateTime(2026, 7, i),
          destroyedAt: i <= 3 ? DateTime(2026, 7, i + 1) : null,
        ),
    ]));
    expect(c.read(newItemsThisMonthProvider), 0);
    expect(c.read(addBlockProvider), AddBlock.none);
  });

  test('pro user is never gated', () async {
    final c = await _ready(_container(
      pro: true,
      items: [
        for (var i = 1; i <= 10; i++) _item(i, createdAt: DateTime(2026, 8, 1)),
      ],
    ));
    expect(c.read(canAddItemProvider), isTrue);
  });
}
