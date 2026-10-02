/// A single, shared rule for flagging a low CGPA/GPA in red -- used
/// wherever a CGPA or semester GPA number is displayed (Dashboard,
/// Academics, Roadmap, Me). Kept in one place so every screen agrees on
/// exactly where the line is, rather than each screen guessing its own
/// threshold.
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

const lowPerformanceThreshold = 3.5;
const lowPerformanceColor = Color(0xFFDC2626);

/// [normal] is the colour to use when [value] is at or above the
/// threshold -- callers on a dark/gradient background pass a light colour
/// instead of the default (which assumes a white/light card).
Color performanceColor(double value, {Color normal = OnboardingLightPalette.bodyText}) =>
    value < lowPerformanceThreshold ? lowPerformanceColor : normal;
