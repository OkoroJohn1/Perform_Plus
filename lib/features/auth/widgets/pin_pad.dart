/// Shared numeric PIN entry UI — dot progress indicator plus a 0-9 keypad
/// with backspace, used identically by the setup sheet (create + confirm)
/// and the lock screen (verify). [onComplete] fires exactly once per
/// [pinLength]-digit sequence; the caller resets via [PinPadController]
/// (e.g. after a wrong-PIN shake) rather than this widget tracking success.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_palette.dart';
import '../services/pin_service.dart';

class PinPadController extends ChangeNotifier {
  String _digits = '';

  String get digits => _digits;

  void clear() {
    _digits = '';
    notifyListeners();
  }

  /// Returns the new digit string, or null if already at [pinLength] and
  /// the tap was ignored.
  String? appendDigit(String digit) {
    if (_digits.length >= pinLength) return null;
    _digits += digit;
    notifyListeners();
    return _digits;
  }

  void backspace() {
    if (_digits.isEmpty) return;
    _digits = _digits.substring(0, _digits.length - 1);
    notifyListeners();
  }
}

class PinPad extends StatefulWidget {
  final PinPadController controller;
  final ValueChanged<String> onComplete;
  final Color? dotColor;

  /// Key-cap fill and label colour — defaults to the page background /
  /// body text (the setup sheet's plain white/dark surface). The lock
  /// screen overrides both to sit correctly on its glass card instead of
  /// painting a solid light/dark square behind every digit.
  final Color? keyFillColor;
  final Color? keyLabelColor;

  const PinPad({
    super.key,
    required this.controller,
    required this.onComplete,
    this.dotColor,
    this.keyFillColor,
    this.keyLabelColor,
  });

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _press(String digit) {
    final next = widget.controller.appendDigit(digit);
    if (next != null && next.length == pinLength) {
      HapticFeedback.selectionClick();
      widget.onComplete(next);
    }
  }

  void _backspace() => widget.controller.backspace();

  @override
  Widget build(BuildContext context) {
    final color = widget.dotColor ?? context.palette.primary;
    final filled = widget.controller.digits.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < pinLength; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: i < filled ? 17 : 15,
                height: i < filled ? 17 : 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < filled ? color : Colors.transparent,
                  border: Border.all(color: color, width: 1.6),
                  boxShadow: i < filled
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.55),
                              blurRadius: 10,
                              spreadRadius: 1)
                        ]
                      : null,
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final d in row)
                  _PinKey(
                    label: d,
                    onTap: () => _press(d),
                    fillColor: widget.keyFillColor,
                    labelColor: widget.keyLabelColor,
                  ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 64, height: 64),
            _PinKey(
              label: '0',
              onTap: () => _press('0'),
              fillColor: widget.keyFillColor,
              labelColor: widget.keyLabelColor,
            ),
            SizedBox(
              width: 64,
              height: 64,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined),
                color: widget.keyLabelColor ?? context.palette.secondaryText,
                onPressed: _backspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? fillColor;
  final Color? labelColor;

  const _PinKey(
      {required this.label,
      required this.onTap,
      this.fillColor,
      this.labelColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Material(
          color: fillColor ?? context.palette.background,
          shape: CircleBorder(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? context.palette.bodyText),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
