/// Whether the student has opened the notifications panel since the last
/// change to `standing.hasErrors` — backs the header bell's badge. Purely
/// cosmetic, in-memory; resets on restart.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationsReadProvider = StateProvider<bool>((ref) => false);
