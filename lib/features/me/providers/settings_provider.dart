/// Cosmetic settings toggles with no backend wiring yet — no push
/// notification system exists, so this only controls the in-app read
/// state, not actual delivery. In-memory, resets on restart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsEnabledProvider = StateProvider<bool>((ref) => true);
