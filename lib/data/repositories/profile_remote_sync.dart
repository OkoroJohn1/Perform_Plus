/// Mirrors a locally-saved profile to Supabase's `profiles` table, once a
/// session exists. Local Drift is always the source of truth — the profile
/// screen must complete with zero connectivity, so this is a best-effort
/// follow-up, never a blocking step.
///
/// UPDATE only, NEVER insert: the `profiles` row already exists by the time
/// this runs, created by a database trigger on `auth.users` insert (see the
/// provisioned schema). Inserting here would collide on the primary key.
///
/// `faculty` and a photo are deliberately NOT included in the synced
/// columns below — they exist locally (see `student_profile.dart`), but
/// this project's live Supabase schema was last confirmed (via the
/// Supabase MCP tools) to have neither a `faculty` column nor a photo
/// column on `profiles`. Sending them would make the whole `UPDATE`
/// statement fail outright. Add them here once the remote schema actually
/// has the columns — do not guess ahead of it.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/student_profile.dart';

abstract class ProfileRemoteSync {
  Future<void> updateProfile(String uid, StudentProfile profile);
}

class SupabaseProfileRemoteSync implements ProfileRemoteSync {
  final SupabaseClient _client;

  SupabaseProfileRemoteSync(this._client);

  @override
  Future<void> updateProfile(String uid, StudentProfile profile) async {
    await _client.from('profiles').update({
      'full_name': profile.fullName,
      'reg_number': profile.regNumber,
      'department': profile.department,
      'current_level': profile.currentLevel,
      'entry_year': profile.entryYear,
      'expected_graduation_year': profile.expectedGraduationYear,
    }).eq('id', uid);
  }
}
