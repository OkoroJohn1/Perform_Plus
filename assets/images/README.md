`logo.png` — the official Perform+ "P" mark, transparent background, used
in-app via `lib/shared/widgets/app_logo.dart`'s `AppLogo` widget.

`app_icon.png` — the same mark on its full rounded-square gradient
background, the source image for the Android launcher icon
(`flutter_launcher_icons`, see pubspec.yaml).

`app_icon_foreground.png` — the mark alone, transparent, centred and padded
to Android's adaptive-icon safe zone; paired with
`adaptive_icon_background: "#0A0A48"` in pubspec.yaml so the OS's own mask
shape (circle/squircle/rounded square) never clips it or doubles up against
`app_icon.png`'s own baked-in background.

All three are derived from one source image via background-removal
(luminance-threshold alpha) — see git history for the exact processing if
regenerating from a new source.
