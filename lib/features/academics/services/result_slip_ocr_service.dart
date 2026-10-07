/// On-device OCR for a result slip -- the document issued *after* exams,
/// listing a grade per course. Deliberately separate from
/// `course_slip_extraction_service.dart`, which reads a *registration*
/// slip (courses only, no grades yet) via a server-side vision model:
/// a result slip needs a grade read off it too, which is a far higher-
/// stakes field to get wrong, and this path runs fully offline with no
/// API key, via Google ML Kit's on-device text recognizer.
///
/// ML Kit only does raw text recognition -- it finds words and their
/// position on the page, nothing more. It has no idea what a "course
/// code" or "grade column" is. [extractResultsFromImage] reconstructs
/// table rows from text-line positions and parses each with a regex
/// heuristic, which is inherently less reliable than a vision model that
/// actually understands the slip's layout. Every row this produces is
/// capped well under `CourseResult.needsReview`'s 0.85 threshold (see
/// [ExtractedResultLine.confidence]'s doc comment) so the review banner
/// in `add_semester_sheet.dart` always fires, and -- same as the
/// registration-slip path, and the whole point of "THE LLM NEVER
/// PERFORMS ARITHMETIC" in AGENTS.md -- the parsed grade is never saved
/// directly. It only pre-fills `_RowEditor`'s grade dropdown, which is
/// constrained to the active `GradingScheme.grades`, so a misread can
/// only ever be corrected to a valid grade, never saved as garbage.
library;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// A single row parsed off a result slip. Unlike `ExtractedCourse`
/// (registration slips), this carries a [grade] guess -- a result slip
/// has one, a registration slip never does.
class ExtractedResultLine {
  final String courseCode;
  final String? courseTitle;
  final int? creditUnit;
  final String? grade;

  /// 0.0–1.0. Deliberately capped below 0.85 (see this file's doc
  /// comment) -- raw-OCR table parsing is never confident enough to skip
  /// the review flag that threshold gates in the UI.
  final double confidence;

  const ExtractedResultLine({
    required this.courseCode,
    this.courseTitle,
    this.creditUnit,
    this.grade,
    required this.confidence,
  });
}

/// Thrown with a message that's always safe to show directly to the
/// student.
class ResultSlipOcrException implements Exception {
  final String message;
  const ResultSlipOcrException(this.message);

  @override
  String toString() => message;
}

/// Launches the camera/gallery picker and returns the picked file's path,
/// or null if the student backed out. No resizing here (unlike the
/// registration-slip path) -- downscaling trades away exactly the detail
/// the text recognizer needs, and there's no upload payload limit to
/// respect on-device.
Future<String?> pickResultSlipImagePath(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 100);
  return file?.path;
}

final _courseCodePattern = RegExp(r'\b([A-Za-z]{2,5})\s?-?\s?(\d{2,4}[A-Za-z]?)\b');
final _gradeTokenPattern = RegExp(r'^[A-Fa-f](\+|-)?$');
final _standaloneNumberPattern = RegExp(r'\b(\d{1,2})\b');

/// Runs the on-device recognizer against the image at [imagePath] and
/// parses whatever looks like course rows out of the result.
///
/// This never touches the network and never throws for an unreadable
/// slip -- an empty result list means "couldn't find any rows," which
/// the caller presents the same way a cloud-extraction failure is
/// presented: fall back to manual entry, never a fabricated row.
Future<List<ExtractedResultLine>> extractResultsFromImage(String imagePath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognized;
  try {
    recognized = await recognizer.processImage(InputImage.fromFilePath(imagePath));
  } catch (_) {
    throw const ResultSlipOcrException(
      "Couldn't read that image. Try a clearer, well-lit photo of the slip.",
    );
  } finally {
    await recognizer.close();
  }

  final lines = <TextLine>[
    for (final block in recognized.blocks) ...block.lines,
  ]..sort((a, b) => a.boundingBox.top.compareTo(b.boundingBox.top));

  if (lines.isEmpty) {
    throw const ResultSlipOcrException(
      "Couldn't find any text on that image. Try a clearer, well-lit photo of the slip.",
    );
  }

  // Group lines into table rows by vertical proximity -- ML Kit returns
  // each recognized text line independently, with no notion of "these
  // three lines are cells in the same table row."
  final rows = <List<TextLine>>[];
  for (final line in lines) {
    final height = line.boundingBox.height;
    final center = line.boundingBox.top + height / 2;
    final currentRow = rows.isEmpty ? null : rows.last;
    if (currentRow != null &&
        currentRow.any((l) => (l.boundingBox.top + l.boundingBox.height / 2 - center).abs() < height * 0.6)) {
      currentRow.add(line);
    } else {
      rows.add([line]);
    }
  }

  final results = <ExtractedResultLine>[];
  for (final row in rows) {
    row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
    final rowText = row.map((l) => l.text).join(' ').trim();
    final parsed = _parseRow(rowText);
    if (parsed != null) results.add(parsed);
  }

  return results;
}

ExtractedResultLine? _parseRow(String rowText) {
  final codeMatch = _courseCodePattern.firstMatch(rowText);
  if (codeMatch == null) return null;

  final courseCode = '${codeMatch.group(1)!.toUpperCase()}${codeMatch.group(2)!.toUpperCase()}';
  var confidence = 0.30;

  var remainder = rowText.replaceRange(codeMatch.start, codeMatch.end, ' ').trim();

  // The grade is the most load-bearing field to get right, so it's
  // matched narrowly: a single bare letter token (optionally +/-), not
  // just any letter anywhere in the row -- a row like "Introduction to
  // Economics" must never donate its leading "I" as a guessed grade.
  String? grade;
  final tokens = remainder.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  for (var i = tokens.length - 1; i >= 0; i--) {
    if (_gradeTokenPattern.hasMatch(tokens[i])) {
      grade = tokens[i].toUpperCase();
      tokens.removeAt(i);
      confidence += 0.25;
      break;
    }
  }
  remainder = tokens.join(' ');

  int? creditUnit;
  for (final match in _standaloneNumberPattern.allMatches(remainder)) {
    final value = int.tryParse(match.group(1)!);
    if (value != null && value >= 1 && value <= 12) {
      creditUnit = value;
      confidence += 0.10;
      remainder = remainder.replaceRange(match.start, match.end, ' ').trim();
      break;
    }
  }

  final courseTitle = remainder.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (courseTitle.isNotEmpty) confidence += 0.05;

  return ExtractedResultLine(
    courseCode: courseCode,
    courseTitle: courseTitle.isEmpty ? null : courseTitle,
    creditUnit: creditUnit,
    grade: grade,
    // Clamped well under the 0.85 review threshold -- see this file's
    // doc comment on why raw-OCR table parsing never claims that level
    // of confidence.
    confidence: confidence.clamp(0.0, 0.70),
  );
}
