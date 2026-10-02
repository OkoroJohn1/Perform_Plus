/// A 40dp lettermark circle standing in for an institution's crest.
///
/// `institution_setup_screen.dart` must never render a real coat of arms —
/// Nigerian universities enforce their crests as copyrighted marks. This is
/// the substitute: the institution's abbreviation (truncated to 5 chars) on
/// a tinted circle in its assigned `InstitutionPalette.avatarPalette` colour.
///
/// When [logoAsset] is set (see `Institution.logoAsset`'s doc comment for
/// the license bar an asset must clear before it's ever wired up there),
/// the real logo renders instead of the lettermark -- as of this writing
/// that's true for exactly one institution.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LettermarkAvatar extends StatelessWidget {
  final String abbreviation;
  final Color color;
  final String? logoAsset;

  const LettermarkAvatar({
    super.key,
    required this.abbreviation,
    required this.color,
    this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    final asset = logoAsset;
    if (asset != null) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: asset.endsWith('.svg')
              ? SvgPicture.asset(asset, fit: BoxFit.contain)
              : Image.asset(asset, fit: BoxFit.contain),
        ),
      );
    }

    final label =
        abbreviation.length > 5 ? abbreviation.substring(0, 5) : abbreviation;

    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
