import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/financial_goal.dart';

/// The saved goal, null when none was set. Invalidate after saving or
/// clearing.
final financialGoalProvider = FutureProvider<FinancialGoal?>(
  (ref) => savedFinancialGoal(),
);
