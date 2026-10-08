/// "Result slip wallet" card on the Results screen -- every slip photo run
/// through extraction (registration-slip or result-slip scans, see
/// `SlipKind`) is kept here so a student can look back at what they
/// uploaded. Previously those photos were used once for OCR then silently
/// discarded; see `add_semester_sheet.dart`'s `_scanSlip`/`_scanResultSlip`
/// for where they're now saved.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/slip_wallet_provider.dart';
import '../../../domain/models/slip_upload.dart';
import '../screens/slip_wallet_screen.dart';

class SlipWalletCard extends ConsumerWidget {
  const SlipWalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(slipWalletProvider);
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 20, color: palette.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Result slip wallet',
                  style: TextStyle(color: palette.bodyText, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              if (uploads.isNotEmpty)
                Text(
                  '${uploads.length}',
                  style: TextStyle(color: palette.secondaryText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Every slip you\'ve scanned for extraction, kept here.',
            style: TextStyle(color: palette.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 14),
          if (uploads.isEmpty)
            Text(
              'No slips scanned yet -- scan a registration or result slip above and it lands here.',
              style: TextStyle(color: palette.hintText, fontSize: 13),
            )
          else
            InkWell(
              key: const ValueKey('slipWalletOpenTap'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SlipWalletScreen()),
              ),
              child: Row(
                children: [
                  for (final upload in uploads.take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Thumb(upload: upload),
                    ),
                  if (uploads.length > 4)
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: palette.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${uploads.length - 4}',
                        style: TextStyle(color: palette.primary, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: palette.hintText),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final SlipUpload upload;

  const _Thumb({required this.upload});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(upload.filePath),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 52,
          height: 52,
          color: context.palette.disabledFill,
          child: Icon(Icons.image_not_supported_outlined, size: 18, color: context.palette.hintText),
        ),
      ),
    );
  }
}
