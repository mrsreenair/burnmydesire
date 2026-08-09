import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../widgets/ember_ui.dart';
import 'shock_screen.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _price = TextEditingController();
  final _monthly = TextEditingController();
  final _months = TextEditingController(text: '12');
  bool _installments = false;
  Uint8List? _bytes;
  ui.Image? _image;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _bytes = bytes;
      _image = image;
    });
  }

  Future<void> _continue() async {
    final cents = parseMoneyToCents(_price.text);
    final image = _image;
    final bytes = _bytes;
    if (cents == null || image == null || bytes == null) return;

    InstallmentPlan? plan;
    if (_installments) {
      final monthly = parseMoneyToCents(_monthly.text);
      final months = int.tryParse(_months.text.trim());
      if (monthly != null && months != null && months > 0) {
        plan = InstallmentPlan(monthlyCents: monthly, months: months);
      }
    }

    // Reflection, not advice (PROJECT.md F10): a genuine tool for growth
    // deserves a calmer framing than a dopamine hit.
    final growth = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('One honest question'),
        content: const Text(
          'Is this a real investment in your growth — a tool for your '
          'career or skills you\'ll actually use — or is it an impulse?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('It builds my future'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('It\'s an impulse'),
          ),
        ],
      ),
    );
    if (growth == null || !mounted) return;

    final target = BurnTarget(
      image: image,
      imageBytes: bytes,
      priceCents: cents,
      plan: plan,
    );
    Navigator.of(
      context,
    ).push(emberRoute(ShockScreen(target: target, forGrowth: growth)));
  }

  @override
  void dispose() {
    _price.dispose();
    _monthly.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ready = _image != null && parseMoneyToCents(_price.text) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('What do you crave?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Reveal(
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: AnimatedContainer(
                  duration: Motion.base,
                  decoration: BoxDecoration(
                    color: AppColors.paperHigh,
                    borderRadius: BorderRadius.circular(24),
                    border: _bytes == null
                        ? Border.all(
                            color: AppColors.ink.withValues(alpha: 0.08),
                          )
                        : Border.all(
                            color: AppColors.accent.withValues(alpha: 0.6),
                          ),
                    boxShadow: AppColors.cardShadow(
                      opacity: _bytes == null ? 0.06 : 0.12,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _bytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: AppColors.textLow,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a photo of it',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.textMid,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(_bytes!, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Price',
                prefixText: '${activeCurrency.symbol.trim()} ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I\'d buy it on installments'),
              value: _installments,
              onChanged: (v) => setState(() => _installments = v),
            ),
            if (_installments) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _monthly,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Per month',
                        prefixText: '${activeCurrency.symbol.trim()} ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _months,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Months',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            EmberButton(
              label: 'Show me the damage',
              icon: Icons.bolt,
              onPressed: ready ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}
