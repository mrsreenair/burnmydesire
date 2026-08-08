/// Curated encouragement shown after an emotional burn. No AI, no
/// network — these ship with the app and work offline. (The AI roadmap
/// in PROJECT.md §4.4 layers personalization on top later.)
const _firstBurnMessages = [
  'That thought is ash now. You faced it instead of feeding it.',
  'You wrote it down, looked it in the eye, and let it go. That\'s strength.',
  'The urge was real. So was the fire. You chose the fire.',
  'What you burn stops owning you. One page at a time.',
  'You didn\'t scroll past this feeling — you ended it. Well done.',
];

const _streakMessages = [
  'Resisted %N× now. Every burn makes the urge weaker and you stronger.',
  '%N times this desire came back. %N times you burned it. It\'s losing.',
  'Streak: %N. The craving is on a losing record against you.',
  'That\'s %N burns. You\'re building proof that you\'re in charge.',
];

/// Picks a stable-but-varied message. [resistanceCount] > 1 celebrates
/// the streak; otherwise the first-burn set is used. [seed] keeps the
/// choice deterministic per item so re-renders don't flicker.
String motivationMessage({required int resistanceCount, required int seed}) {
  if (resistanceCount > 1) {
    final template = _streakMessages[seed % _streakMessages.length];
    return template.replaceAll('%N', '$resistanceCount');
  }
  return _firstBurnMessages[seed % _firstBurnMessages.length];
}
