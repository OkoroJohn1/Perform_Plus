/// "Add a PIN" flow — create, then confirm by re-entry, then save. A
/// mismatch on confirm clears the pad and returns to the create step
/// rather than silently accepting a typo as the new PIN.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/pin_provider.dart';
import '../widgets/pin_pad.dart';

Future<void> showPinSetupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _PinSetupSheet(),
  );
}

class _PinSetupSheet extends ConsumerStatefulWidget {
  const _PinSetupSheet();

  @override
  ConsumerState<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends ConsumerState<_PinSetupSheet> {
  final _controller = PinPadController();
  String? _firstEntry;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onComplete(String pin) async {
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = pin;
        _controller.clear();
      });
      return;
    }

    if (pin != _firstEntry) {
      setState(() {
        _error = "PINs didn't match. Try again.";
        _firstEntry = null;
        _controller.clear();
      });
      return;
    }

    setState(() => _saving = true);
    await ref.read(pinProvider.notifier).setPin(pin);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN lock enabled.')));
  }

  @override
  Widget build(BuildContext context) {
    final confirming = _firstEntry != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            confirming ? 'Confirm your PIN' : 'Create a PIN',
            style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            confirming ? 'Enter it once more to confirm.' : "You'll need this to open Perform+.",
            style: TextStyle(color: context.palette.secondaryText, fontSize: 13.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: context.palette.error, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          if (_saving)
            const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())
          else
            PinPad(controller: _controller, onComplete: _onComplete),
        ],
      ),
    );
  }
}
