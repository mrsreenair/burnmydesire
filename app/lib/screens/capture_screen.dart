import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/burn_target.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../utils/format_utils.dart';
import '../utils/math_utils.dart';
import '../widgets/ember_ui.dart';
import '../widgets/paper_backdrop.dart';
import 'reflection_screen.dart';

/// Capture: a photo and a price, and nothing else.
///
/// Built on how marketplace apps take a listing (Karrot, eBay, Vinted,
/// Shopify on Mobbin), because "photograph a thing and say what it costs"
/// is exactly their problem. Three things they all do that the first
/// version of this screen didn't:
///
///  * The empty photo slot is a small TILE in a row, not a page-filling
///    box. Nobody gives half a screen to a placeholder — the space belongs
///    to the fields you have to fill in.
///  * ONE control adds media; camera-or-library is asked afterwards, in a
///    sheet. Two permanent buttons that do nearly the same thing is a
///    choice the user shouldn't have to make up front.
///  * Fields carry an example, not just a name ("e.g. 249" the way Vinted
///    writes "e.g. White COS Sweater"), so the format is never a guess.
///
/// The one place this departs from them: the price is set in big type
/// rather than as another row. Every marketplace treats price as one field
/// among many because it is. Here it is the entire point of the app — the
/// number that becomes the wealth you kept — so it is the biggest thing
/// on the page.
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
    if (!mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bytes = bytes;
      _image = image;
    });
  }

  /// Camera or library, asked once and only when it matters. Two permanent
  /// buttons on the page made the user answer this before they'd even
  /// decided to add anything.
  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SourceSheet(canRemove: _bytes != null),
    );
    if (source == null) return;
    await _pick(source);
  }

  void _removePhoto() {
    setState(() {
      _bytes = null;
      _image = null;
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

    // The interview (PROJECT.md F10): three questions, then the user's
    // own answers mirrored back, then the growth-or-impulse choice —
    // theirs, always.
    final target = BurnTarget(
      image: image,
      imageBytes: bytes,
      priceCents: cents,
      plan: plan,
    );
    if (!mounted) return;
    Navigator.of(context).push(emberRoute(ReflectionScreen(target: target)));
  }

  /// What's still missing, in the user's words. A dead grey button that
  /// never says why is the most common complaint about forms like this.
  String? get _blocker {
    final hasPrice = parseMoneyToCents(_price.text) != null;
    if (_image == null && !hasPrice) return 'Add a photo and what it costs';
    if (_image == null) return 'Add a photo of it';
    if (!hasPrice) return 'Add what it costs';
    return null;
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
    final blocker = _blocker;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: PaperBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            children: [
              Reveal(
                child: Text(
                  'What do you\ncrave?',
                  style: theme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 8),
              Reveal(
                delay: const Duration(milliseconds: 40),
                child: Text(
                  'A photo and a price. That\'s all it takes to see what it '
                  'really costs you.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textMid,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Reveal(
                delay: const Duration(milliseconds: 80),
                child: const SectionLabel('The thing'),
              ),
              const SizedBox(height: 10),
              Reveal(
                delay: const Duration(milliseconds: 100),
                child: _PhotoRow(
                  bytes: _bytes,
                  onTap: _chooseSource,
                  onRemove: _removePhoto,
                ),
              ),
              const SizedBox(height: 28),

              Reveal(
                delay: const Duration(milliseconds: 140),
                child: const SectionLabel('The price'),
              ),
              const SizedBox(height: 10),
              Reveal(
                delay: const Duration(milliseconds: 160),
                child: _PriceCard(
                  price: _price,
                  monthly: _monthly,
                  months: _months,
                  installments: _installments,
                  onInstallments: (v) => setState(() => _installments = v),
                  onPriceChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 28),

              // The button says what it does; this says why it can't yet.
              AnimatedSwitcher(
                duration: Motion.fast,
                child: blocker == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        key: ValueKey(blocker),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                              color: AppColors.textLow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              blocker,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              EmberButton(
                label: 'Show me the damage',
                icon: Icons.bolt,
                onPressed: blocker == null ? _continue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The photo slot: a tile you can take in at a glance, with the guidance
/// beside it rather than inside it (Karrot and eBay both put the camera
/// tile in a row and let the copy live outside).
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.bytes,
    required this.onTap,
    required this.onRemove,
  });

  final Uint8List? bytes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const _side = 112.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final has = bytes != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: Motion.base,
                width: _side,
                height: _side,
                decoration: BoxDecoration(
                  color: AppColors.paperHigh,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: has
                        ? AppColors.accent.withValues(alpha: 0.55)
                        : AppColors.hairline,
                    width: has ? 1.5 : 1,
                  ),
                  boxShadow: AppColors.cardShadow(opacity: has ? 0.12 : 0.05),
                ),
                clipBehavior: Clip.antiAlias,
                child: has
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 26,
                            color: AppColors.textLow,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMid,
                            ),
                          ),
                        ],
                      ),
              ),
              if (has)
                Positioned(
                  top: -6,
                  right: -6,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.paper, width: 2),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  has ? 'This is what burns' : 'Add a photo of it',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  has
                      ? 'Tap it to swap the photo, or × to drop it.'
                      : 'A screenshot from the shop works. Seeing the thing '
                            'is what makes letting it go mean something.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMid,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Price, in big type, with the optional monthly plan folded underneath —
/// a disclosure row rather than a permanent pair of fields, so the common
/// case stays a single number.
class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.monthly,
    required this.months,
    required this.installments,
    required this.onInstallments,
    required this.onPriceChanged,
  });

  final TextEditingController price;
  final TextEditingController monthly;
  final TextEditingController months;
  final bool installments;
  final ValueChanged<bool> onInstallments;
  final VoidCallback onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symbol = activeCurrency.symbol.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow(opacity: 0.06),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  symbol,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textLow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    style: theme.textTheme.displaySmall,
                    decoration: InputDecoration(
                      // The app's fields are grey pills. This one isn't a
                      // field so much as a figure written on the card, so
                      // the fill and padding have to be turned off
                      // explicitly — `border: none` alone leaves the pill.
                      filled: false,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: '0',
                      hintStyle: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.textLow.withValues(alpha: 0.45),
                      ),
                    ),
                    onChanged: (_) => onPriceChanged(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              // People halfway to a finance deal type the monthly figure
              // here. The whole point is the number they'd actually owe.
              'The full price — not the monthly payment',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textLow,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.hairline),
          SwitchListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            title: Text(
              'I\'d pay monthly',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Instalments hide the real total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMid,
              ),
            ),
            value: installments,
            onChanged: onInstallments,
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.easeOut,
            child: installments
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: monthly,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Per month',
                              prefixText: '$symbol ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: months,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Months',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Camera or library, asked at the moment of adding — the iOS convention,
/// and what every listing flow does instead of two permanent buttons.
class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.canRemove});

  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paperHigh,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppColors.cardShadow(opacity: 0.16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  canRemove ? 'Swap the photo' : 'Add a photo',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from library'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
