/// Course-registration-slip extraction — the client half of the
/// `extract-course-slip` Supabase Edge Function. This file only prepares
/// the photo (resize/compress so a multi-MB phone photo doesn't blow past
/// the function's payload limit) and makes the call; the Edge Function
/// itself owns the actual vision-model call, the per-user daily rate
/// limit, and returning only what it can actually read off the slip.
///
/// A registration slip lists courses, not grades — extracted rows never
/// carry a grade. The caller (`add_semester_sheet.dart`) is responsible for
/// leaving that field blank for the student to fill in once results are
/// out, per "THE RULE THAT MATTERS MOST" in AGENTS.md: nothing here ever
/// computes or guesses a grade or GPA.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const slipMaxDimension = 1600;
const slipJpegQuality = 82;

class ExtractedCourse {
  final String courseCode;
  final String? courseTitle;
  final int? creditUnit;

  /// 0.0–1.0, from the model itself. Rows below 0.85 should be flagged for
  /// review in the UI, mirroring `CourseResult.needsReview`'s threshold.
  final double confidence;

  const ExtractedCourse({
    required this.courseCode,
    required this.courseTitle,
    required this.creditUnit,
    required this.confidence,
  });

  bool get needsReview => confidence < 0.85;

  factory ExtractedCourse.fromJson(Map<String, dynamic> json) => ExtractedCourse(
        courseCode: json['courseCode'] as String,
        courseTitle: json['courseTitle'] as String?,
        creditUnit: (json['creditUnit'] as num?)?.toInt(),
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}

/// Thrown with a message that's always safe to show directly to the
/// student — offline, rate-limited, unreadable slip, etc.
class SlipExtractionException implements Exception {
  final String message;
  const SlipExtractionException(this.message);

  @override
  String toString() => message;
}

Future<Uint8List?> pickRegistrationSlipBytes(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source, imageQuality: 90);
  if (file == null) return null;
  return file.readAsBytes();
}

/// Downscales to at most [slipMaxDimension] on the longer side, preserving
/// aspect ratio — unlike the profile-photo pipeline, a document must never
/// be cropped. Throws [FormatException] if [bytes] isn't a decodable image.
Uint8List processRegistrationSlip(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Could not decode the selected image.');
  }

  final longSide = decoded.width > decoded.height ? decoded.width : decoded.height;
  final resized = longSide <= slipMaxDimension
      ? decoded
      : decoded.width >= decoded.height
          ? img.copyResize(decoded, width: slipMaxDimension, interpolation: img.Interpolation.average)
          : img.copyResize(decoded, height: slipMaxDimension, interpolation: img.Interpolation.average);

  return Uint8List.fromList(img.encodeJpg(resized, quality: slipJpegQuality));
}

/// Calls the `extract-course-slip` Edge Function with an already-compressed
/// JPEG (see [processRegistrationSlip]).
Future<List<ExtractedCourse>> extractCoursesFromSlip(Uint8List jpegBytes) async {
  const offlineMessage = "Couldn't reach the extraction service. Check your connection and try again.";

  final Map<String, dynamic> data;
  try {
    final res = await Supabase.instance.client.functions.invoke(
      'extract-course-slip',
      body: {
        'imageBase64': base64Encode(jpegBytes),
        'mimeType': 'image/jpeg',
      },
    );
    if (res.data is! Map) throw const SlipExtractionException(offlineMessage);
    data = Map<String, dynamic>.from(res.data as Map);
  } on FunctionException catch (e) {
    final details = e.details;
    final message = details is Map ? details['error'] as String? : null;
    throw SlipExtractionException(message ?? offlineMessage);
  } on SlipExtractionException {
    rethrow;
  } catch (_) {
    throw const SlipExtractionException(offlineMessage);
  }

  final coursesJson = data['courses'];
  if (coursesJson is! List) {
    throw const SlipExtractionException(
      'Could not read the slip clearly. Try a clearer photo or enter courses manually.',
    );
  }

  final courses = coursesJson
      .whereType<Map>()
      .map((c) => ExtractedCourse.fromJson(Map<String, dynamic>.from(c)))
      .toList();

  if (courses.isEmpty) {
    throw const SlipExtractionException(
      "Couldn't find any courses on that slip. Try a clearer photo or enter courses manually.",
    );
  }

  return courses;
}
