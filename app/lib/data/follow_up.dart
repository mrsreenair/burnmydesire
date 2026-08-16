import 'database.dart';

/// The follow-up cadence (GROWTH.md M5): questions get opened, nags get
/// dismissed — so the app asks "did you buy it?" twice per burn, at
/// three days and at fourteen, and never again.
///
/// Three days is when most impulse cravings have either resolved or
/// been acted on; fourteen catches the ones that took a while. Only the
/// second is asked if the first was "still resisted" — a confession
/// ends the questions.

const followUpFirstAfter = Duration(days: 3);
const followUpSecondAfter = Duration(days: 14);

/// Which question is due for [item] right now: 1, 2, or 0 for none.
int followUpStageFor(Item item, DateTime now) {
  if (item.boughtAt != null || item.category == 'emotion') return 0;
  final burned = item.lastBurnedAt;
  if (burned == null) return 0;
  final since = now.difference(burned);
  // An answer only counts if it came after the most recent burn — a
  // re-burn starts the pair again.
  final answered = item.followUpAt != null && item.followUpAt!.isAfter(burned);
  if (!answered) return since >= followUpFirstAfter ? 1 : 0;
  // First was answered; the second is due at fourteen days unless the
  // answer itself already came that late.
  final answeredLate = item.followUpAt!.difference(burned) >= followUpSecondAfter;
  if (answeredLate) return 0;
  return since >= followUpSecondAfter ? 2 : 0;
}
