/// TODO(v1): persist the chosen theme mode once Drift lands. In-memory
/// only for now, resets to system default on app restart.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
