import 'package:burn_my_desire/data/plan_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('planPeriodFrom', () {
    test('reads the periods the App Store actually sends', () {
      expect(planPeriodFrom('P1W'), PlanPeriod.weekly);
      expect(planPeriodFrom('P1M'), PlanPeriod.monthly);
      expect(planPeriodFrom('P1Y'), PlanPeriod.annual);
      expect(planPeriodFrom('P12M'), PlanPeriod.annual);
    });

    test('a null period is a one-off purchase, not a subscription', () {
      expect(planPeriodFrom(null), PlanPeriod.lifetime);
    });

    test('anything unexpected stays unlabelled rather than guessed', () {
      expect(planPeriodFrom('P3M'), PlanPeriod.other);
      expect(planPeriodFrom('nonsense'), PlanPeriod.other);
    });
  });

  group('trialDaysFrom', () {
    test('converts each unit', () {
      expect(trialDaysFrom('P7D'), 7);
      expect(trialDaysFrom('P1W'), 7);
      expect(trialDaysFrom('P1M'), 30);
      expect(trialDaysFrom('P1Y'), 365);
    });

    test('no trial reads as no trial', () {
      expect(trialDaysFrom(null), isNull);
      expect(trialDaysFrom(''), isNull);
      expect(trialDaysFrom('P0D'), isNull);
      expect(trialDaysFrom('garbage'), isNull);
    });
  });

  group('annualSavingsPercent', () {
    test('the usual case', () {
      // €2.99/mo is €35.88 a year; €19.99 saves 44%.
      expect(
        annualSavingsPercent(monthlyPrice: 2.99, annualPrice: 19.99),
        44,
      );
    });

    test('never claims a saving that isn\'t there', () {
      // Annual priced at or above twelve months: no badge at all, rather
      // than "Save 0%" or a negative number.
      expect(annualSavingsPercent(monthlyPrice: 2.0, annualPrice: 24.0), isNull);
      expect(annualSavingsPercent(monthlyPrice: 2.0, annualPrice: 30.0), isNull);
    });

    test('refuses to divide by nothing', () {
      expect(annualSavingsPercent(monthlyPrice: 0, annualPrice: 19.99), isNull);
      expect(annualSavingsPercent(monthlyPrice: 2.99, annualPrice: 0), isNull);
      expect(annualSavingsPercent(monthlyPrice: -1, annualPrice: 19.99), isNull);
    });
  });

  test('perMonthFromAnnual', () {
    expect(perMonthFromAnnual(19.99), closeTo(1.665, 0.001));
  });
}
