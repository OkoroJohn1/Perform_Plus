/// Full Result slip wallet -- every slip photo run through extraction,
/// newest first. Pushed from `SlipWalletCard` on the Results screen.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/slip_wallet_provider.dart';
import '../../../domain/models/slip_upload.dart';

String _kindLabel(SlipKind kind) => switch (kind) {
      SlipKind.registration => 'Registration slip',
      SlipKind.result => 'Result slip',
    };

class SlipWalletScreen extends ConsumerWidget {
  const SlipWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(slipWalletProvider);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.bodyText,
        elevation: 0,
        title: const Text('Result slip wallet'),
      ),
      body: uploads.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No slips scanned yet.',
                  style: TextStyle(color: palette.secondaryText, fontSize: 15),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
              ),
              itemCount: uploads.length,
              itemBuilder: (context, i) => _SlipTile(upload: uploads[i]),
            ),
    );
  }
}

class _SlipTile extends ConsumerWidget {
  final SlipUpload upload;

  const _SlipTile({required this.upload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    return InkWell(
      key: ValueKey('slipTile_${upload.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openFullSlip(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.surfaceBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.file(
                File(upload.filePath),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: palette.disabledFill,
                  alignment: Alignment.center,
                  child: Icon(Icons.image_not_supported_outlined, color: palette.hintText),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kindLabel(upload.kind),
                    style: TextStyle(color: palette.bodyText, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM yyyy').format(upload.capturedAt),
                    style: TextStyle(color: palette.secondaryText, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullSlip(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullSlipView(upload: upload),
      ),
    );
  }
}

class _FullSlipView extends ConsumerWidget {
  final SlipUpload upload;

  const _FullSlipView({required this.upload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_kindLabel(upload.kind)),
        actions: [
          IconButton(
            key: const ValueKey('slipDeleteTap'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(upload.filePath)),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this slip?'),
        content: const Text('This removes it from your wallet. The results you already entered from it are not affected.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(slipWalletProvider.notifier).remove(upload);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
