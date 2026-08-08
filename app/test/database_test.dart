import 'package:burn_my_desire/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('first burn inserts with resistance count 1', () async {
    await db.insertBurnedItem(imageFile: 'a.jpg', priceCents: 80000);
    final items = await db.watchItems().first;
    expect(items, hasLength(1));
    expect(items.single.resistanceCount, 1);
    expect(items.single.lastBurnedAt, isNotNull);
  });

  test('re-burn increments resistance, price counted once', () async {
    final id = await db.insertBurnedItem(imageFile: 'a.jpg', priceCents: 80000);
    await db.recordReBurn(id);
    await db.recordReBurn(id);

    final items = await db.watchItems().first;
    expect(items.single.resistanceCount, 3);

    final protected = items.fold(0, (s, i) => s + i.priceCents);
    expect(protected, 80000, reason: 'savings must never multiply per burn');
  });

  test('installment terms are stored', () async {
    await db.insertBurnedItem(
        imageFile: 'a.jpg', priceCents: 80000, monthlyCents: 7000, months: 12);
    final item = (await db.watchItems().first).single;
    expect(item.monthlyCents, 7000);
    expect(item.months, 12);
  });

  test('items ordered by most recently burned', () async {
    final a = await db.insertBurnedItem(imageFile: 'a.jpg', priceCents: 100);
    await db.insertBurnedItem(imageFile: 'b.jpg', priceCents: 200);
    await db.recordReBurn(a);
    final items = await db.watchItems().first;
    expect(items.first.id, a);
  });
}
