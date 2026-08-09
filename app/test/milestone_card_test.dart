import 'package:burn_my_desire/utils/milestone_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a PNG', () async {
    final bytes =
        await renderMilestoneCard(protectedCents: 120000, burns: 3);
    expect(bytes.length, greaterThan(2000));
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  test('singular and plural both render', () async {
    final one = await renderMilestoneCard(protectedCents: 500, burns: 1);
    final many = await renderMilestoneCard(protectedCents: 500, burns: 9);
    expect(one, isNotEmpty);
    expect(many, isNotEmpty);
    // Different copy means different pixels.
    expect(one, isNot(equals(many)));
  });
}
