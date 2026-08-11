/// Student profile provider — kept separate from [AuthState], which is
/// auth-only. The [StudentProfile] model itself lives in
/// `lib/domain/models/student_profile.dart` (pure Dart) so
/// `lib/domain/repositories/profile_repository.dart` can reference it
/// without depending on this feature folder. Persisted via
/// [ProfileRepository] so it survives restarts.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/student_profile.dart';
import '../../../domain/repositories/profile_repository.dart';

export '../../../domain/models/student_profile.dart';

class ProfileController extends StateNotifier<StudentProfile?> {
  final ProfileRepository _repository;

  ProfileController(this._repository) : super(null) {
    unawaited(_loadPersisted());
  }

  Future<void> _loadPersisted() async {
    final persisted = await _repository.loadProfile();
    if (persisted != null) state = persisted;
  }

  void save(StudentProfile profile) {
    state = profile;
    unawaited(_repository.saveProfile(profile));
  }
}

final studentProfileProvider = StateNotifierProvider<ProfileController, StudentProfile?>(
  (ref) => ProfileController(ref.watch(profileRepositoryProvider)),
);
