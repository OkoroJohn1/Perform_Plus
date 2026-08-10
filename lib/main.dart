import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO(v1): init local DB (Drift), then Supabase, then run.
  runApp(const ProviderScope(child: PerformPlusApp()));
}
