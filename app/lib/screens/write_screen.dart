import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/thought_image.dart';
import '../widgets/ember_ui.dart';
import 'burn_screen.dart';

/// Write the thought, craving, or feeling on paper — then burn the paper.
/// No price, no shock card: straight to the ritual.
class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _controller = TextEditingController();
  var _hasText = false;
  var _rendering = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _burn() async {
    setState(() => _rendering = true);
    final bytes = await renderThoughtImage(_controller.text.trim());
    final image = await decodeImageFromList(bytes);
    if (!mounted) return;
    setState(() => _rendering = false);
    Navigator.of(context).push(
      fireRoute(
        BurnScreen(
          target: BurnTarget(
            image: image,
            imageBytes: bytes,
            priceCents: 0,
            category: 'emotion',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Write it down')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Reveal(
              child: Text(
                'The thought, the craving, the feeling — put it on paper.',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: AppColors.textMid),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                // The thought goes on a real sticky note.
                decoration: BoxDecoration(
                  color: AppColors.sticky,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow(),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: AppColors.stickyInk,
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    // Raw paper: no fill, no borders — just ink on the note.
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterStyle: TextStyle(color: Color(0x996B5D2E)),
                    hintText: 'I keep thinking about…',
                    hintStyle: TextStyle(color: Color(0x776B5D2E)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            EmberButton(
              label: _rendering ? 'Preparing…' : 'Burn this thought',
              icon: Icons.local_fire_department,
              kind: PillKind.fire,
              onPressed: _hasText && !_rendering ? _burn : null,
            ),
          ],
        ),
      ),
    );
  }
}
