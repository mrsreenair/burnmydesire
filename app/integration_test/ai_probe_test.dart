import 'package:burn_my_desire/data/ai_coach.dart';
import 'package:burn_my_desire/data/reflection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Diagnostic probe, not a pass/fail gate: prints exactly what Apple
/// Intelligence reports on THIS device and what a real generation
/// attempt returns, so "AI enabled but still curated fallbacks" stops
/// being a mystery. Run on a physical phone:
///
///   flutter test integration_test/ai_probe_test.dart -d DEVICE
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('probe: status, then one real generation of each kind', () async {
    final coach = AiCoach();

    final status = await coach.status();
    final available = await coach.isAvailable();
    // ignore: avoid_print
    print('AI PROBE status=$status available=$available');

    // One encouragement (what the victory screen asks for).
    final enc = await coach.encouragement(
      isEmotion: true,
      burnNumber: 2,
      goalLabels: ['Impulse buying'],
      thought: 'I want those sneakers so badly',
    );
    // ignore: avoid_print
    print('AI PROBE encouragement=${enc ?? 'NULL'} '
        'lastError=${AiCoach.lastError ?? 'none'}');

    // One interview question (what the reflection screen asks for).
    final q = await coach.generate(
      instructions: kInterviewInstructions,
      prompt: buildQuestionPrompt(
        priceLabel: '€250',
        soFar: const [
          ReflectionQA(
            question: 'When is the next real moment you\'d actually use it?',
            answer: 'Maybe a party next month',
          ),
        ],
      ),
      timeout: const Duration(seconds: 15),
      maxLength: 120,
    );
    // ignore: avoid_print
    print('AI PROBE question=${q ?? 'NULL'} '
        'lastError=${AiCoach.lastError ?? 'none'}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
