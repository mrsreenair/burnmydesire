import 'dart:convert';

/// The purchase interview (PROJECT.md F10).
///
/// Three questions, then a mirror. The rules that make it safe:
///
///  * The AI is the interviewer, never the judge. It asks, and at the end
///    it reflects the user's own answers back — the verdict belongs to
///    the user, on the same two buttons the app has always had. A verdict
///    from the model would turn a ritual of self-control into a
///    permission machine, and permission machines get gamed.
///  * Curated questions are the floor, the model is the upgrade. The
///    interview must work identically on a phone with no Apple
///    Intelligence.
///  * Skippable at every step. Mid-craving, willpower is measured in
///    seconds; reflection must never stand between the user and the fire.

/// One asked-and-answered exchange.
class ReflectionQA {
  const ReflectionQA({required this.question, required this.answer});

  final String question;
  final String answer;

  Map<String, dynamic> toJson() => {'q': question, 'a': answer};

  factory ReflectionQA.fromJson(Map<String, dynamic> json) => ReflectionQA(
        question: json['q'] as String? ?? '',
        answer: json['a'] as String? ?? '',
      );
}

String encodeReflection(List<ReflectionQA> qa) =>
    jsonEncode([for (final e in qa) e.toJson()]);

/// Tolerant of anything — a corrupt column must never break a burn.
List<ReflectionQA> decodeReflection(String? json) {
  if (json == null || json.isEmpty) return const [];
  try {
    final raw = jsonDecode(json);
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) ReflectionQA.fromJson(e),
    ];
  } on FormatException {
    return const [];
  }
}

/// How many questions an interview asks. Three is deliberate: enough to
/// surface a pattern, short enough to finish while the urge is still hot.
const kInterviewLength = 3;

/// The curated bank. Curious, concrete, never accusing — each one is
/// answerable in a phrase, because a question that demands an essay gets
/// skipped. Order matters: the opener is position 0.
const interviewQuestions = <String>[
  'What would this add that you don\'t already own?',
  'When is the next real moment you\'d actually use it?',
  'What were you feeling right before you wanted it?',
  'How many times would you honestly use it in the first month?',
  'If it sold out tonight, how would you feel about it in a week?',
  'Would you still want it if nobody ever saw you with it?',
  'What would you point at in a year to say it was worth it?',
];

/// The curated question for slot [index], skipping anything already
/// asked. Falls back to the last question rather than repeating.
String curatedQuestion(int index, List<String> alreadyAsked) {
  final remaining = [
    for (final q in interviewQuestions)
      if (!alreadyAsked.contains(q)) q,
  ];
  if (remaining.isEmpty) return interviewQuestions.last;
  return remaining.first;
}

/// Instructions for generating the NEXT question. The hard rules mirror
/// the coach's: no verdicts, no advice, no shame.
const kInterviewInstructions =
    'You help someone pause before an impulse purchase inside the app '
    'Burn My Desire. They photographed something they want to buy and are '
    'answering a short interview about it. Your job is to ask exactly ONE '
    'next question — short (under 90 characters), concrete, curious and '
    'warm, answerable in a phrase. Build on their previous answers. Never '
    'judge, never shame, never tell them whether to buy or not buy. Never '
    'give financial advice. Never mention being an AI. Output only the '
    'question itself, no numbering, no quotation marks.';

/// Builds the prompt for the next interview question.
String buildQuestionPrompt({
  required String priceLabel,
  required List<ReflectionQA> soFar,
  List<String> weakSpots = const [],
}) {
  final b = StringBuffer(
    'They want to buy something that costs $priceLabel.',
  );
  if (weakSpots.isNotEmpty) {
    b.write(' Their self-declared spending weak spots: '
        '${weakSpots.join(', ')}.');
  }
  for (final qa in soFar) {
    b.write(' Asked: "${qa.question}" They answered: "${_clip(qa.answer)}".');
  }
  b.write(' Ask the one next question now.');
  return b.toString();
}

/// Instructions for the mirror — the end of the interview. Reflect,
/// never conclude: the last word has to be the user's.
const kMirrorInstructions =
    'You help someone pause before an impulse purchase inside the app '
    'Burn My Desire. They answered a short interview about the thing they '
    'want to buy. Reflect their own answers back to them in second '
    'person: at most two sentences and 200 characters, quoting or closely '
    'paraphrasing their words. Do NOT conclude anything, do NOT recommend '
    'buying or not buying, do NOT judge or shame — end on their words, '
    'not on advice. Never mention being an AI. Output only the '
    'reflection, no quotation marks around it.';

String buildMirrorPrompt({
  required String priceLabel,
  required List<ReflectionQA> answered,
}) {
  final b = StringBuffer(
    'The thing costs $priceLabel. Their interview:',
  );
  for (final qa in answered) {
    b.write(' "${qa.question}" — "${_clip(qa.answer)}".');
  }
  b.write(' Write the reflection now.');
  return b.toString();
}

String _clip(String s) => s.length > 160 ? '${s.substring(0, 160)}…' : s;
