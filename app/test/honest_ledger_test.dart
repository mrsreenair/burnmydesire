import 'package:burn_my_desire/data/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The ledger only means something if it can go down. These cover the
/// three states added with schema 4: money actually moved, bought anyway,
/// and parked.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> burn({int price = 15000}) => db.insertBurnedItem(
    imageFile: 'x.jpg',
    priceCents: price,
    category: 'purchase',
  );

  test('a fresh burn is neither moved nor bought nor parked', () async {
    final id = await burn();
    final item = await db.getItem(id);
    expect(item.movedAt, isNull);
    expect(item.boughtAt, isNull);
    expect(item.parkedUntil, isNull);
  });

  test('moving the money is recorded, and can be taken back', () async {
    final id = await burn();

    await db.setMoved(id, moved: true);
    expect((await db.getItem(id)).movedAt, isNotNull);

    await db.setMoved(id, moved: false);
    expect((await db.getItem(id)).movedAt, isNull);
  });

  test('admitting the purchase clears the claim that it was moved', () async {
    // Otherwise the app would hold both "I saved this" and "I bought it"
    // at once, and the moved total would keep counting money that left.
    final id = await burn();
    await db.setMoved(id, moved: true);

    await db.markBought(id);

    final item = await db.getItem(id);
    expect(item.boughtAt, isNotNull);
    expect(item.movedAt, isNull);
  });

  test('a bought item keeps its row rather than vanishing', () async {
    // Deleting it would restore the very total it should be reducing.
    final id = await burn();
    await db.markBought(id);
    expect((await db.getItem(id)).priceCents, 15000);
  });

  test('changing your mind back is allowed', () async {
    final id = await burn();
    await db.markBought(id);
    await db.markNotBought(id);
    expect((await db.getItem(id)).boughtAt, isNull);
  });

  test('parking sets a return time, unparking clears it', () async {
    final id = await burn();
    final until = DateTime.now().add(const Duration(hours: 24));

    await db.park(id, until);
    final parked = await db.getItem(id);
    expect(parked.parkedUntil, isNotNull);
    expect(
      parked.parkedUntil!.difference(until).inSeconds.abs(),
      lessThan(2),
    );

    await db.unpark(id);
    expect((await db.getItem(id)).parkedUntil, isNull);
  });
}
