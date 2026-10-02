/// Appearance (Light/Dark/System), Theme colour and Notifications sheets —
/// shared between the Me tab's App section, the quick-access rows in
/// [AppDrawer] (`app_drawer.dart`), and the Notifications panel's own
/// settings icon, so there is exactly one implementation of each, not a
/// duplicate copy per screen that could drift apart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/theme_accent_provider.dart';
import '../../core/theme/theme_mode_provider.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };

Widget quickSettingsSheetTitle(BuildContext context, String text) => Text(
      text,
      style: TextStyle(color: context.palette.bodyText, fontSize: 19, fontWeight: FontWeight.w700),
    );

void showAppearanceSheet(BuildContext context, WidgetRef ref, ThemeMode current) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quickSettingsSheetTitle(context, 'Appearance'),
          const SizedBox(height: 4),
          Text(
            'System follows your device setting; Light and Dark are fixed regardless of it.',
            style: TextStyle(color: context.palette.secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              key: ValueKey('appearance_${mode.name}'),
              contentPadding: EdgeInsets.zero,
              value: mode,
              groupValue: current,
              title: Text(themeModeLabel(mode)),
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).setMode(v!);
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}

void showThemeColorSheet(BuildContext context, WidgetRef ref, AppAccent current) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quickSettingsSheetTitle(context, 'Theme colour'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final accent in AppAccent.values)
                _AccentSwatch(
                  accent: accent,
                  selected: accent == current,
                  onTap: () {
                    ref.read(themeAccentProvider.notifier).setAccent(accent);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showNotificationSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.palette.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          quickSettingsSheetTitle(context, 'Notifications'),
          const SizedBox(height: 12),
          Text(
            'Result, CGPA and streak alerts are controlled by your system notification permission.',
            style: TextStyle(color: context.palette.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: openAppSettings, child: const Text('Open system settings')),
          ),
        ],
      ),
    ),
  );
}

class _AccentSwatch extends StatelessWidget {
  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  const _AccentSwatch({required this.accent, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('accentSwatch_${accent.name}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.primary,
                shape: BoxShape.circle,
                border: selected ? Border.all(color: context.palette.bodyText, width: 2.5) : null,
              ),
              child: selected ? const Icon(Icons.check, color: Colors.white) : null,
            ),
            const SizedBox(height: 6),
            Text(accent.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
