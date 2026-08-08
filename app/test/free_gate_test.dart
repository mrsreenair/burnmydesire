import 'package:burn_my_desire/data/database.dart';
import 'package:burn_my_desire/providers/db_providers.dart';
import 'package:burn_my_desire/providers/pro_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Item _item(int id) => Item(
      id: id,
      imageFile: '$id.jpg',
      priceCents: 1000,
      category: 'purchase',
      resistanceCount: 1,
      createdAt: DateTime(2026),
    );

ProviderContainer _container({required int itemCount, bool pro = false}) {
  return ProviderContainer(overrides: [
    itemsProvider.overrideWith(
        (ref) => Stream.value(List.generate(itemCount, _item))),
    if (pro) proProvider.overrideWith(() => _AlwaysPro()),
  ]);
}

class _AlwaysPro extends ProNotifier {
  @override
  bool build() => true;
}

void main() {
  test('free user under the limit can add items', () async {
    final c = _container(itemCount: 2);
    c.listen(itemsProvider, (_, _) {});
  await c.read(itemsProvider.future);
    expect(c.read(canAddItemProvider), isTrue);
  });

  test('free user at the limit is gated', () async {
    final c = _container(itemCount: 3);
    c.listen(itemsProvider, (_, _) {});
  await c.read(itemsProvider.future);
    expect(c.read(canAddItemProvider), isFalse);
  });

  test('pro user is never gated', () async {
    final c = _container(itemCount: 10, pro: true);
    c.listen(itemsProvider, (_, _) {});
  await c.read(itemsProvider.future);
    expect(c.read(canAddItemProvider), isTrue);
  });
}
