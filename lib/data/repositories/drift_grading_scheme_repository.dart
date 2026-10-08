/// Drift-backed [GradingSchemeRepository]. Composes [GradingSchemeDao] (the
/// scheme snapshot) and [ProfileDao] (the active-scheme pointer).
library;

import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/grading_scheme.dart';
import '../../domain/repositories/grading_scheme_repository.dart';
import '../local/app_database.dart';
import '../local/daos/grading_scheme_dao.dart';
import '../local/daos/profile_dao.dart';

class DriftGradingSchemeRepository implements GradingSchemeRepository {
  final GradingSchemeDao _schemeDao;
  final ProfileDao _profileDao;

  DriftGradingSchemeRepository(this._schemeDao, this._profileDao);

  @override
  Future<GradingScheme?> loadActiveScheme() async {
    final profile = await _profileDao.getProfile(AppConstants.localProfileId);
    final activeSchemeId = profile?.activeSchemeId;
    if (activeSchemeId == null) return null;

    final row = await _schemeDao.getById(activeSchemeId);
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<void> saveActiveScheme(GradingScheme scheme) async {
    await _schemeDao.upsertScheme(
      GradingSchemesCompanion.insert(
        id: scheme.id,
        institutionId: scheme.institutionId,
        name: scheme.name,
        version: scheme.version,
        effectiveFrom: scheme.effectiveFrom,
        effectiveUntil: Value(scheme.effectiveUntil),
        maxPoint: scheme.maxPoint,
        grades: scheme.grades,
        classifications: scheme.classifications,
        repeatPolicy: scheme.repeatPolicy,
        repeatCapPoint: Value(scheme.repeatCapPoint),
        cgpaAggregation: Value(scheme.cgpaAggregation),
        isCustom: Value(scheme.isCustom),
        isVerified: Value(scheme.isVerified),
        firstTermLabel: Value(scheme.firstTermLabel),
        secondTermLabel: Value(scheme.secondTermLabel),
      ),
    );

    final existing = await _profileDao.getProfile(AppConstants.localProfileId);
    if (existing != null) {
      // A real profile already exists (Profile Setup has run) — touch only
      // the pointer column. `upsertProfile` below is a full-row upsert via
      // `ProfilesCompanion.insert`, and its required (non-nullable) fields
      // can't be left absent, so using it here would silently blank out the
      // student's name/reg number/etc. on every semester saved afterwards.
      await _profileDao.setActiveScheme(AppConstants.localProfileId, scheme.id);
      return;
    }

    // No profile row yet — scheme selection during onboarding happens
    // before the profile-setup screen runs. Insert a minimal placeholder so
    // the active-scheme pointer has somewhere to live.
    await _profileDao.upsertProfile(
      ProfilesCompanion.insert(
        id: AppConstants.localProfileId,
        fullName: '',
        regNumber: '',
        department: '',
        currentLevel: 0,
        entryYear: 0,
        expectedGraduationYear: 0,
        activeSchemeId: Value(scheme.id),
        updatedAt: DateTime.now(),
      ),
    );
  }

  GradingScheme _toDomain(GradingSchemeRow row) => GradingScheme(
        id: row.id,
        institutionId: row.institutionId,
        name: row.name,
        version: row.version,
        effectiveFrom: row.effectiveFrom,
        effectiveUntil: row.effectiveUntil,
        maxPoint: row.maxPoint,
        grades: row.grades,
        classifications: row.classifications,
        repeatPolicy: row.repeatPolicy,
        repeatCapPoint: row.repeatCapPoint,
        cgpaAggregation: row.cgpaAggregation,
        isCustom: row.isCustom,
        isVerified: row.isVerified,
        firstTermLabel: row.firstTermLabel,
        secondTermLabel: row.secondTermLabel,
      );
}
