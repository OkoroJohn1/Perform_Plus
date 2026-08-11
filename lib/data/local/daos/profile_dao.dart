import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/profiles_table.dart';

part 'profile_dao.g.dart';

@DriftAccessor(tables: [Profiles])
class ProfileDao extends DatabaseAccessor<AppDatabase> with _$ProfileDaoMixin {
  ProfileDao(super.db);

  Future<Profile?> getProfile(String id) =>
      (select(profiles)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> upsertProfile(ProfilesCompanion entry) =>
      into(profiles).insertOnConflictUpdate(entry);

  Future<void> setActiveScheme(String profileId, String schemeId) =>
      (update(profiles)..where((p) => p.id.equals(profileId))).write(
        ProfilesCompanion(activeSchemeId: Value(schemeId)),
      );
}
