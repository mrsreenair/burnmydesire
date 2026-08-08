import 'package:flutter/material.dart';

import '../models/burn_target.dart';
import '../utils/thought_image.dart';
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
      MaterialPageRoute(
        builder: (_) => BurnScreen(
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
            Text(
              'The thought, the craving, the feeling — put it on paper.',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFDF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  expands: true,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: Color(0xFF33291C),
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    height: 1.6,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterStyle: TextStyle(color: Color(0x8833291C)),
                    hintText: 'I keep thinking about…',
                    hintStyle: TextStyle(color: Color(0x6633291C)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: _hasText && !_rendering ? _burn : null,
              icon: const Icon(Icons.local_fire_department),
              label: Text(_rendering ? 'Preparing…' : 'Burn this thought'),
            ),
          ],
        ),
      ),
    );
  }
}
