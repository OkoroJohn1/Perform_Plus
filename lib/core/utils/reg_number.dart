/// Best-effort entry-year guess from a Nigerian reg number prefix, e.g.
/// "21/ENG/12345" -> 2021. Always a prefill, never a validated fact — the
/// student can and should correct it on the profile form.
int? deriveEntryYear(String regNumber) {
  final match = RegExp(r'^(\d{2})').firstMatch(regNumber.trim());
  if (match == null) return null;

  final twoDigit = int.parse(match.group(1)!);
  final currentTwoDigit = DateTime.now().year % 100;
  final century = twoDigit <= currentTwoDigit ? 2000 : 1900;
  return century + twoDigit;
}
