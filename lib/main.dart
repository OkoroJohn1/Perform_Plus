import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';

/// Crash/error reporting. `SENTRY_DSN` is optional (see `.env.example`) --
/// left blank, [SentryFlutter.init] is never called and the app runs
/// exactly as it did before Sentry existed. When set, this captures
/// uncaught Flutter framework errors and Dart zone errors app-wide; no
/// screen needs to opt in individually.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  final sentryDsn = dotenv.env['SENTRY_DSN'];

  Future<void> bootstrap() async {
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      // The .env value is a `sb_publishable_...` key — Supabase's newer
      // publishable-key format, not the legacy anon JWT.
      publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
    );
    runApp(const ProviderScope(child: PerformPlusApp()));
  }

  if (sentryDsn == null || sentryDsn.isEmpty) {
    await bootstrap();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      // Nigerian mobile data is unreliable and everything else in this app
      // already treats that as normal, not exceptional -- sampling every
      // event by default would fill a free-tier Sentry project with
      // routine timeouts rather than genuine bugs. Traces are sampled much
      // lighter than errors, which are always sent.
      options.tracesSampleRate = 0.1;
    },
    appRunner: bootstrap,
  );
}
