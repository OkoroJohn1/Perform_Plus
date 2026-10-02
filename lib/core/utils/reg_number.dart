/// Registration-number shapes vary per institution — there is no single
/// Nigerian format. A prior version of this file assumed "21/ENG/12345"
/// (two-digit year, slash-separated) universally; a real FUTO registration
/// slip is actually 11 digits with no separators at all, e.g.
/// "20211258122", where the first FOUR digits are the entry year. Encoding
/// one shape as THE format silently mis-derives (or outright rejects) every
/// other institution's number, so each institution now carries its own
/// [RegNumberFormat] — see `data/seed/nigerian_institutions.dart`.
library;

/// One institution's registration-number shape: a validation pattern, a
/// hint/example shown in the field, and a way to pull the entry year out
/// of a number in that shape. Never a hard gate — `profile_setup_screen.dart`
/// uses [matches] for a soft "does this look right?" warning only, since
/// formats change and a real student's number should never be rejected
/// outright over our assumption of what it looks like.
class RegNumberFormat {
  final String _patternSource;
  final String hint;
  final int? Function(String regNumber) extractEntryYear;

  const RegNumberFormat({
    required String patternSource,
    required this.hint,
    required this.extractEntryYear,
  }) : _patternSource = patternSource;

  bool matches(String regNumber) =>
      RegExp(_patternSource).hasMatch(regNumber.trim());
}

/// FUTO: 11 digits, no separators, entry year is the first four digits —
/// e.g. "20211258122" -> 2021. Confirmed against a real FUTO registration
/// slip.
int? _extractFutoEntryYear(String regNumber) {
  final digits = regNumber.trim();
  if (digits.length < 4) return null;
  return int.tryParse(digits.substring(0, 4));
}

const futoRegNumberFormat = RegNumberFormat(
  patternSource: r'^\d{11}$',
  hint: '20211258122',
  extractEntryYear: _extractFutoEntryYear,
);

/// Best-effort guess assuming a leading two-digit year code — common across
/// many Nigerian formats (e.g. "21/ENG/12345" -> 2021) but NOT confirmed for
/// any specific institution below FUTO. Century is inferred by comparing
/// against the current year's own two-digit form, so this drifts correctly
/// decade to decade rather than hardcoding "20xx".
int? _extractGenericEntryYear(String regNumber) {
  final match = RegExp(r'(\d{2})').firstMatch(regNumber.trim());
  if (match == null) return null;
  final twoDigit = int.parse(match.group(1)!);
  final currentTwoDigit = DateTime.now().year % 100;
  final century = twoDigit <= currentTwoDigit ? 2000 : 1900;
  return century + twoDigit;
}

/// Used for every institution whose actual reg-number shape hasn't been
/// confirmed yet (everything except FUTO — see the file doc comment).
/// Deliberately permissive so the soft-warning rarely fires on a real
/// number we simply haven't catalogued the shape of.
const genericRegNumberFormat = RegNumberFormat(
  patternSource: r'^.{4,}$',
  hint: 'e.g. 21/ENG/12345 or 20211258122',
  extractEntryYear: _extractGenericEntryYear,
);
