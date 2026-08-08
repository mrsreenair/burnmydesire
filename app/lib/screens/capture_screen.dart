import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/burn_target.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
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
    final picked =
        await ImagePicker().pickImage(source: source, maxWidth: 1600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final image = await decodeImageFromList(bytes);
    setState(() {
      _bytes = bytes;
      _image = image;
    });
  }

  void _continue() {
    final cents = parseEurosToCents(_price.text);
    final image = _image;
    final bytes = _bytes;
    if (cents == null || image == null || bytes == null) return;

    InstallmentPlan? plan;
    if (_installments) {
      final monthly = parseEurosToCents(_monthly.text);
      final months = int.tryParse(_months.text.trim());
      if (monthly != null && months != null && months > 0) {
        plan = InstallmentPlan(monthlyCents: monthly, months: months);
      }
    }

    final target = BurnTarget(
      image: image,
      imageBytes: bytes,
      priceCents: cents,
      plan: plan,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShockScreen(target: target)),
    );
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
    final ready = _image != null && parseEurosToCents(_price.text) != null;

    return Scaffold(
      appBar: AppBar(title: const Text('What do you crave?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _bytes == null
                    ? Center(
                        child: Text('Add a photo of it',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)))
                    : Image.memory(_bytes!, fit: BoxFit.cover),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '€ ',
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
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Per month',
                        prefixText: '€ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _months,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Months',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18)),
              onPressed: ready ? _continue : null,
              child: const Text('Show me the damage'),
            ),
          ],
        ),
      ),
    );
  }
}
