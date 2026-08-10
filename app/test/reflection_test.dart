import 'package:burn_my_desire/data/reflection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const qa = [
    ReflectionQA(question: 'When would you use it?', answer: 'A wedding'),
    ReflectionQA(question: 'How were you feeling?', answer: 'Bored, honestly'),
  ];

  group('serialization', () {
    test('round-trips', () {
      final decoded = decodeReflection(encodeReflection(qa));
      expect(decoded.length, 2);
      expect(decoded.first.question, 'When would you use it?');
      expect(decoded.last.answer, 'Bored, honestly');
    });

    test('garbage never breaks a burn', () {
      expect(decodeReflection(null), isEmpty);
      expect(decodeReflection(''), isEmpty);
      expect(decodeReflection('not json'), isEmpty);
      expect(decodeReflection('{"q":"a"}'), isEmpty); // map, not list
      expect(decodeReflection('[1, 2]'), isEmpty); // list of non-maps
    });
  });

  group('curated bank', () {
    test('has enough distinct questions for a full interview', () {
      expect(interviewQuestions.toSet().length, interviewQuestions.length);
      expect(
        interviewQuestions.length,
        greaterThanOrEqualTo(kInterviewLength + 2),
      );
      for (final q in interviewQuestions) {
        // Answerable in a phrase, and never a verdict.
        expect(q.length, lessThan(100), reason: q);
        expect(q.endsWith('?'), isTrue, reason: q);
      }
    });

    test('never repeats an already-asked question', () {
      final asked = interviewQuestions.take(2).toList();
      final next = curatedQuestion(2, asked);
      expect(asked.contains(next), isFalse);
    });

    test('exhausted bank falls back instead of crashing', () {
      final next = curatedQuestion(99, interviewQuestions);
      expect(next, interviewQuestions.last);
    });
  });

  group('prompts', () {
    test('question prompt carries price, weak spots and the dialogue', () {
      final prompt = buildQuestionPrompt(
        priceLabel: '₹1,29,900',
        soFar: qa,
        weakSpots: ['Gadgets', 'Sneakers & shoes'],
      );
      expect(prompt, contains('₹1,29,900'));
      expect(prompt, contains('Gadgets'));
      expect(prompt, contains('A wedding'));
      expect(prompt, contains('Bored, honestly'));
    });

    test('mirror prompt quotes every answer', () {
      final prompt = buildMirrorPrompt(priceLabel: '€800', answered: qa);
      expect(prompt, contains('€800'));
      expect(prompt, contains('A wedding'));
      expect(prompt, contains('Bored, honestly'));
    });

    test('long answers are clipped so the prompt stays bounded', () {
      final long = ReflectionQA(question: 'Q?', answer: 'x' * 500);
      final prompt = buildQuestionPrompt(priceLabel: '€1', soFar: [long]);
      expect(prompt.length, lessThan(400));
    });

    test('the interviewer instructions forbid verdicts', () {
      // The one design rule that must survive every future edit: the AI
      // asks and mirrors; it never judges, and the user always decides.
      expect(kInterviewInstructions, contains('Never judge'));
      expect(kInterviewInstructions.toLowerCase(),
          contains('never tell them whether to buy'));
      expect(kMirrorInstructions, contains('do NOT recommend'));
    });
  });
}
