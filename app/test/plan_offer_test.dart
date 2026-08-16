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

  group('the paywall\'s own ordering (GROWTH.md M1)', () {
    test('lifetime is the hero, weekly is never sold', () {
      final periods = [
        PlanPeriod.weekly,
        PlanPeriod.annual,
        PlanPeriod.monthly,
        PlanPeriod.lifetime,
        PlanPeriod.other,
      ];
      final shown = [
        for (final p in periods)
          if (offeredOnPaywall(p)) p,
      ]..sort((a, b) => paywallRank(a).compareTo(paywallRank(b)));
      expect(shown, [
        PlanPeriod.lifetime,
        PlanPeriod.annual,
        PlanPeriod.monthly,
      ]);
      expect(heroIndex(shown), 0);
    });

    test('without a lifetime plan, annual is preselected', () {
      expect(heroIndex([PlanPeriod.annual, PlanPeriod.monthly]), 0);
      expect(heroIndex([PlanPeriod.monthly, PlanPeriod.annual]), 1);
      expect(heroIndex([PlanPeriod.monthly]), 0);
    });

    test('the new prices still earn a savings badge', () {
      // €2.99/mo is €35.88 a year; €14.99 saves 58%.
      expect(
        annualSavingsPercent(monthlyPrice: 2.99, annualPrice: 14.99),
        58,
      );
    });
  });

  group('burnsCoveringLifetime', () {
    test('says how many times a burn covers Pro forever', () {
      expect(burnsCoveringLifetime(burnCents: 24900, lifetimePrice: 29.99), 8);
      expect(burnsCoveringLifetime(burnCents: 2999, lifetimePrice: 29.99), 1);
      expect(burnsCoveringLifetime(burnCents: 5000, lifetimePrice: 29.99), 1);
    });

    test('says nothing when the burn is smaller than the price', () {
      // A €12 coffee-machine burn does not "pay for" a €29.99 plan, and
      // the paywall must not pretend it does.
      expect(burnsCoveringLifetime(burnCents: 1200, lifetimePrice: 29.99), isNull);
      expect(burnsCoveringLifetime(burnCents: 0, lifetimePrice: 29.99), isNull);
      expect(burnsCoveringLifetime(burnCents: 5000, lifetimePrice: 0), isNull);
    });
  });

  group('paywallHeadline', () {
    test('speaks to the moment it was opened from', () {
      expect(paywallHeadline(PaywallSource.general), 'Burn without limits');
      expect(
        paywallHeadline(PaywallSource.limit, limitLine: 'You let go of 5.'),
        'You let go of 5.',
      );
      expect(paywallHeadline(PaywallSource.limit), 'Burn without limits');
      expect(
        paywallHeadline(PaywallSource.effect),
        'Unlock every way to let go',
      );
      expect(paywallHeadline(PaywallSource.goal), 'Chase more than one thing');
      expect(
        paywallHeadline(PaywallSource.moment, burnLabel: '€249'),
        'You just protected €249',
      );
      expect(paywallHeadline(PaywallSource.moment), 'Keep this going');
    });
  });
}
