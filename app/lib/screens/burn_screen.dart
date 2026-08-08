import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../widgets/burnable_image.dart';
import 'victory_screen.dart';

class BurnScreen extends StatelessWidget {
  const BurnScreen({super.key, required this.target});

  final BurnTarget target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: BurnableImage(
                  image: target.image,
                  onBurned: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => VictoryScreen(target: target),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Text(
              'Press and hold. Let it go.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
